# This script validates the mod.json file against a schema.
# It updates mod.json if mod.template.json or qpm.shared.json are newer.
# If PowerShell version is 6 or higher, it validates mod.json using a schema.

$mod = "./mod.json"
$modTemplate = "./mod.template.json"
$qpmShared = "./qpm.shared.json"

# Check if mod.template.json exists
if (Test-Path -Path $modTemplate) {
    # Determine if mod.json needs to be updated
    $update = -not (Test-Path -Path $mod)

    if (-not $update) {
        $update = (Get-Item $modTemplate).LastWriteTime -gt (Get-Item $mod).LastWriteTime
    }

    if (-not $update -and (Test-Path -Path $qpmShared)) {
        $update = (Get-Item $qpmShared).LastWriteTime -gt (Get-Item $mod).LastWriteTime
    }

    # Update mod.json if necessary
    if ($update) {
        & qpm qmod manifest
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
}
# Error if neither mod.json nor mod.template.json exist
elseif (-not (Test-Path -Path $mod)) {
    Write-Output "Error: mod.json and mod.template.json were not present"
    exit 1
}

Write-Output "Creating qmod from mod.json"

# Validate mod.json if PowerShell version is 6 or higher
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -ge 6) {
    # Download the schema
    $schemaUrl = "https://raw.githubusercontent.com/Lauriethefish/QuestPatcher.QMod/main/QuestPatcher.QMod/Resources/qmod.schema.json"
    $modSchemaRaw = (Invoke-WebRequest $schemaUrl).Content

    # Read mod.json
    $modJsonRaw = Get-Content $mod -Raw

    # Validate mod.json
    Write-Output "Validating mod.json..."
    if (-not ($modJsonRaw | Test-Json -Schema $modSchemaRaw)) {
        Write-Output "Error: mod.json is not valid"
        exit 1
    }
}
else {
    Write-Output "Could not validate mod.json with schema: powershell version was too low (< 6)"
}
exit
