function Confirm-TSEnvironmentSetup {
    <#
    .SYNOPSIS
    Verifies and initializes the Microsoft Configuration Manager Task Sequence Environment COM object.

    .DESCRIPTION
    This function checks if the Task Sequence Environment COM object has been initialized and creates it if it does not exist.
    The function stores the COM object in the module-scoped variable $script:TaskSequenceEnvironment for use by other functions in the module.
    The function returns a boolean value indicating whether the Task Sequence Environment is available: $true if successful, $false if initialization fails.

    .PARAMETER None
    This function does not accept any parameters.

    .EXAMPLE
    Confirm-TSEnvironmentSetup
    Verifies that the Task Sequence Environment COM object is initialized. If it is not already initialized, the function will attempt to create it.

    .INPUTS
    None

    .OUTPUTS
    System.Boolean
    Returns $true if the Task Sequence Environment is successfully initialized or already exists, $false if initialization fails.

    .NOTES
    Original Version:
    https://github.com/sombrerosheep/TaskSequenceModule

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
    )

    # If already initialized, return true
    if ($null -ne $script:TaskSequenceEnvironment) {
        return $true
    }

    # If inTSEnvironment is already set to false, return false
    if ($script:inTSEnvironment -eq $false) {
        return $false
    }

    # Attempt to initialize the Task Sequence Environment
    try {
        $script:TaskSequenceEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment
        $script:inTSEnvironment = $true
        return $true
    }
    catch {
        Write-Host "Unable to connect to the Task Sequence Environment."
        $script:inTSEnvironment = $false
        return $false
    }
}