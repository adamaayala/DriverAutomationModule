---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Get-DriverPackageList

## SYNOPSIS
Retrieves driver package(s) from the Configuration Manager AdminService endpoint.

## SYNTAX

```
Get-DriverPackageList -Uri <String> [[-AdminServiceUser] <String>] [[-AdminServicePass] <String>]
    [<CommonParameters>]
```

## DESCRIPTION
This function retrieves driver package(s) from the Configuration Manager AdminService endpoint using a REST API call.
The function performs a GET request to the specified AdminService URI and returns an array of driver package objects.
Authentication can be performed using either provided credentials or default Windows credentials.
Default Windows credentials are used when credentials are not provided, which is the recommended approach for local testing scenarios.
If no driver packages are found, the function throws an error and logs a warning message.

## EXAMPLES

### Example 1
```
PS C:\> $uri = Set-DriverPackageQuery -ServerFQDN "CM01.contoso.com" -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
PS C:\> $driverPackages = Get-DriverPackageList -Uri $uri
```
Retrieves driver packages using default Windows credentials (useful for local testing) for a Dell device with SystemSKU 0A52 running Windows 11 x64.

### Example 2
```
PS C:\> $uri = Set-DriverPackageQuery -ServerFQDN "CM01.contoso.com" -TargetOS "Windows 10 x64"
PS C:\> $driverPackages = Get-DriverPackageList -Uri $uri -AdminServiceUser "DOMAIN\ServiceAccount" -AdminServicePass "SecurePassword123"
```
Retrieves driver packages for Windows 10 x64 using explicit credentials for authentication.

### Example 3
```
PS C:\> $driverPackages = Get-DriverPackageList -Uri 'https://cm01.contoso.com/AdminService/wmi/SMS_Package?$filter=startswith(Name,''Drivers -'')&$select=Name,PackageID'
```
Retrieves all driver packages using default Windows credentials (useful for local testing) with a custom query string.

## PARAMETERS

### -Uri
The full URI of the AdminService endpoint, including the OData query string and filter parameters.
This should be a complete URL pointing to the SMS_Package endpoint, typically constructed using Set-DriverPackageQuery.
Example: 'https://cm01.contoso.com/AdminService/wmi/SMS_Package?$filter=startswith(Name,'Drivers -')&$select=Name,Description,Manufacturer,Version,SourceDate,PackageID,MIFName,MIFVersion'

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

### -AdminServiceUser
The username to use for authentication with the AdminService endpoint. This parameter is optional.
If both AdminServiceUser and AdminServicePass are provided, the function will use these credentials for authentication.
If either parameter is omitted, the function will use default Windows credentials (UseDefaultCredentials), which is typically used for local testing scenarios.

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

### -AdminServicePass
The password to use for authentication with the AdminService endpoint. This parameter is optional.
If both AdminServiceUser and AdminServicePass are provided, the function will use these credentials for authentication.
If either parameter is omitted, the function will use default Windows credentials (UseDefaultCredentials), which is typically used for local testing scenarios.

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

### System.Object[]
Returns an array of driver package objects retrieved from the AdminService endpoint.
Each object contains properties such as Name, Description, Manufacturer, Version, SourceDate, PackageID, MIFName, and MIFVersion (depending on the $select clause in the URI).
If no packages are found, the function throws an error and does not return any output.

## NOTES
Part of the DriverAutomationModule module.
The function uses Invoke-RestMethod to perform the REST API call to the AdminService endpoint.
The response from the AdminService is expected to be in OData JSON format with a 'value' property containing the array of packages.
If the response does not contain a 'value' property or the value array is empty, the function will throw an error.
All authentication attempts and errors are logged using Write-LogEntry.
Default Windows credentials are used when credentials are not provided, which is the recommended approach for local testing scenarios.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

