function Confirm-TSEnvironmentSetup {
    <#
    .SYNOPSIS
    Verifies and initializes the Microsoft Configuration Manager Task Sequence Environment COM object.

    .DESCRIPTION
    This function checks if the Task Sequence Environment COM object has been initialized and creates it if it does not exist.
    The function stores the COM object in the module-scoped variable $script:TaskSequenceEnvironment for use by other functions in the module.

    .PARAMETER None
    This function does not accept any parameters.

    .EXAMPLE
    Confirm-TSEnvironmentSetup
    Verifies that the Task Sequence Environment COM object is initialized. If it is not already initialized, the function will attempt to create it.

    .INPUTS
    None

    .OUTPUTS
    None

    .NOTES
    Original Version:
    https://github.com/sombrerosheep/TaskSequenceModule

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
    )
    if ($null -eq $script:TaskSequenceEnvironment) {
        try {
            $script:TaskSequenceEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment
        }
        catch {
            Write-Host "Unable to connect to the Task Sequence Environment."
        }
    }
}