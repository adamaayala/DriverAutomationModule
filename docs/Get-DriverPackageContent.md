---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Get-DriverPackageContent

## SYNOPSIS
Downloads the driver package content from Microsoft Endpoint Manager (SCCM) to a specified custom location.

## SYNTAX

```
Get-DriverPackageContent -CustomLocation <String> [<CommonParameters>]
```

## DESCRIPTION
This function downloads the driver package content from Microsoft Endpoint Manager (SCCM) to a specified custom location.
The function retrieves the driver package information from Task Sequence variables (set by Find-DriverPackage) and uses
the OSDDownloadContent utility to download the package content.

The function performs the following steps:
1. Retrieves the driver package query result from Task Sequence variables using Get-DriverPackageQueryResult
2. Validates that the driver package query result exists and contains a PackageID
3. Downloads the driver package content to the specified custom location using Invoke-OSDDownloadContent
4. Sets the download location path in the Task Sequence variable "DriverPackagePath"

This function requires that Find-DriverPackage has been executed previously to set the driver package information
in Task Sequence variables. If the driver package query result is not found or does not contain a PackageID,
the function will throw an error.

The function uses the OSDDownloadContent utility which must be available in the system PATH (WinPE) or at
$env:WINDIR\CCM\OSDDownloadContent.exe (full OS). The function requires a Task Sequence environment to be available.

## EXAMPLES

### Example 1
```
PS C:\> Get-DriverPackageContent -CustomLocation "C:\DriverPackageContent"
```
Downloads the driver package content to C:\DriverPackageContent. The driver package information must have been
previously set by Find-DriverPackage.

### Example 2
```
PS C:\> Get-DriverPackageContent -CustomLocation "D:\Downloads\Drivers\Dell"
```
Downloads the driver package content to D:\Downloads\Drivers\Dell. The download location path will be stored
in the Task Sequence variable "DriverPackagePath".

## PARAMETERS

### -CustomLocation
The custom location path where the driver package content will be downloaded.
This parameter is mandatory and must be a valid, non-empty string.
The path will be created if it does not exist during the download process.
Example: "C:\DriverPackageContent" or "D:\Downloads\Drivers\Dell"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
This function does not accept pipeline input.

## OUTPUTS

### None
This function does not return any output. Success or failure is indicated through log entries and exception handling.
The download location path is stored in the Task Sequence variable "DriverPackagePath".

## NOTES
Part of the DriverAutomationModule module.
This function requires:
- A Task Sequence environment to be initialized
- Find-DriverPackage to have been executed previously to set driver package information in Task Sequence variables
- The OSDDownloadContent utility to be available in the system PATH (WinPE) or at $env:WINDIR\CCM\OSDDownloadContent.exe (full OS)
- The Get-DriverPackageQueryResult function to retrieve driver package information from Task Sequence variables
- The Invoke-OSDDownloadContent function to perform the actual download

The function uses Write-LogEntry for logging all operations and errors.
If the driver package query result is not found or does not contain a PackageID, the function will throw an error.
If the download process fails, the function will log the error and re-throw it with a descriptive message.

## RELATED LINKS
https://github.com/adamaayala/OSDeploymentKit

