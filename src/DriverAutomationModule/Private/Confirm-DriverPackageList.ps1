function Confirm-DriverPackageList {
    <#
    .SYNOPSIS
    Confirms the driver package list and selects the latest package if multiple are found.

    .DESCRIPTION
    This function confirms the driver package list object and selects the latest driver package if multiple packages are found.
    The function processes driver package objects retrieved from the Configuration Manager AdminService endpoint.
    If a single package is found, it is returned as-is. If multiple packages are found, the function selects the package with the most recent SourceDate.
    SourceDate values are provided as ISO 8601 formatted strings from the AdminService and are converted to DateTime objects for accurate chronological sorting.
    If no packages are found, the function logs an error and returns nothing.

    .PARAMETER DriverPackageList
    The driver package object(s) to confirm. This should be the output from Get-DriverPackageList or an AdminService response.
    The objects should contain at least the PackageID and SourceDate properties. SourceDate should be in ISO 8601 format (e.g., "2025-07-18T17:58:08Z").
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
    SourceDate strings are converted to DateTime objects during sorting to ensure accurate chronological comparison, as ISO 8601 string sorting may not always produce correct results depending on format variations.
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
            # Converting SourceDate strings to DateTime objects for chronological sorting
            # since ISO 8601 strings can sort lexicographically, converting to DateTime
            # makes a more accurate date/time comparison regardless of string format variations
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