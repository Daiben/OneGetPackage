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
        Throw "OneGetPackage resource only supported in Windows 2012 R2 and up."
    }

    $OneGetPackages = @()
    $OneGetPackages = Get-Package -Name $Name -ErrorAction SilentlyContinue #Can be more than one package!

    #Check source validity
    If ($Source)
    {
        $OneGetSources = Get-PackageSource -ProviderName (($OneGetPackages).ProviderName) -ErrorAction SilentlyContinue #Can be more than one source!
        If (($OneGetSources.Name) -contains $Source)
        {
            #Check if installed package comes from requested soure
            $PackageVersions = $OneGetPackages | Where-Object ProviderName -eq (($OneGetSources | Where-Object Name -ieq $Source).Providername) #can still be multiple versions (future implement)
            If ($PackageVersions)
            {
                Write-Verbose "$($PackageVersions)"
                $returnValue = @{
                    Name = $Name
                    Source = $Source
                    Ensure = 'Present'
                }
                $returnValue
            }
            Else {
                $returnValue = @{
                    Name = $Name
                    Source = $Source
                    Ensure = 'Absent'
                }
            }
        }
        else {
            $returnValue = @{
                Name = $Name
                Source = [string]::Empty
                Ensure = 'Absent'
            }
            $returnValue
        }
    }
    else {
        If ($OneGetPackages){
            $returnValue = @{
                Name = $Name
                Source = [string]::Empty
                Ensure = 'Present'
            }
        }
        Else{
            $returnValue = @{
                Name = $Name
                Source = [string]::Empty
                Ensure = 'Absent'
            }
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
        Throw "OneGetPackage resource only supported in Windows 2012 R2 and up."
    }

    $CheckOneGetPackage = Get-TargetResource @PSBoundParameters

    If (($Ensure -ieq 'Present') -and ($CheckOneGetPackage.Ensure -ieq 'Absent')) { #Installation not found
        #Check source validity
        If ($Source)
        {
            $OneGetSources = Get-PackageSource -ErrorAction SilentlyContinue #Can be more than one source!
            If (($OneGetSources.Name) -notcontains $Source)
            {
                Write-Verbose "$($Source) is NOT a registered package source in the system."
                Write-Debug "$($Source) is NOT a registered package source in the system."
                Write-Error "$($Source) is NOT a registered package source in the system."
            }

            If (!(Find-Package -Name $Name -Source $Source))
            {
                Write-Verbose "Package $($Name) is not found in $($Source)"
                Write-Debug "Package $($Name) is not found in $($Source)"
                Write-Error "Package $($Name) is not found in $($Source)"           
            }

            Install-Package $Name -Source $Source -Force
            Write-Verbose "Package $($Name) installed from $($Source)"
        }

        #Check package validity
        If (!(Find-Package -Name $Name))
        {
            Write-Verbose "Package $($Name) is not found in any source"
            Write-Debug "Package $($Name) is not found in any source"
            Write-Error "Package $($Name) is not found in any source"         
        }
        
        #Install package
        Install-Package $Name -Force
        Write-Verbose "Package $($Name) installed"
    }

    If (($Ensure -ieq 'Absent') -and ($CheckOneGetPackage.Ensure-ieq 'Present')) { #Removal requested
        Uninstall-Package -Name $Name -Force
        Write-Verbose "Package $($Name) uninstalled"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $Source = [string]::Empty,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.3){
        Throw "OneGetPackage resource only supported in Windows 2012 R2 and up."
    }

    Write-Verbose "Testing OneGetPackage $($Name)."

    #Check of storagepool already exists
    $CheckOneGetPackage = Get-TargetResource @PSBoundParameters

    If (($Ensure -ieq 'Present') -and ($CheckOneGetPackage.Ensure -ieq 'Absent')) { #Installation not found
        Write-Verbose "Package $($Name) NOT installed. NOT consistent."
        Write-Debug "Package $($Name) NOT installed. NOT consistent."
        Return $false
    } 


    If (($Ensure -ieq 'Absent') -and ($CheckOneGetPackage.Ensure-ieq 'Present')) { #Removal requested
        Write-Verbose "Removal requested. NOT consistent."
        Write-Debug "Removal requested. NOT consistent."
        Return $false
    }


    If (($Ensure -ieq 'Present') -and ($CheckOneGetPackage.Ensure -ieq 'Present')) { #Consistent, check details
        If ($Source -ieq $CheckOneGetPackage.Source) { 
            Write-Verbose "Package $($Name) installed from $($Source). Consistent."
            Write-Debug "Package $($Name) installed from $($Source). Consistent."
            Return $true
            }
        else {
            Write-Verbose "Package $($Name) NOT installed from $($Source). NOT Consistent."
            Write-Debug "Package $($Name) NOT installed from $($Source). NOT Consistent."
            Return $false
        }

        Write-Verbose "Package $($Name) installed. Consistent."
        Write-Debug "Package $($Name) installed. Consistent."
        Return $true
    }
}

Function Get-WinVersion
{
    #not using Get-CimInstance; older versions of Windows use DCOM. Get-WmiObject works on all, so far...
    $os = (Get-WmiObject -Class Win32_OperatingSystem).Version.Split('.')
    [decimal]($os[0] + "." + $os[1])
}

Export-ModuleMember -Function *-TargetResource

