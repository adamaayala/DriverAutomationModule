. $PSScriptRoot\Imports.ps1

$itemSplat = @{
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}
try {
    $public = @(Get-ChildItem -Path "$PSScriptRoot\Public" @itemSplat)
    $private = @(Get-ChildItem -Path "$PSScriptRoot\Private" @itemSplat)
}
catch {
    Write-Error $_
    throw 'Unable to get get file information from Public & Private src.'
}

foreach ($file in @($public + $private)) {
    try {
        . $file.FullName
    }
    catch {
        throw ('Unable to dot source {0}' -f $file.FullName)
    }
}

# Export public functions - extract basenames explicitly
$functionsToExport = foreach ($file in $public) {
    $file.Basename
}

if ($functionsToExport.Count -gt 0) {
    Export-ModuleMember -Function $functionsToExport
}