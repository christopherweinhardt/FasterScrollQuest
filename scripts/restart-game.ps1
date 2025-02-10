# This script restarts the game on the connected device using adb.

Param(
    [Parameter(Mandatory=$false)]
    [String] $packageName="com.beatgames.beatsaber"
)

# Force stop the Beat Saber game
adb shell am force-stop "$packageName"

# Start the Beat Saber game
adb shell am start "$packageName/com.unity3d.player.UnityPlayerActivity"
