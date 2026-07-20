# OPEN AI TERMINAL — PowerShell Wrapper
# Ruft den `cosmo` Launcher innerhalb von WSL auf.
#   cosmo.ps1 desktop | vps | agent | builder | monitor
param([Parameter(ValueFromRemainingArguments=$true)] $Args)
$argline = ($Args -join ' ')
wsl.exe -- bash -lic "cosmo $argline"
