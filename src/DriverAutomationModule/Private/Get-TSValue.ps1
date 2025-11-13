function Get-TSValue {
    <#
    .SYNOPSIS
        Retrieves the value of a specific Task Sequence variable.

    .DESCRIPTION
        This function retrieves the current value of a specified Task Sequence variable.
        It automatically initializes the Task Sequence Environment if it hasn't been initialized yet.
        If the Task Sequence Environment cannot be initialized or an error occurs while retrieving
        the variable, the function writes an error message to the host but does not throw an exception.

    .PARAMETER Name
        The name of the Task Sequence variable to retrieve. This parameter is mandatory.

    .INPUTS
        [System.String]
        The name of the Task Sequence variable to retrieve.

    .OUTPUTS
        None
        This function does not return any output. It retrieves the Task Sequence variable value directly.

    .EXAMPLE
        PS C:\> Get-TSValue -Name "OSDComputerName"
        Retrieves the value of the OSDComputerName Task Sequence variable.

    .EXAMPLE
        PS C:\> Get-TSValue -Name "OSDJoinDomain"
        Retrieves the value of the OSDJoinDomain Task Sequence variable.

    .EXAMPLE
        PS C:\> Get-TSValue -Name "NonExistentVariable"
        Attempts to retrieve a non-existent variable. Writes an error message if the variable does not exist.

    .NOTES
        This function is designed to be used in both production environments and Pester testing scenarios.
        It automatically handles Task Sequence Environment initialization and error cases gracefully.
        Errors are written to the host but do not cause the function to throw exceptions.

        Modified for use in Pester Testing and Task Sequences.

        Original Version:
        https://github.com/sombrerosheep/TaskSequenceModule

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    # Initialize Task Sequence Environment if needed
    if (-not (Confirm-TSEnvironmentSetup)) {
        Write-Host "Failed to confirm Task Sequence Environment"
    }

    try {
        return $script:TaskSequenceEnvironment.Value($Name)
    }
    catch {
        Write-Host "Failed to get Task Sequence variable: $Name"
    }
}
