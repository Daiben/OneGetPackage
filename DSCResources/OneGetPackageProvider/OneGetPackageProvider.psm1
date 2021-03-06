function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String] $Name,

        [String] $Source = [string]::Empty,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.3){
        Throw "OneGetPackageProvider resource only supported in Windows 2012 R2 and up."
    }

    If ((Get-PSVersion) -lt [decimal]5.1){
        Throw "OneGetPackageProvider resource needs PowerShell version 5.1"
    }

    Write-Verbose "Getting info for OneGetPackageProvider $($Name)."
    $PackageProvider = Get-PackageProvider -ListAvailable | Where-Object Name -ieq $Name
    If ($PackageProvider){
        If ($Source)
        {
            $PackageProviderSources = Find-PackageProvider -Name $Name -ErrorAction SilentlyContinue
            If (($PackageProviderSources.Source) -contains $Source)
            {
                $returnValue = @{
                    Name = $Name
                    Source = $Source
                    Ensure = 'Present'
                }
            }
            else {
                $returnValue = @{
                    Name = $Name
                    Source = [string]::Empty
                    Ensure = 'Absent'
                }
            }
        }
        $returnValue = @{
            Name = $Name
            Source = [string]::Empty
            Ensure = 'Present'
        }
    }
    Else {
         $returnValue = @{
            Name = $Name
            Source = [string]::Empty
            Ensure = 'Absent'
        }       
    }
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String] $Name,

        [String] $Source = [string]::Empty,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.3){
        Throw "OneGetPackageProvider resource only supported in Windows 2012 R2 and up."
    }

    If ((Get-PSVersion) -lt [decimal]5.1){
        Throw "OneGetPackageProvider resource needs PowerShell version 5.1"
    }

    #Check source validity
    If ($Source)
    {
        $PackageProviderSource = Find-PackageProvider -Name $Name -Source $Source -ErrorAction SilentlyContinue
        If ($PackageProviderSource){
            Write-Verbose "Installing PackageProvider $($Name) from $($Source)"
            Write-Debug "Installing PackageProvider $($Name) from $($Source)"
            Install-PackageProvider -Name $Name -Source $Source -Force
        }
        Else {
            Write-Verbose "PackageProvider $($Name) not available from $($Source)"
            Write-Debug "PackageProvider $($Name) not available from $($Source)"
            Write-Error "PackageProvider $($Name) not available from $($Source)"
        }
    }

    $PackageProviderSource = Find-PackageProvider -Name $Name -ErrorAction SilentlyContinue
    If ($PackageProviderSource){
        Write-Verbose "Installing PackageProvider $($Name) from $($PackageProviderSource.Source)"
        Write-Debug "Installing PackageProvider $($Name) from $($PackageProviderSource.Source)"
        Install-PackageProvider -Name $Name -Force
    }
    Else {
        Write-Verbose "PackageProvider $($Name) not available"
        Write-Debug "PackageProvider $($Name) not available"
        Write-Error "PackageProvider $($Name) not available"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [String] $Name,

        [String] $Source = [string]::Empty,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.3){
        Throw "OneGetPackageProvider resource only supported in Windows 2012 R2 and up."
    }

    If ((Get-PSVersion) -lt [decimal]5.1){
        Throw "OneGetPackageProvider resource needs PowerShell version 5.1"
    }

    Write-Verbose "Testing OneGetPackageProvider $($Name)."

    #Check of storagepool already exists
    $CheckPackageProvider = Get-TargetResource @PSBoundParameters

    If (($Ensure -ieq 'Present') -and ($CheckPackageProvider.Ensure -ieq 'Absent')) { #Installation not found
        Write-Verbose "PackageProvider $($Name) NOT installed. NOT consistent."
        Write-Debug "PackageProvider $($Name) NOT installed. NOT consistent."
        Return $false
    } 

    If (($Ensure -ieq 'Absent') -and ($CheckPackageProvider.Ensure -ieq 'Present')) { #Removal requested
        Write-Verbose "Removal requested. NOT consistent but NOT supported"
        Write-Debug "Removal requested. NOT consistent but NOT supported"
        Return $true
    }

    Write-Verbose "PackageProvider $($Name) installed. Consistent."
    Write-Debug "PackageProvider $($Name) installed. Consistent."
    Return $true
}

Function Get-WinVersion
{
    #not using Get-CimInstance; older versions of Windows use DCOM. Get-WmiObject works on all, so far...
    $os = (Get-WmiObject -Class Win32_OperatingSystem).Version.Split('.')
    [decimal]($os[0] + "." + $os[1])
}

Function Get-PSVersion
{
    $PSMajor = $PSVersionTable.PSVersion.Major
    $PSMinor = $PSVersionTable.PSVersion.Minor
    [decimal]([string]$PSMajor + '.' + [string]$PSMinor)
}

Export-ModuleMember -Function *-TargetResource

