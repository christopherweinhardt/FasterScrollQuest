# This script logs Beat Saber using adb logcat.
# It supports various logging options including self, all, custom patterns, and file output.

Param(
    [Parameter(Mandatory = $false)]
    [Switch] $self,

    [Parameter(Mandatory = $false)]
    [Switch] $all,

    [Parameter(Mandatory = $false)]
    [String] $custom = "",

    [Parameter(Mandatory = $false)]
    [String] $file = "",

    [Parameter(Mandatory = $false)]
    [Switch] $help,

    [Parameter(Mandatory = $false)]
    [Switch] $excludeHeader,

    [Parameter(Mandatory = $false)]
    [String] $packageId = "com.beatgames.beatsaber"
)

# Display help information if requested
if ($help -eq $true) {
    if ($excludeHeader -eq $false) {
        Write-Output "`"Start-Logging`" - Logs Beat Saber using `"adb logcat`""
        Write-Output "`n-- Arguments --`n"
    }

    Write-Output "-Self `t`t Only Logs your mod and Crashes"
    Write-Output "-All `t`t Logs everything, including logs made by the Quest itself"
    Write-Output "-Custom `t Specify a specific logging pattern, e.g `"custom-types|questui`""
    Write-Output "`t`t NOTE: The pattern `"AndroidRuntime|CRASH|scotland2|Unity`" is always appended to a custom pattern"
    Write-Output "-File `t`t Saves the output of the log to the file name given"

    exit
}

# Check if package_id.txt exists and use that as the package name
if (Test-Path "$PSScriptRoot/../package_id.txt") {
    $packageId = Get-Content "$PSScriptRoot/../package_id.txt"
    Write-Output "Using package ID from package_id.txt: $packageId"
}

# Get the process ID of Beat Saber
$bspid = adb shell pidof "$packageId"
$command = "adb logcat "

# Retry getting the process ID if not found
if ($all -eq $false) {
    $loops = 0
    while ([string]::IsNullOrEmpty($bspid) -and $loops -lt 3) {
        Start-Sleep -Milliseconds 100
        $bspid = adb shell pidof "$packageId"
        $loops += 1
    }

    # Exit if the process ID could not be found
    if ([string]::IsNullOrEmpty($bspid)) {
        Write-Output "Could not connect to adb, exiting..."
        exit 1
    }

    $command += "--pid $bspid"
}

# Build the logging pattern
if ($all -eq $false) {
    $pattern = "("
    if ($self -eq $true) {
        & $PSScriptRoot/validate-modjson.ps1
        $modID = (Get-Content "./mod.json" -Raw | ConvertFrom-Json).id
        $pattern += "$modID|"
    }
    if (![string]::IsNullOrEmpty($custom)) {
        $pattern += "$custom|"
    }
    if ($pattern -eq "(") {
        $pattern = "( INFO| DEBUG| WARN| ERROR| CRITICAL|"
    }
    $pattern += "AndroidRuntime|CRASH|scotland2|Unity  )"
    $command += " | Select-String -pattern `"$pattern`""
}

# Add file output if specified
if (![string]::IsNullOrEmpty($file)) {
    $command += " | Out-File -FilePath $PSScriptRoot\$file"
}

Write-Output "Logging using Command `"$command`""
adb logcat -c
Invoke-Expression $command
