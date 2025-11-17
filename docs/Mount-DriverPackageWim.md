---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Mount-DriverPackageWim

## SYNOPSIS
Mounts the driver package content WIM file.

## SYNTAX

```
Mount-DriverPackageWim -PackageDirectory <String> -MountPath <String> [<CommonParameters>]
```

## DESCRIPTION
This function locates and mounts the driver package content WIM file from the specified package directory to the given mount path.

The function performs the following operations:
- Recursively searches the PackageDirectory for a file named "DriverPackage.wim"
- Creates the MountPath directory if it does not exist
- Mounts the WIM file using Mount-WindowsImage with Index 1
- Logs the operation progress and results

If the WIM file is not found in the specified directory (including subdirectories), the function will throw an error.
If the mount operation fails, the function will log the error and throw an exception with details.

## EXAMPLES

### Example 1
```
PS C:\> Mount-DriverPackageWim -PackageDirectory "C:\Temp\DriverPackage" -MountPath "C:\Temp\DriverPackageMount"
```
Searches for DriverPackage.wim in C:\Temp\DriverPackage and mounts it to C:\Temp\DriverPackageMount.

### Example 2
```
PS C:\> Mount-DriverPackageWim -PackageDirectory "D:\Downloads\Drivers\Dell" -MountPath "D:\Mount\DellDrivers"
```
Searches for DriverPackage.wim in D:\Downloads\Drivers\Dell (including subdirectories) and mounts it to D:\Mount\DellDrivers.

### Example 3
```
PS C:\> Mount-DriverPackageWim -PackageDirectory "C:\DriverPackages\HP" -MountPath "C:\MountedDrivers"
```
Searches for DriverPackage.wim in C:\DriverPackages\HP and mounts it to C:\MountedDrivers. The mount path will be created if it does not exist.

## PARAMETERS

### -PackageDirectory
The full local path to the downloaded driver package content. The function will recursively search this directory and all subdirectories for a file named "DriverPackage.wim".

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
The mount location for the driver package content. This path will be created automatically if it does not exist.
The WIM file will be mounted to this location using Mount-WindowsImage with Index 1.

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
This function requires administrative privileges to mount WIM files.
The function uses Mount-WindowsImage with Index 1 to mount the WIM file.
The function will recursively search all subdirectories for the DriverPackage.wim file.
If the MountPath does not exist, it will be created automatically.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

