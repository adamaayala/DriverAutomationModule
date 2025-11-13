function Get-DriverPackageQueryResult {
    <#
    .SYNOPSIS
        Retrieves Driver Package search results from Task Sequence variables and returns them as a hashtable.

    .DESCRIPTION
        This function retrieves Driver Package search results from Task Sequence variables and returns them as a hashtable.
        The function looks for Task Sequence variables with names prefixed by the specified VariablePrefix (default: "XDriver")
        followed by the property names: Description, Manufacturer, Name, PackageID, and Version.

    .PARAMETER VariablePrefix
        The prefix used for Task Sequence variable names. Default value is "XDriver".
        For example, with the default prefix, the function will look for variables like "XDriverDescription", "XDriverManufacturer", etc.

    .INPUTS
        [System.String]
        The VariablePrefix parameter accepts a string value.

    .OUTPUTS
        [System.Collections.Hashtable]
        Returns a hashtable containing the Driver Package properties with the following keys:
        - Description: The Description of the Driver Package
        - Manufacturer: The Manufacturer of the Driver Package
        - Name: The Name of the Driver Package
        - PackageID: The Package ID of the Driver Package
        - Version: The Version of the Driver Package

    .EXAMPLE
        PS C:\> Get-DriverPackageQueryResult
        Retrieves Driver Package search results using the default prefix "XDriver" and returns a hashtable.

    .EXAMPLE
        PS C:\> Get-DriverPackageQueryResult -VariablePrefix "CustomDriver"
        Retrieves Driver Package search results using the custom prefix "CustomDriver" (e.g., "CustomDriverDescription", "CustomDriverManufacturer", etc.).

    .NOTES
        Part of the DriverAutomationModule module.
        This function requires the Task Sequence Environment to be initialized. The Get-TSValue function is used internally to retrieve the variables.

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$VariablePrefix = "XDriver"
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            $taskSequenceVariableNames = @("Description", "Manufacturer", "Name", "PackageID", "Version")
            $result = @{}
            foreach ($variableName in $taskSequenceVariableNames) {
                $taskSequenceVariableValue = Get-TSValue -Name ("{0}{1}" -f $VariablePrefix, $variableName)

                Write-LogEntry -Message "$variableName : $variableValue" -Source $cmdletName
                $result.Add($variableName, $taskSequenceVariableValue)
            }
            return $result
        }
        catch {
            $errorMessage = "Failed to get the Driver Package search results from the Task Sequence variables: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
    }
}