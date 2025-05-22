# Build and run wrapper script
# This script is kept in the root directory for backward compatibility
# It calls the main script in the scripts folder

# Get the current script directory
$scriptDirectory = $PSScriptRoot

# Run the original script here directly since it relies on relative paths
# and is more complex than the other scripts
. "$scriptDirectory\build-and-run.ps1"
