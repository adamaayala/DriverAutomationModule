function Confirm-DriverPackageList {
    <#
    .SYNOPSIS
    Confirms the driver package list and selects the latest package if multiple are found.

    .DESCRIPTION
    This function confirms the driver package list object and selects the latest driver package if multiple packages are found.
    The function processes driver package objects retrieved from the Configuration Manager AdminService endpoint.
    If a single package is found, it is returned as-is. If multiple packages are found, the function selects the package with the most recent SourceDate.
    If no packages are found, the function logs an error and returns nothing.

    .PARAMETER DriverPackageList
    The driver package object(s) to confirm. This should be the output from Get-DriverPackageList or an AdminService response.
    The objects should contain at least the PackageID and SourceDate properties.
    This parameter accepts pipeline input and can process an array of driver package objects.

    .EXAMPLE
    $uri = Set-DriverPackageQuery -ServerFQDN "CM01.contoso.com" -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
    $driverPackages = Get-DriverPackageList -Uri $uri
    $confirmedPackage = Confirm-DriverPackageList -DriverPackageList $driverPackages
    Retrieves driver packages and confirms the latest package from the results.

    .EXAMPLE
    $driverPackages = Get-DriverPackageList -Uri $uri
    $confirmedPackage = $driverPackages | Confirm-DriverPackageList
    Confirms the driver package using pipeline input.

    .INPUTS
    System.Object[]
    You can pipe driver package objects to this function. Each object should contain PackageID and SourceDate properties.

    .OUTPUTS
    System.Object
    Returns a single driver package object. If multiple packages are found, returns the one with the most recent SourceDate.
    If no packages are found, returns nothing.

    .NOTES
    Part of the DriverAutomationModule module.
    The function sorts packages by SourceDate in descending order to select the latest package when multiple matches are found.
    All operations are logged using Write-LogEntry for debugging and audit purposes.

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Specify the driver package object(s) to confirm.")]
        [AllowEmptyCollection()]
        [System.Object[]]$DriverPackageList
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        # Count the number of driver packages
        $pkgCount = @($DriverPackageList).Count

        Write-LogEntry -Message "Driver package count: $pkgCount" -Source $cmdletName

        if ($pkgCount -eq 1) {
            $confirmedPackage = $DriverPackageList
        }

        # If multiple packages are found, select the latest one
        elseif ($pkgCount -gt 1) {
            Write-LogEntry -Message "Multiple driver packages found. Selecting the latest package." -Source $cmdletName
            $packagesArray = @($DriverPackageList)
            $sortedPackages = $packagesArray | Sort-Object -Property { [DateTime]::Parse($_.SourceDate) } -Descending
            $confirmedPackage = $sortedPackages[0]
        }
        else {
            Write-LogEntry -Message "No driver packages found." -Source $cmdletName -Severity 3
            return
        }

        Write-LogEntry -Message "Driver package confirmed with PackageID: [$($confirmedPackage.PackageID)]" -Source $cmdletName -Severity 0
        Write-Output $confirmedPackage
    }
}