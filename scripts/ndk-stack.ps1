# This script processes a tombstone file using ndk-stack to find file locations.
# It requires the Android NDK path to be set.

Param(
    [Parameter(Mandatory = $false)]
    [String] $logName = "RecentCrash.log",

    [Parameter(Mandatory = $false)]
    [Switch] $help
)

# Display help information if requested
if ($help -eq $true) {
    Write-Output "`"NDK-Stack`" - Processes a tombstone using the debug .so to find file locations"
    Write-Output "`n-- Arguments --`n"

    Write-Output "LogName `t`t The file name of the tombstone to process"

    exit
}

# Determine the NDK path
if (Test-Path "./ndkpath.txt") {
    $NDKPath = Get-Content ./ndkpath.txt
}
else {
    $NDKPath = $ENV:ANDROID_NDK_HOME
}

$stackScript = "$NDKPath/ndk-stack"
if (-not ($PSVersionTable.PSEdition -eq "Core")) {
    $stackScript += ".cmd"
}

# Process the tombstone file using ndk-stack
Get-Content $logName | & $stackScript -sym ./build/debug/ > "$($logName)_processed.log"
