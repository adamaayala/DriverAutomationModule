---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Confirm-DriverPackageList

## SYNOPSIS
Confirms the driver package list and selects the latest package if multiple are found.

## SYNTAX

```
Confirm-DriverPackageList [-DriverPackageList] <Object[]> [<CommonParameters>]
```

## DESCRIPTION
This function confirms the driver package list object and selects the latest driver package if multiple packages are found.
The function processes driver package objects retrieved from the Configuration Manager AdminService endpoint.
If a single package is found, it is returned as-is. If multiple packages are found, the function selects the package with the most recent SourceDate.
SourceDate values are provided as ISO 8601 formatted strings from the AdminService and are converted to DateTime objects for accurate chronological sorting.
If no packages are found, the function logs an error and returns nothing.

## EXAMPLES

### Example 1
```
PS C:\> $uri = Set-DriverPackageQuery -ServerFQDN "CM01.contoso.com" -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
PS C:\> $driverPackages = Get-DriverPackageList -Uri $uri
PS C:\> $confirmedPackage = Confirm-DriverPackageList -DriverPackageList $driverPackages
```
Retrieves driver packages and confirms the latest package from the results.

### Example 2
```
PS C:\> $driverPackages = Get-DriverPackageList -Uri $uri
PS C:\> $confirmedPackage = $driverPackages | Confirm-DriverPackageList
```
Confirms the driver package using pipeline input.

## PARAMETERS

### -DriverPackageList
The driver package object(s) to confirm. This should be the output from Get-DriverPackageList or an AdminService response.
The objects should contain at least the PackageID and SourceDate properties. SourceDate should be in ISO 8601 format (e.g., "2025-07-18T17:58:08Z").
This parameter accepts pipeline input and can process an array of driver package objects.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object[]
You can pipe driver package objects to this function. Each object should contain PackageID and SourceDate properties.

## OUTPUTS

### System.Object
Returns a single driver package object. If multiple packages are found, returns the one with the most recent SourceDate.
If no packages are found, returns nothing.

## NOTES
Part of the DriverAutomationModule module.
The function sorts packages by SourceDate in descending order to select the latest package when multiple matches are found.
SourceDate strings are converted to DateTime objects during sorting to ensure accurate chronological comparison, as ISO 8601 string sorting may not always produce correct results depending on format variations.
All operations are logged using Write-LogEntry for debugging and audit purposes.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

