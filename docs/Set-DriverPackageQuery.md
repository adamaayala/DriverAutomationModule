---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Set-DriverPackageQuery

## SYNOPSIS
Builds an OData query URL for the Configuration Manager AdminService to retrieve driver packages.

## SYNTAX

```
Set-DriverPackageQuery -ServerFQDN <String> [[-Manufacturer] <String>] [[-SystemSKU] <String>]
    [[-TargetOS] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function constructs an OData query URL string for the Configuration Manager AdminService to retrieve driver packages.
The query filters driver packages based on the provided parameters: SystemSKU, Manufacturer, and TargetOS.
The function builds a URL-encoded query string that filters packages by name (starting with 'Drivers -') and optionally filters by SystemSKU in the description, Manufacturer in the name, and TargetOS in the name.
The query selects specific properties: Name, Description, Manufacturer, Version, SourceDate, PackageID, MIFName, and MIFVersion.

## EXAMPLES

### Example 1
```
PS C:\> $url = Set-DriverPackageQuery -ServerFQDN "CM01.domain.local" -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
```
Constructs a query URL for Dell driver packages with SystemSKU 0A52 for Windows 11 x64.

### Example 2
```
PS C:\> $url = Set-DriverPackageQuery -ServerFQDN "CM01.domain.local" -TargetOS "Windows 10 x64"
```
Constructs a query URL for all driver packages for Windows 10 x64 without filtering by manufacturer or SystemSKU.

## PARAMETERS

### -ServerFQDN
The internal fully qualified domain name of the server hosting the AdminService, e.g. CM01.domain.local.

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

### -Manufacturer
The manufacturer of the device, if available. This parameter is optional. If provided, the query will filter packages that contain the manufacturer name in the package name.

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

### -SystemSKU
The SKU of the device, if available. This parameter is optional. If provided, the query will filter packages that contain the SystemSKU in the package description.

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

### -TargetOS
The target operating system. Valid values are 'Windows 10 x64' and 'Windows 11 x64'. This parameter is optional. If provided, the query will filter packages that contain the TargetOS in the package name.

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

### System.String
Returns a URL-encoded OData query string that can be used with the Configuration Manager AdminService to retrieve driver packages.

## NOTES
Part of the DriverAutomationModule module.
The function constructs an OData query using $filter and $select parameters. The base filter always includes packages that start with 'Drivers -' in the name.
Additional filters are appended based on the optional parameters provided. The final URL is URI-encoded to ensure proper formatting.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

