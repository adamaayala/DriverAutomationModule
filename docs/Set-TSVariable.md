---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Set-TSVariable

## SYNOPSIS
Sets or creates a Task Sequence variable with the specified value.

## SYNTAX

```
Set-TSVariable [-Name] <String> [-Value] <String> [<CommonParameters>]
```

## DESCRIPTION
This function sets or creates a Task Sequence variable with the specified value.
It automatically initializes the Task Sequence Environment if it hasn't been initialized yet.
If the Task Sequence Environment cannot be initialized or an error occurs while setting the variable,
the function writes an error message to the host but does not throw an exception.

## EXAMPLES

### Example 1
```
PS C:\> Set-TSVariable -Name "OSDComputerName" -Value "MyComputer123"
```
Sets the OSDComputerName task sequence variable to "MyComputer123"

### Example 2
```
PS C:\> Set-TSVariable -Name "OSDJoinDomain" -Value "contoso.com"
```
Sets the OSDJoinDomain task sequence variable to "contoso.com"

### Example 3
```
PS C:\> Set-TSVariable -Name "OSDComputerName" -Value ""
```
Sets the OSDComputerName task sequence variable to an empty string

## PARAMETERS

### -Name
The name of the Task Sequence variable to set or create. This parameter is mandatory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The value to set for the Task Sequence variable. This parameter is mandatory.
Empty strings are allowed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
The name of the Task Sequence variable to set or create.

### System.String
The value to set for the Task Sequence variable.

## OUTPUTS

### None
This function does not return any output. It sets the Task Sequence variable directly.

## NOTES
This function is designed to be used in both production environments and Pester testing scenarios.
It automatically handles Task Sequence Environment initialization and error cases gracefully.
Errors are written to the host but do not cause the function to throw exceptions.

Modified for use in Pester Testing and Task Sequences.

Original Version:
https://github.com/sombrerosheep/TaskSequenceModule

## RELATED LINKS
https://github.com/adamaayala/TaskSequenceModule

