---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Confirm-TSEnvironmentSetup

## SYNOPSIS
Verifies and initializes the Microsoft Configuration Manager Task Sequence Environment COM object.

## SYNTAX

```
Confirm-TSEnvironmentSetup [<CommonParameters>]
```

## DESCRIPTION
This function checks if the Task Sequence Environment COM object has been initialized and creates it if it does not exist.
The function stores the COM object in the module-scoped variable $script:TaskSequenceEnvironment for use by other functions in the module.
The function returns a boolean value indicating whether the Task Sequence Environment is available: $true if successful, $false if initialization fails.

## EXAMPLES

### Example 1
```
PS C:\> Confirm-TSEnvironmentSetup
```
Verifies that the Task Sequence Environment COM object is initialized. If it is not already initialized, the function will attempt to create it.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
This function does not accept any input.

## OUTPUTS

### System.Boolean
Returns $true if the Task Sequence Environment is successfully initialized or already exists, $false if initialization fails.

## NOTES
Original Version:
https://github.com/sombrerosheep/TaskSequenceModule

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

