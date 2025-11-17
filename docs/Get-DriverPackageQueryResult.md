---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Get-DriverPackageQueryResult

## SYNOPSIS
Retrieves Driver Package search results from Task Sequence variables and returns them as a hashtable.

## SYNTAX

```
Get-DriverPackageQueryResult [[-VariablePrefix] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function retrieves Driver Package search results from Task Sequence variables and returns them as a hashtable.
The function looks for Task Sequence variables with names prefixed by the specified VariablePrefix (default: "XDriver")
followed by the property names: Description, Manufacturer, Name, PackageID, and Version.

## EXAMPLES

### Example 1
```
PS C:\> Get-DriverPackageQueryResult
```
Retrieves Driver Package search results using the default prefix "XDriver" and returns a hashtable.

### Example 2
```
PS C:\> Get-DriverPackageQueryResult -VariablePrefix "CustomDriver"
```
Retrieves Driver Package search results using the custom prefix "CustomDriver" (e.g., "CustomDriverDescription", "CustomDriverManufacturer", etc.).

## PARAMETERS

### -VariablePrefix
The prefix used for Task Sequence variable names. Default value is "XDriver".
For example, with the default prefix, the function will look for variables like "XDriverDescription", "XDriverManufacturer", etc.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: XDriver
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
The VariablePrefix parameter accepts a string value.

## OUTPUTS

### System.Collections.Hashtable
Returns a hashtable containing the Driver Package properties with the following keys:
- Description: The Description of the Driver Package
- Manufacturer: The Manufacturer of the Driver Package
- Name: The Name of the Driver Package
- PackageID: The Package ID of the Driver Package
- Version: The Version of the Driver Package

## NOTES
Part of the DriverAutomationModule module.
This function requires the Task Sequence Environment to be initialized. The Get-TSValue function is used internally to retrieve the variables.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

