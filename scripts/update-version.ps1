param (
    [switch]$restore
)

# Read version.txt
$version = Get-Content -Path "$PSScriptRoot/../version.txt"

# Path to the mod.template.json file
$jsonTemplatePath = "$PSScriptRoot/../mod.template.json"
$jsonTemplateBackupPath = "$PSScriptRoot/../mod.template.json.bak"

if ($restore) {
    if (Test-Path -Path $jsonTemplateBackupPath) {
        if (Test-Path -Path $jsonTemplatePath) {
            Remove-Item -Path $jsonTemplatePath
        }
        Move-Item -Path $jsonTemplateBackupPath -Destination $jsonTemplatePath
    }
}
else {
    if (-not (Test-Path -Path $jsonTemplateBackupPath)) {
        Move-Item -Path $jsonTemplatePath -Destination $jsonTemplateBackupPath
    }

    $jsonContent = Get-Content -Path $jsonTemplateBackupPath -Raw | ConvertFrom-Json
    $jsonContent.version = $version
    $jsonContent | ConvertTo-Json -Depth 32 | Set-Content -Path $jsonTemplatePath
}
