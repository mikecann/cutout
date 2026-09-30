# Thin stubs keep all source code in the clone, so updates need no reinstall.
function Write-BatStub {
    param([string]$ToolName, [string]$Content, [string]$ToolsDir)
    if ($Content -match '[^\x00-\x7F]') {
        throw 'The clone path must contain only ASCII characters for the Windows batch stub.'
    }
    Set-Content -Path (Join-Path $ToolsDir "$ToolName.bat") -Value $Content -Encoding ASCII
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace('__TOOL_NAME__', $ToolName)
    Set-Content -Path (Join-Path $ToolsDir $ToolName) -Value $bashContent -Encoding ASCII
}

# PNG-in-ICO preserves alpha. Both bundled icons are 16 by 16 pixels.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [IO.File]::ReadAllBytes($pngPath)
    $stream = [IO.FileStream]::new($icoPath, [IO.FileMode]::Create)
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]1)
        $writer.Write([byte]16)
        $writer.Write([byte]16)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length)
        $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey, $icon) {
    # Leave an existing submenu and its properties alone, including other tools' verbs.
    if (-not (Test-Path $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -Path $rootKey -Name MUIVerb -Value "Mike's Tools"
        Set-ItemProperty -Path $rootKey -Name SubCommands -Value ''
        Set-ItemProperty -Path $rootKey -Name Icon -Value $icon
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -Path $verbKey -Name MUIVerb -Value $label
    Set-ItemProperty -Path $verbKey -Name Icon -Value $icon
    Set-ItemProperty -Path $cmdKey -Name '(Default)' -Value $command
}

function Remove-CutoutVerb($rootKey) {
    $verbKey = "$rootKey\shell\Cutout"
    if (Test-Path $verbKey) { Remove-Item $verbKey -Recurse -Force }
}

function Get-CutoutMenuRoots {
    foreach ($ext in @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')) {
        "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    }
}
