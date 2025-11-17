---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Set-DriverPackageQueryResult

## SYNOPSIS
Sets the Driver Package search results to Task Sequence variables.

## SYNTAX

```
Set-DriverPackageQueryResult [-Description] <String> [-Manufacturer] <String> [-Name] <String>
    [-PackageID] <String> [-Version] <String> [<CommonParameters>]
```

## DESCRIPTION
This function sets the Driver Package search results to Task Sequence variables for later use.
Each parameter value is stored in a Task Sequence variable with the prefix "XDriver" followed by the parameter name.
For example, the Description parameter is stored as "XDriverDescription", Manufacturer as "XDriverManufacturer", etc.

## EXAMPLES

### Example 1
```
PS C:\> Set-DriverPackageQueryResult -Description "Network Driver" -Manufacturer "Intel" -Name "Intel Network Adapter" -PackageID "PACK001" -Version "1.0.0"
```
Sets the Driver Package search results to Task Sequence variables: XDriverDescription, XDriverManufacturer, XDriverName, XDriverPackageID, and XDriverVersion.

### Example 2
```
PS C:\> $driverPackage | Set-DriverPackageQueryResult
```
Accepts a driver package object from the pipeline and sets the corresponding Task Sequence variables.

## PARAMETERS

### -Description
The Description of the Driver Package. This parameter is mandatory and accepts pipeline input.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### -Manufacturer
The Manufacturer of the Driver Package. This parameter is mandatory and accepts pipeline input.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### -Name
The Name of the Driver Package. This parameter is mandatory and accepts pipeline input.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### -PackageID
The Package ID of the Driver Package. This parameter is mandatory and accepts pipeline input.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### -Version
The Version of the Driver Package. This parameter is mandatory and accepts pipeline input.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object
This function accepts pipeline input by property name or by value.

## OUTPUTS

### None
This function does not return any output. It sets Task Sequence variables directly.

## NOTES
Part of the DriverAutomationModule module.
This function requires the Task Sequence Environment to be initialized. The Set-TSVariable function is used internally to set the variables.

## RELATED LINKS
https://github.com/adamaayala/OSDeploymentKit

