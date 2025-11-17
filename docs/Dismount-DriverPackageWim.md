---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Dismount-DriverPackageWim

## SYNOPSIS
Dismounts the driver package content WIM file from the specified mount path.

## SYNTAX

```
Dismount-DriverPackageWim -MountPath <String> [<CommonParameters>]
```

## DESCRIPTION
This function dismounts the driver package content WIM file from the specified mount path.
The function uses the Dismount-WindowsImage function from the OSDeploymentKit module to perform the dismount operation.
The -Discard parameter is used to discard any changes made to the mounted image, ensuring the WIM file remains unchanged.
All operations are logged using Write-LogEntry for debugging and audit purposes.
If the dismount operation fails, the function logs an error and throws an exception.

## EXAMPLES

### Example 1
```
PS C:\> Dismount-DriverPackageWim -MountPath "C:\Temp\DriverPackageMount"
```
Dismounts the driver package content WIM file from the mount path "C:\Temp\DriverPackageMount" and discards any changes.

## PARAMETERS

### -MountPath
The mount location for the driver package content WIM file.
This should be the same path that was used when mounting the WIM file.
The path must exist and contain a mounted WIM image.
This parameter is mandatory and must not be null or empty.

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
This function does not return any output. It performs the dismount operation and logs the result.

## NOTES
Part of the DriverAutomationModule module.
The function uses the Dismount-WindowsImage function from the OSDeploymentKit module to dismount the driver package content WIM file.
The -Discard parameter ensures that any modifications made to the mounted image are not saved back to the WIM file.
This function should be called after completing operations on the mounted driver package content.
All operations are logged using Write-LogEntry for debugging and audit purposes.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

