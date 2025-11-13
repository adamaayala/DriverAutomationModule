function Set-DriverPackageQueryResult {
    <#
    .SYNOPSIS
        Sets the Driver Package search results to Task Sequence variables.

    .DESCRIPTION
        This function sets the Driver Package search results to Task Sequence variables for later use.
        Each parameter value is stored in a Task Sequence variable with the prefix "XDriver" followed by the parameter name.
        For example, the Description parameter is stored as "XDriverDescription", Manufacturer as "XDriverManufacturer", etc.

    .PARAMETER Description
        The Description of the Driver Package. This parameter is mandatory and accepts pipeline input.

    .PARAMETER Manufacturer
        The Manufacturer of the Driver Package. This parameter is mandatory and accepts pipeline input.

    .PARAMETER Name
        The Name of the Driver Package. This parameter is mandatory and accepts pipeline input.

    .PARAMETER PackageID
        The Package ID of the Driver Package. This parameter is mandatory and accepts pipeline input.

    .PARAMETER Version
        The Version of the Driver Package. This parameter is mandatory and accepts pipeline input.

    .INPUTS
        System.Object
        This function accepts pipeline input by property name or by value.

    .OUTPUTS
        None
        This function does not return any output. It sets Task Sequence variables directly.

    .EXAMPLE
        PS C:\> Set-DriverPackageQueryResult -Description "Network Driver" -Manufacturer "Intel" -Name "Intel Network Adapter" -PackageID "PACK001" -Version "1.0.0"
        Sets the Driver Package search results to Task Sequence variables: XDriverDescription, XDriverManufacturer, XDriverName, XDriverPackageID, and XDriverVersion.

    .EXAMPLE
        PS C:\> $driverPackage | Set-DriverPackageQueryResult
        Accepts a driver package object from the pipeline and sets the corresponding Task Sequence variables.

    .NOTES
        Part of the DriverAutomationModule module.
        This function requires the Task Sequence Environment to be initialized. The Set-TSVariable function is used internally to set the variables.

    .LINK
        https://github.com/adamaayala/OSDeploymentKit
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [string]$Manufacturer,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [string]$PackageID,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [string]$Version
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            foreach ($param in $PSBoundParameters.GetEnumerator()) {
                $params = @{
                    Name  = "XDriver$($param.Key)"
                    Value = $param.Value
                }
                Set-TSVariable @params
            }

            Write-LogEntry -Message "Successfully set the Driver Package search results to Task Sequence variables." -Source $cmdletName -Severity 0
        }
        catch {
            $errorMessage = "Failed to set the Driver Package search results to Task Sequence variables: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
    }
}