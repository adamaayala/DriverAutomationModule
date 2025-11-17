# Integration Tests

This directory contains integration tests for the DriverAutomationModule.

## Test Types

### Mocked Integration Tests

The main integration tests use mocked dependencies to test the workflow without requiring external services. These tests are safe to run in any environment.

### Live Server Integration Tests

Tests that connect to the actual Configuration Manager AdminService server at `escsccm.amaisd.org`. These tests use your current Windows credentials for authentication.

## Running Tests

### Running All Integration Tests

```powershell
# Run all integration tests (including live server tests)
Invoke-Pester 'src/Tests/Integration' -Output Detailed

# Run via Invoke-Build
Invoke-Build -Task IntegrationTest
```

### Running Specific Test Types

```powershell
# Run only live server tests
Invoke-Pester 'src/Tests/Integration/Deploy-DriverPackage.Improved.Tests.ps1' -Tag LiveServer -Output Detailed

# Run only mocked tests (exclude live server tests)
Invoke-Pester 'src/Tests/Integration/Deploy-DriverPackage.Improved.Tests.ps1' -Tag Integration -ExcludeTag LiveServer -Output Detailed
```

### Live Server Configuration

The live server tests are configured with:
- **Server FQDN**: `escsccm.amaisd.org`
- **Target OS**: `Windows 11 x64`
- **Authentication**: Windows default credentials (current user)

No environment variables or credentials are required - the tests use your current Windows credentials automatically.

### Test Coverage

Live server tests verify:
1. Connection to AdminService endpoint at `escsccm.amaisd.org`
2. Authentication using Windows default credentials
3. Driver package query functionality
4. Find phase execution against live server
5. Server connectivity verification

## Prerequisites

For live server tests to work:
- Network connectivity to `escsccm.amaisd.org`
- Your Windows account must have permissions to query SMS_Package in Configuration Manager
- The machine must be domain-joined or have appropriate network access

## Troubleshooting

### Connection Issues

If tests fail to connect:
1. Verify network connectivity: `Test-NetConnection -ComputerName escsccm.amaisd.org -Port 443`
2. Check firewall rules
3. Verify AdminService is accessible: `Invoke-WebRequest -Uri "https://escsccm.amaisd.org/AdminService" -UseDefaultCredentials`

### Authentication Issues

If authentication fails:
1. Verify your account has permissions to query SMS_Package in Configuration Manager
2. Ensure you're running from a domain-joined machine
3. Test with `Invoke-RestMethod` directly to verify authentication:
   ```powershell
   $uri = "https://escsccm.amaisd.org/AdminService/wmi/SMS_Package"
   Invoke-RestMethod -Uri $uri -UseDefaultCredentials
   ```

### Test Environment

Ensure you're running tests from a machine that:
- Has network access to `escsccm.amaisd.org`
- Is domain-joined (for Windows authentication)
- Has PowerShell execution policy that allows script execution

