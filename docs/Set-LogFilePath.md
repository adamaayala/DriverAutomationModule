---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Set-LogFilePath

## SYNOPSIS
Sets the log file path based on the script execution context.

## SYNTAX

```
Set-LogFilePath -LogFileName <String> [<CommonParameters>]
```

## DESCRIPTION
Determines the appropriate log file path based on the execution environment.
If running in Windows PE (WinPE) and a task sequence environment is available, uses the task sequence log directory (_SMSTSLogPath).
If the task sequence environment is not available or not running in WinPE, uses the user's temporary directory.
The function attempts to connect to the Task Sequence Environment COM object to retrieve the log path.

## EXAMPLES

### Example 1
```
PS C:\> Set-LogFilePath -LogFileName 'myLog.log'
```
Returns the full path to the log file based on the current execution context.

## PARAMETERS

### -LogFileName
The name of the log file (e.g., 'myLog.log'). This parameter is mandatory.

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

### System.String
Returns the full path to the log file as a string.

## NOTES
Part of the DriverAutomationModule module.
The function checks for the presence of the X:\ drive to determine if running in WinPE.
If the Task Sequence Environment COM object cannot be accessed, the function falls back to using the temporary directory.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

