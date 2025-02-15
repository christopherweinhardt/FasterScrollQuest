# This script pulls the most recent tombstone file from the Quest device.
# Optionally, it can analyze the tombstone using ndk-stack.

Param(
    [Parameter(Mandatory = $false)]
    [String] $fileName = "RecentCrash.log",

    [Parameter(Mandatory = $false)]
    [Switch] $analyze,

    [Parameter(Mandatory = $false)]
    [Switch] $help,

    [Parameter(Mandatory = $false)]
    [String] $packageId = "com.beatgames.beatsaber"
)

# Display help information if requested
if ($help -eq $true) {
    Write-Output "`"Pull-Tombstone`" - Finds and pulls the most recent tombstone from your quest, optionally analyzing it with ndk-stack"
    Write-Output "`n-- Arguments --`n"

    Write-Output "-FileName `t The name for the output file, defaulting to RecentCrash.log"
    Write-Output "-Analyze `t Runs ndk-stack on the file after pulling"

    exit
}

# Check if package_id.txt exists and use that as the package name
if (Test-Path "$PSScriptRoot/../package_id.txt") {
    $packageId = Get-Content "$PSScriptRoot/../package_id.txt"
    Write-Output "Using package ID from package_id.txt: $packageId"
}

$global:currentDate = get-date
$global:recentDate = $Null
$global:recentTombstone = $Null

# Loop through possible tombstone files to find the most recent one
for ($i = 0; $i -lt 3; $i++) {
    $stats = & adb shell stat "/sdcard/Android/data/$packageId/files/tombstone_0$i"
    $date = (Select-String -Input $stats -Pattern "(?<=Modify: )\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?=.\d{9})").Matches.Value
    if ([string]::IsNullOrEmpty($date)) {
        Write-Output "Failed to pull tombstone, exiting..."
        exit 1;
    }
    $dateObj = [datetime]::ParseExact($date, "yyyy-MM-dd HH:mm:ss", $Null)
    $difference = [math]::Round(($currentDate - $dateObj).TotalMinutes)
    if ($difference -eq 1) {
        Write-Output "Found tombstone_0$i $difference minute ago"
    }
    else {
        Write-Output "Found tombstone_0$i $difference minutes ago"
    }
    if (-not $recentDate -or $recentDate -lt $dateObj) {
        $recentDate = $dateObj
        $recentTombstone = $i
    }
}

Write-Output "Latest tombstone was tombstone_0$recentTombstone"

# Pull the most recent tombstone file
& adb pull "/sdcard/Android/data/$packageId/files/tombstone_0$recentTombstone" "$fileName"

# Analyze the tombstone file if requested
if ($analyze) {
    & "$PSScriptRoot/ndk-stack.ps1" "-logName:$fileName"
}
