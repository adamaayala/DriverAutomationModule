---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Invoke-DISM

## SYNOPSIS
Invokes the DISM utility to apply drivers to the target system disk.

## SYNTAX

```
Invoke-DISM -MountPath <String> [[-OSDisk] <String>] [[-LogPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function uses the DISM (Deployment Image Servicing and Management) utility to apply drivers from a specified path to the target system disk.

The function executes DISM with the following parameters:
- /Image: Specifies the target system disk (default: C:)
- /Add-Driver: Instructs DISM to add drivers to the image
- /Driver: Specifies the path to the driver package content
- /Recurse: Recursively searches subdirectories for driver files (.inf files)

If a log path is specified, DISM will write detailed operation logs to that location. If not specified, DISM will use its default logging behavior.

The function uses Start-Process to execute DISM and waits for completion. On success, a log entry is written. On failure, an error is logged and thrown.

## EXAMPLES

### Example 1
```
PS C:\> Invoke-DISM -MountPath "C:\Drivers" -OSDisk "C:"
```
Applies drivers from C:\Drivers to the C: drive using default DISM logging.

### Example 2
```
PS C:\> Invoke-DISM -MountPath "C:\Drivers" -OSDisk "C:" -LogPath "C:\Logs\DISM.log"
```
Applies drivers from C:\Drivers to the C: drive and writes detailed logs to C:\Logs\DISM.log.

### Example 3
```
PS C:\> Invoke-DISM -MountPath "D:\DriverPackages\Dell" -OSDisk "D:"
```
Applies drivers from D:\DriverPackages\Dell to the D: drive.

## PARAMETERS

### -MountPath
The full local path to the downloaded driver package content. This path should contain driver files (.inf files) that will be applied to the target system disk.
The function will recursively search subdirectories for driver files.

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
The target system disk where drivers will be applied. Default is "C:".
This should be the drive letter of the system disk (e.g., "C:", "D:").

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: C:
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
The full path for the DISM log file. If not specified, DISM will use its default logging behavior.
Specifying a log path allows for detailed tracking of the driver installation process.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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
This function requires administrative privileges to modify the system disk.
The DISM utility must be available in the system PATH.
The function will recursively search subdirectories for driver files when using the /Recurse parameter.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

