param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools'
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use install.sh on macOS.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')

if (-not $SkipDeps) { & (Join-Path $PSScriptRoot 'deps.ps1') }
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
Write-BatStub -ToolName cutout -ToolsDir $ToolsDir -Content @"
@echo off
call "$PSScriptRoot\cutout.bat" %*
"@

$iconsOut = Join-Path $env:LOCALAPPDATA 'cutout\icons'
$sharedIcons = Join-Path $env:LOCALAPPDATA 'MikesTools\icons'
New-Item -ItemType Directory -Path $iconsOut, $sharedIcons -Force | Out-Null
$pictureIco = Join-Path $iconsOut 'cutout.ico'
$wrenchIco = Join-Path $sharedIcons 'mikes-tools.ico'
ConvertTo-Ico (Join-Path $PSScriptRoot 'icons\picture.png') $pictureIco
if (-not (Test-Path $wrenchIco)) {
    ConvertTo-Ico (Join-Path $PSScriptRoot 'icons\wrench.png') $wrenchIco
}
$command = 'cmd.exe /k ""{0}" "%1""' -f (Join-Path $ToolsDir 'cutout.bat')
foreach ($root in (Get-CutoutMenuRoots)) {
    Set-MikesToolsRoot $root $wrenchIco
    Add-MikesVerb $root Cutout 'Cutout (Remove Background)' $pictureIco $command
}

$userPath = [string][Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$onPath = (@($userPath -split ';') + @($machinePath -split ';')) |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) {
    $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        $newPath = ($userPath.TrimEnd(';') + ";$ToolsDir").TrimStart(';')
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    }
}
Write-Host 'Installed cutout. Open a new terminal to use the command.' -ForegroundColor Green
