---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Get-TSValue

## SYNOPSIS
Retrieves the value of a specific Task Sequence variable.

## SYNTAX

```
Get-TSValue [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
This function retrieves the current value of a specified Task Sequence variable.
It automatically initializes the Task Sequence Environment if it hasn't been initialized yet.
If the Task Sequence Environment cannot be initialized or an error occurs while retrieving
the variable, the function writes an error message to the host but does not throw an exception.

## EXAMPLES

### Example 1
```
PS C:\> Get-TSValue -Name "OSDComputerName"
```
Retrieves the value of the OSDComputerName Task Sequence variable.

### Example 2
```
PS C:\> Get-TSValue -Name "OSDJoinDomain"
```
Retrieves the value of the OSDJoinDomain Task Sequence variable.

### Example 3
```
PS C:\> Get-TSValue -Name "NonExistentVariable"
```
Attempts to retrieve a non-existent variable. Writes an error message if the variable does not exist.

## PARAMETERS

### -Name
The name of the Task Sequence variable to retrieve. This parameter is mandatory.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
The name of the Task Sequence variable to retrieve.

## OUTPUTS

### None
This function does not return any output. It retrieves the Task Sequence variable value directly.

## NOTES
This function is designed to be used in both production environments and Pester testing scenarios.
It automatically handles Task Sequence Environment initialization and error cases gracefully.
Errors are written to the host but do not cause the function to throw exceptions.

Modified for use in Pester Testing and Task Sequences.

Original Version:
https://github.com/sombrerosheep/TaskSequenceModule

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

