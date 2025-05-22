# Troubleshoot wrapper script
# Simply calls the script from the scripts folder

$scriptPath = Join-Path $PSScriptRoot "scripts\troubleshoot.ps1"
& $scriptPath
