# This script compiles the mod into a .so or .a library.
# It supports clean builds and skipping the build process.

Param(
    [Parameter(Mandatory = $false)]
    [Switch] $clean,

    [Parameter(Mandatory = $false)]
    [Switch] $skipBuild,

    [Parameter(Mandatory = $false)]
    [Switch] $help
)

# Display help information if requested
if ($help -eq $true) {
    Write-Output "`"Build`" - Copiles your mod into a `".so`" or a `".a`" library"
    Write-Output "`n-- Arguments --`n"

    Write-Output "-Clean `t`t Deletes the `"build`" folder, so that the entire library is rebuilt"
    Write-Output "-SkipBuild `t`t Skips build, combine this with -Clean"

    exit
}

# Check if qpm.shared.json exists, otherwise fallback to qpm.json
$sharedQpmFilePath = "qpm.shared.json"
$defaultQpmFilePath = "qpm.json"

if (Test-Path $sharedQpmFilePath) {
    $qpmJson = (Get-Content $sharedQpmFilePath | ConvertFrom-Json).config
}
elseif (Test-Path $defaultQpmFilePath) {
    $qpmJson = Get-Content $defaultQpmFilePath | ConvertFrom-Json
}
else {
    Write-Error "Neither qpm.shared.json nor qpm.json exists."
    exit 1
}

# Restore dependencies if the directory isn't present
if (-not $skipBuild.IsPresent -and (-not (Test-Path -Path $qpmJson.dependenciesDir))) {
    & qpm restore
}

# Perform a clean build if requested
if ($clean.IsPresent) {
    if (Test-Path -Path "build") {
        remove-item build -R -Force
    }

    if (Test-Path $qpmJson.workspace.qmodOutput) {
        Remove-Item $qpmJson.workspace.qmodOutput -Force
    }
}

# Exit if skipping the build
if ($skipBuild.IsPresent) {
    exit 0
}

# Check if ./extern/includes/bs-cordl/version.txt exists
if (Test-Path "$PSScriptRoot/../extern/includes/bs-cordl/include/version.txt") {
    # Update packageVersion in mod.template.json using bs-cordl version.txt
    $modTemplateRaw = Get-Content "$PSScriptRoot/../mod.template.json" -Raw
    $modTemplateOriginal = $modTemplateRaw | ConvertFrom-Json
    $modTemplate = $modTemplateRaw | ConvertFrom-Json
    $bsversion = Get-Content "$PSScriptRoot/../extern/includes/bs-cordl/include/version.txt"
    if (-not [string]::IsNullOrWhitespace($bsversion)) {
        Write-Output "Setting Package Version to $bsversion"
        $modTemplate.packageVersion = $bsversion

        # Write the updated mod.template.json if the contents have changed
        if (($modTemplate | ConvertTo-Json -Depth 32) -ne ($modTemplateOriginal | ConvertTo-Json -Depth 32)) {
            Write-Output "Writing updated mod.template.json"
            $modTemplate | ConvertTo-Json -Depth 32 | Set-Content -Path "$PSScriptRoot/../mod.template.json"
        }
    }
    else {
        Write-Output "Empty bs-cordl version.txt, skipping package version update."
    }
}
else {
    Write-Output "Missing bs-cordl version.txt, skipping package version update."
}

# Create the build directory if it doesn't exist
if (-not (Test-Path -Path "build")) {
    new-item -Path build -ItemType Directory
}

# Run cmake to build the mod
& cmake -G "Ninja" -DCMAKE_BUILD_TYPE="RelWithDebInfo" -B build
& cmake --build ./build
exit $LASTEXITCODE
