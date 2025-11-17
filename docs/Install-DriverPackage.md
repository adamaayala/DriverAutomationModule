---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Install-DriverPackage

## SYNOPSIS
Installs a driver package on the target system.

## SYNTAX

```
Install-DriverPackage -DriverPackagePath <String> -OSDisk <String> -MountPath <String>
    [<CommonParameters>]
```

## DESCRIPTION
This function mounts a driver package WIM file, applies the drivers to the target system using DISM, and then dismounts the WIM file.

The function performs the following operations:
1. Mounts the driver package WIM file using Mount-DriverPackageWim
2. Applies the drivers to the target system using Invoke-DISM
3. Dismounts the driver package WIM file using Dismount-DriverPackageWim

## EXAMPLES

### Example 1
```
PS C:\> Install-DriverPackage -DriverPackagePath "C:\DriverPackageContent" -OSDisk "C:" -MountPath "C:\Mount"
```
Mounts the driver package WIM file from C:\DriverPackageContent, applies drivers to the C: drive, and then dismounts the WIM file.

## PARAMETERS

### -DriverPackagePath
The path to the driver package content. This parameter is mandatory.

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

### -OSDisk
The target system drive. This parameter is mandatory.

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

### -MountPath
The mount path. This parameter is mandatory.

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

## NOTES
Part of the DriverAutomationModule module.

## RELATED LINKS
https://github.com/adamaayala/OSDeploymentKit

