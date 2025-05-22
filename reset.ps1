# Reset wrapper script
# Simply calls the script from the scripts folder

$scriptPath = Join-Path $PSScriptRoot "scripts\reset.ps1"
& $scriptPath
