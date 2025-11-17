---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Invoke-OSDDownloadContent

## SYNOPSIS
Starts the OSDDownloadContent executable during a task sequence.

## SYNTAX

### NoPath
```
Invoke-OSDDownloadContent -PackageID <String> -DestinationLocationType <String>
    -DestinationVariableName <String> [<CommonParameters>]
```

### CustomPath
```
Invoke-OSDDownloadContent -PackageID <String> -DestinationLocationType <String>
    -DestinationVariableName <String> -CustomLocationPath <String> [<CommonParameters>]
```

## DESCRIPTION
This function initiates the OSDDownloadContent executable during a task sequence,
utilizing OSDDownloadContent task sequence variables as parameters.

The function uses Set-TSVariable to set the following task sequence variables before execution:
- OSDDownloadDownloadPackages: The PackageID to download
- OSDDownloadDestinationLocationType: The destination location type (Custom, TSCache, or CCMCache)
- OSDDownloadDestinationVariable: The task sequence variable name to store the download location
- OSDDownloadDestinationPath: The custom path (set to the CustomLocationPath value when provided, otherwise null/empty)

The function automatically determines the OSDDownloadContent executable path:
- In WinPE: Uses "OSDDownloadContent.exe" (assumes it's in the PATH)
- In full OS: Uses "$env:WINDIR\CCM\OSDDownloadContent.exe"

After execution, all task sequence variables are automatically cleared using Set-TSVariable with empty string values in the finally block, regardless of success or failure.

This function supports two parameter sets:
- NoPath: Used when DestinationLocationType is TSCache or CCMCache (CustomLocationPath not required)
- CustomPath: Used when DestinationLocationType is Custom (CustomLocationPath is required)

## EXAMPLES

### Example 1
```
PS C:\> Invoke-OSDDownloadContent -PackageID "PKG00001" -DestinationLocationType "TSCache" -DestinationVariableName "OSDDownloadDestinationPath"
```
Downloads package PKG00001 to the task sequence cache and stores the path in the OSDDownloadDestinationPath task sequence variable.

### Example 2
```
PS C:\> Invoke-OSDDownloadContent -PackageID "PKG00001" -DestinationLocationType "CCMCache" -DestinationVariableName "OSDDownloadDestinationPath"
```
Downloads package PKG00001 to the Configuration Manager cache and stores the path in the OSDDownloadDestinationPath task sequence variable.

### Example 3
```
PS C:\> Invoke-OSDDownloadContent -PackageID "PKG00001" -DestinationLocationType "Custom" -DestinationVariableName "OSDDownloadDestinationPath" -CustomLocationPath "C:\Temp"
```
Downloads package PKG00001 to the custom path C:\Temp and stores the path in the OSDDownloadDestinationPath task sequence variable.

## PARAMETERS

### -PackageID
The PackageID of the content to download. Must match the pattern "^[A-Z0-9]{3}[A-F0-9]{5}$" (e.g., "PKG00001", "ABC12345").

```yaml
Type: String
Parameter Sets: NoPath, CustomPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationLocationType
The location type for content download. Valid values are:
- Custom: Download to a custom path specified by CustomLocationPath
- TSCache: Download to the task sequence cache
- CCMCache: Download to the Configuration Manager cache

```yaml
Type: String
Parameter Sets: NoPath, CustomPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationVariableName
The task sequence variable name to store the download location. This variable will contain the path where the content was downloaded after successful execution.

```yaml
Type: String
Parameter Sets: NoPath, CustomPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomLocationPath
The custom path for content download when DestinationLocationType is set to Custom. This parameter is required when using the CustomPath parameter set.

```yaml
Type: String
Parameter Sets: CustomPath
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

## NOTES
Part of the DriverAutomationModule module.
This function requires a task sequence environment to be available.
The function uses Confirm-TSEnvironmentSetup to verify the task sequence environment is properly initialized.
The function uses Set-TSVariable to set and clear task sequence variables.
All task sequence variables set by this function are automatically cleared after execution using Set-TSVariable with empty string values, regardless of success or failure.
The OSDDownloadContent executable must be available in the system PATH (WinPE) or at $env:WINDIR\CCM\OSDDownloadContent.exe (full OS).

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

