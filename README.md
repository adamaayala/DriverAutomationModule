# DriverAutomationModule

## Synopsis

PowerShell module designed exclusively for Configuration Manager Task Sequences to automate driver package deployment during Operating System Deployment (OSD). This module provides functions to find, download, and install driver packages as part of the Windows deployment process.

## Description

The DriverAutomationModule is designed to run exclusively within Configuration Manager Task Sequences during Operating System Deployment. It automates driver package deployment by:

- **Finding** appropriate driver packages by querying the Configuration Manager AdminService based on hardware information
- **Downloading** driver package content from the distribution point to the Task Sequence data path
- **Installing** drivers to target systems using DISM (Deployment Image Servicing and Management)

The module requires a Task Sequence environment and uses Task Sequence variables for configuration and state management. It supports automatic hardware detection and normalization for multiple manufacturers including Dell, HP, Lenovo, Microsoft, Alienware, ClearTouch, Panasonic, Viglen, AZW, and Fujitsu.

All operations are logged using CMTrace-compatible log files to the Task Sequence log directory for troubleshooting and audit purposes.

**Important**: This module is not intended for manual execution or use outside of Configuration Manager Task Sequences. It requires the Task Sequence COM object and Task Sequence variables to function properly.

### Driver Package Creation

This module is designed to work with driver packages created by the [Driver Automation Tool](https://github.com/maurice-daly/DriverAutomationTool) by Maurice Daly. The Driver Automation Tool creates driver packages in Configuration Manager with specific naming conventions and structure that this module expects:

- **Package Naming**: Packages must be named with the prefix "Drivers -" followed by manufacturer, model, and operating system information (e.g., "Drivers - Dell - Latitude 7480 - Windows 11 x64")
- **Package Structure**: Packages must contain a WIM file named `DriverPackage.wim` that contains the driver files
- **Package Metadata**: The SystemSKU value must be included in the package description for proper matching
- **Package Format**: The module expects WIM-based driver packages created by the Driver Automation Tool

For information on creating driver packages, see the [Driver Automation Tool documentation](https://github.com/maurice-daly/DriverAutomationTool) and the [Modern Driver Management implementation guide](https://www.msendpointmgr.com/modern-driver-management/).

## Getting Started

### Prerequisites

- Microsoft Endpoint Manager (Configuration Manager) with AdminService enabled
- Driver packages created using the [Driver Automation Tool](https://github.com/maurice-daly/DriverAutomationTool) (packages must be named with "Drivers -" prefix and contain `DriverPackage.wim` files)
- An OSD Task Sequence for deploying Windows operating systems
- OSDDownloadContent utility (available in WinPE or full OS at `$env:WINDIR\CCM\OSDDownloadContent.exe`)
- DISM (Deployment Image Servicing and Management) for driver installation

### Task Sequence Integration

This module is designed to run exclusively within Configuration Manager Task Sequences during Operating System Deployment (OSD). The module files must be included in a Configuration Manager package and deployed as part of the Task Sequence.

#### Step 1: Build the Module

Build the compiled module from source:

```powershell
.\src\DriverAutomationModule.build.ps1
```

The compiled module will be available at `.\src\Artifacts\DriverAutomationModule.psm1`

#### Step 2: Create a Configuration Manager Package

1. Create a new package in Configuration Manager containing:
   - The compiled `DriverAutomationModule.psm1` file
   - The `DriverAutomationModule.psd1` manifest file
   - The `Deploy-DriverPackage.Improved.ps1` script from `.\src\Scripts\`

2. Distribute the package to your distribution points

#### Step 3: Add to Task Sequence

Add a "Run PowerShell Script" step to your OSD Task Sequence:

1. **Step Name**: "Deploy Driver Package" (or similar)
2. **Package**: Select the package created in Step 2
3. **Script Name**: `Deploy-DriverPackage.Improved.ps1`
4. **Parameters**: (Optional) Specify phase or working directory if needed
   - `-Phase Find` - Execute only the Find phase
   - `-Phase Download` - Execute only the Download phase
   - `-Phase Install` - Execute only the Install phase
   - (No parameter) - Execute all phases sequentially

#### Step 4: Configure Task Sequence Variables

Set the following Task Sequence variables before the driver deployment step:

- `AdminServiceFQDN`: The FQDN of your Configuration Manager AdminService server (e.g., "cm01.contoso.com")
- `OSDWindowsVersion`: The target Windows version (e.g., "Windows 11 x64" or "Windows 10 x64")
- `OSDTargetSystemDrive`: The target system drive letter (typically "C:")

Optional variables for AdminService authentication:

- `AdminServiceUser`: Username for AdminService authentication (if not using default credentials)
- `AdminServicePass`: Password for AdminService authentication (if not using default credentials)

### Task Sequence Workflow

The module executes in three phases:

1. **Find Phase**: Queries the AdminService to locate the appropriate driver package based on hardware information
2. **Download Phase**: Downloads the driver package content to the Task Sequence data path
3. **Install Phase**: Mounts the WIM file and installs drivers to the target system using DISM

All phases execute automatically when the Task Sequence step runs. The module uses Task Sequence variables for configuration and state management.

## Functions

### Public Functions

- **Find-DriverPackage**: Finds the appropriate driver package by querying the Configuration Manager AdminService based on hardware information
- **Get-DriverPackageContent**: Downloads driver package content from Configuration Manager to a specified custom location
- **Install-DriverPackage**: Mounts a driver package WIM file and installs drivers to the target system using DISM
- **Write-LogEntry**: Writes CMTrace-compatible log entries for debugging and audit purposes

### Private Functions

The module includes several private helper functions for hardware detection, query construction, WIM mounting, and Task Sequence variable management.

## Task Sequence Configuration

### Driver Package Requirements

Driver packages must be created using the Driver Automation Tool and meet the following requirements:

- Package name must start with "Drivers -"
- Package must contain a WIM file named `DriverPackage.wim` in the package content
- Package description must include the SystemSKU value for proper hardware matching
- Package name should include manufacturer and target operating system information

The module queries the Configuration Manager AdminService for packages matching these criteria based on hardware information (Manufacturer, SystemSKU) and target operating system.

### Task Sequence Step Placement

The driver deployment step should be placed in your Task Sequence:

- **After**: Operating system image application
- **Before**: Windows Setup or first boot configuration steps
- **Context**: Can run in both WinPE and full Windows environments

The module automatically detects the environment and uses the appropriate paths and utilities.

### Task Sequence Variables

#### Required Variables (Set Before Driver Deployment Step)

- `AdminServiceFQDN`: The FQDN of the AdminService server (e.g., "cm01.contoso.com")
- `OSDWindowsVersion`: The target Windows version (e.g., "Windows 11 x64" or "Windows 10 x64")
- `OSDTargetSystemDrive`: The target system drive letter (typically "C:")

#### Optional Variables

- `AdminServiceUser`: Username for AdminService authentication (if not using default credentials)
- `AdminServicePass`: Password for AdminService authentication (if not using default credentials)

#### Variables Set by the Module

- `XDriverPackageID`: The PackageID of the found driver package
- `XDriverName`: The name of the driver package
- `XDriverVersion`: The version of the driver package
- `XDriverDescription`: The description of the driver package
- `XDriverManufacturer`: The manufacturer of the driver package
- `DriverPackagePath`: The path to the downloaded driver package content (set by Get-DriverPackageContent)

#### Built-in Task Sequence Variables Used

- `_SMSTSMDataPath`: The Task Sequence data path (automatically available in Task Sequences)

## Supported Hardware Manufacturers

The module supports automatic hardware detection and normalization for:

- Dell
- HP (Hewlett-Packard)
- Lenovo
- Microsoft
- Alienware
- ClearTouch
- Panasonic
- Viglen
- AZW
- Fujitsu

## Supported Operating Systems

- Windows 10 x64
- Windows 11 x64

## Logging

All module functions use `Write-LogEntry` to create CMTrace-compatible log files. Log files are created in the Task Sequence log directory (`_SMSTSLogPath`) with the format:

```text
[MM-dd-yyyy HH:mm:ss.fff] [Source] [Severity] :: Message
```

Log severity levels:

- 0: Success
- 1: Informational
- 2: Warning
- 3: Error

## Development and Testing

The module includes comprehensive Pester tests for all functions. These tests are intended for development and validation purposes only. Run tests using:

```powershell
Invoke-Pester -Path .\src\Tests
```

**Note**: The module is designed to run exclusively within Task Sequences. The module includes wrapper functions (`Get-TSValue` and `Set-TSVariable`) that abstract Task Sequence variable access, allowing these functions to be mocked in tests without requiring direct mocking of the Task Sequence COM object.

## Contributing

Contributions are welcome! Please ensure that:

- All functions include comprehensive help documentation
- Code follows PowerShell best practices
- Tests are included for new functionality
- Code passes PSScriptAnalyzer validation

## License

See the [LICENSE](LICENSE) file for details.

## Author

Adam Ayala

## Related Tools

This module is designed to work with driver packages created by:

- **[Driver Automation Tool](https://github.com/maurice-daly/DriverAutomationTool)**: Creates and manages driver packages in Configuration Manager. This tool downloads drivers from manufacturer websites (Dell, HP, Lenovo, Microsoft Surface) and packages them for deployment.

For more information on modern driver management strategies, see:

- [Modern Driver Management Implementation Guide](https://www.msendpointmgr.com/modern-driver-management/)
- [Modern BIOS Management Implementation Guide](https://www.msendpointmgr.com/modern-bios-management/)

## Links

- [Project Repository](https://github.com/adamaayala/DriverAutomationModule)
- [License](https://github.com/adamaayala/DriverAutomationModule/blob/main/LICENSE)
- [Driver Automation Tool Repository](https://github.com/maurice-daly/DriverAutomationTool)
