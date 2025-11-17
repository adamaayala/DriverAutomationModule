---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Get-HardwareData

## SYNOPSIS
Gets the normalized hardware information of the computer.

## SYNTAX

```
Get-HardwareData [[-Manufacturer] <String>] [[-Model] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function retrieves and normalizes hardware information from the computer system, particularly standardizing manufacturer names and retrieving system-specific identifiers such as SystemSKU and SerialNumber.

The function supports the following manufacturers:
- Dell: Returns normalized manufacturer name "Dell", SystemSKU (from MS_SystemInformation), and SerialNumber (from Win32_SystemEnclosure)
- ClearTouch (including variants: "Clear Touch Interactive", "ClearTouch Interactive", "ClearTouch", "MAINBRD"): Returns normalized manufacturer name "ClearTouch", and uses the Model parameter as both SystemSKU and SerialNumber
- Alienware: Returns normalized manufacturer name "Alienware", SystemSKU (from MS_SystemInformation), and SerialNumber (from Win32_SystemEnclosure)
- Microsoft: Returns normalized manufacturer name "Microsoft" and SystemSKU (from MS_SystemInformation, no SerialNumber)
- HP/Hewlett-Packard: Returns normalized manufacturer name "Hewlett-Packard", Model (from Win32_ComputerSystem), and SystemSKU (from MS_SystemInformation BaseBoardProduct)
- Lenovo: Returns normalized manufacturer name "Lenovo", Model (from Win32_ComputerSystemProduct Version), and SystemSKU (first 4 characters of Win32_ComputerSystem Model)
- Panasonic: Returns normalized manufacturer name "Panasonic Corporation", Model (from Win32_ComputerSystem), and SystemSKU (from MS_SystemInformation BaseBoardProduct)
- Viglen: Returns normalized manufacturer name "Viglen", Model (from Win32_ComputerSystem), and SystemSKU (from Win32_BaseBoard SKU)
- AZW: Returns normalized manufacturer name "AZW", Model (from Win32_ComputerSystem), and SystemSKU (from MS_SystemInformation BaseBoardProduct)
- Fujitsu: Returns normalized manufacturer name "Fujitsu", Model (from Win32_ComputerSystem), and SystemSKU (from Win32_BaseBoard SKU)

For unsupported manufacturers, an empty hashtable is returned.

If Manufacturer or Model parameters are not provided, the function will automatically retrieve them from the Win32_ComputerSystem WMI class.
All retrieved values are trimmed of leading and trailing whitespace.

## EXAMPLES

### Example 1
```
PS C:\> Get-HardwareData
```
Retrieves hardware information from the system automatically and returns normalized hardware data.

### Example 2
```
PS C:\> Get-HardwareData -Manufacturer "Dell Inc." -Model "OptiPlex 7090"
```
Returns normalized Dell hardware data with SystemSKU and SerialNumber.

### Example 3
```
PS C:\> Get-HardwareData -Manufacturer "Clear Touch Interactive" -Model "CT-12345"
```
Returns normalized ClearTouch hardware data where the Model is used as both SystemSKU and SerialNumber.

### Example 4
```
PS C:\> Get-HardwareData -Manufacturer "Microsoft Corporation" -Model "Surface Pro 9"
```
Returns normalized Microsoft hardware data with SystemSKU only.

### Example 5
```
PS C:\> Get-HardwareData -Manufacturer "Hewlett-Packard" -Model "EliteBook 850 G8"
```
Returns normalized HP hardware data with Model and SystemSKU.

### Example 6
```
PS C:\> Get-HardwareData -Manufacturer "Lenovo" -Model "ThinkPad X1 Carbon"
```
Returns normalized Lenovo hardware data with Model and SystemSKU.

## PARAMETERS

### -Manufacturer
The manufacturer of the computer. If not provided, it will be retrieved from the Win32_ComputerSystem WMI class.
The value will be trimmed of leading and trailing whitespace.

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

### -Model
The model of the computer. If not provided, it will be retrieved from the Win32_ComputerSystem WMI class.
The value will be trimmed of leading and trailing whitespace.

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

### System.Collections.Hashtable
Returns a hashtable containing normalized hardware information. The hashtable may contain the following keys:
- Manufacturer: The normalized manufacturer name (e.g., "Dell", "ClearTouch", "Alienware", "Microsoft", "Hewlett-Packard", "Lenovo", "Panasonic Corporation", "Viglen", "AZW", "Fujitsu")
- Model: The system model (included for HP, Lenovo, Panasonic, Viglen, AZW, and Fujitsu)
- SystemSKU: The system SKU identifier (retrieved from various WMI classes depending on manufacturer)
- SerialNumber: The system serial number (retrieved from Win32_SystemEnclosure WMI class for Dell and Alienware; uses Model parameter for ClearTouch; not included for Microsoft, HP, Lenovo, Panasonic, Viglen, AZW, or Fujitsu)

For unsupported manufacturers, an empty hashtable is returned.

## NOTES
Part of the DriverAutomationModule module.
The function uses wildcard matching for manufacturer names, allowing for variations in manufacturer naming.
Supported wildcard patterns include: "*Dell*", "*Alienware*", "*Microsoft*", "*HP*", "*Hewlett-Packard*", "*Lenovo*", "*Panasonic*", "*Viglen*", "*AZW*", "*Fujitsu*"
ClearTouch uses exact matching for specific variants: "Clear Touch Interactive", "ClearTouch Interactive", "ClearTouch", "MAINBRD"
All retrieved values are trimmed of leading and trailing whitespace.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

