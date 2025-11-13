function Set-TSVariable {
    <#
    .SYNOPSIS
        Sets or creates a Task Sequence variable with the specified value.

    .DESCRIPTION
        This function sets or creates a Task Sequence variable with the specified value.
        It automatically initializes the Task Sequence Environment if it hasn't been initialized yet.
        If the Task Sequence Environment cannot be initialized or an error occurs while setting the variable,
        the function writes an error message to the host but does not throw an exception.

    .PARAMETER Name
        The name of the Task Sequence variable to set or create. This parameter is mandatory.

    .PARAMETER Value
        The value to set for the Task Sequence variable. This parameter is mandatory.
        Empty strings are allowed.

    .INPUTS
        [System.String]
        The name of the Task Sequence variable to set or create.

        [System.String]
        The value to set for the Task Sequence variable.

    .OUTPUTS
        None
        This function does not return any output. It sets the Task Sequence variable directly.

    .EXAMPLE
        PS C:\> Set-TSVariable -Name "OSDComputerName" -Value "MyComputer123"
        Sets the OSDComputerName task sequence variable to "MyComputer123"

    .EXAMPLE
        PS C:\> Set-TSVariable -Name "OSDJoinDomain" -Value "contoso.com"
        Sets the OSDJoinDomain task sequence variable to "contoso.com"

    .EXAMPLE
        PS C:\> Set-TSVariable -Name "OSDComputerName" -Value ""
        Sets the OSDComputerName task sequence variable to an empty string

    .NOTES
        This function is designed to be used in both production environments and Pester testing scenarios.
        It automatically handles Task Sequence Environment initialization and error cases gracefully.
        Errors are written to the host but do not cause the function to throw exceptions.

        Modified for use in Pester Testing and Task Sequences.

        Original Version:
        https://github.com/sombrerosheep/TaskSequenceModule

    .LINK
        https://github.com/adamaayala/TaskSequenceModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [string]$Value
    )

    # Initialize Task Sequence Environment if needed
    if (-not (Confirm-TSEnvironmentSetup)) {
        Write-Host "Failed to confirm Task Sequence Environment"
    }

    try {
        $script:TaskSequenceEnvironment.Value($Name) = $Value
    }
    catch {
        Write-Host "Failed to set Task Sequence variable: $Name"
    }
}
