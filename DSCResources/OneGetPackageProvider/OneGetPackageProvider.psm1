function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $Source,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    If ((Get-WinVersion) -lt [decimal]6.3){
        Throw "NuGetPackageProvider resource only supported in Windows 2012 R2 and up."
    }

    $InstalledPackageProviders = Get-PackageProvider -ListAvailable

    Write-Verbose "Getting info for NuGetPackageProvider $($Name)."
    If (($InstalledPackageProviders.Name) -contains $Name)
    {
        $returnValue = @{
                Name = $Name
                Ensure = 'Present'
        }
    }
    else {
        $returnValue = @{
            Name = $Name
            Ensure = 'Absent'
        }
        $returnValue
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $Source,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1


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
        $Source,      

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.3){
        Throw "NuGetPackageProvider resource only supported in Windows 2012 R2 and up."
    }
    
    Write-Verbose "Testing NuGetPackageProvider $($Name)."

    #Check of storagepool already exists
    $CheckPackageProvider = Get-TargetResource @PSBoundParameters

    If (($Ensure -ieq 'Present') -and ($CheckNuGetPackage.Ensure -ieq 'Absent')) { #Installation not found
        Write-Verbose "PackageProvider $($Name) NOT installed. NOT consistent."
        Write-Debug "PackageProvider $($Name) NOT installed. NOT consistent."
        Return $false
    } 

    If (($Ensure -ieq 'Absent') -and ($CheckNuGetPackage.Ensure -ieq 'Present')) { #Removal requested
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

Export-ModuleMember -Function *-TargetResource

