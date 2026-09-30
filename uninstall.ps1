param([string]$ToolsDir = 'C:\dev\tools')

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use uninstall.sh on macOS.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')

# Leave the shared submenu, shared icon, PATH and Python packages in place.
foreach ($root in (Get-CutoutMenuRoots)) { Remove-CutoutVerb $root }
foreach ($name in @('cutout.bat', 'cutout')) {
    $path = Join-Path $ToolsDir $name
    if (Test-Path $path) { Remove-Item $path -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'cutout\icons\cutout.ico'
if (Test-Path $icon) { Remove-Item $icon -Force }
Write-Host 'Uninstalled cutout commands and Explorer actions.' -ForegroundColor Green
