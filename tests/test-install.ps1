$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'install-lib.ps1')

function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('cutout tests ' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $content = "@echo off`r`ncall `"C:\repo with spaces\cutout.bat`" %*"
    Write-BatStub -ToolName cutout -Content $content -ToolsDir $temp
    Assert ((Get-Content (Join-Path $temp 'cutout.bat') -Raw).Contains($content)) 'Stub changed the forwarding command'
    $bytes = [IO.File]::ReadAllBytes((Join-Path $temp 'cutout.bat'))
    Assert (@($bytes | Where-Object { $_ -gt 127 }).Count -eq 0) 'Stub must be ASCII'
    Assert ((Get-Content (Join-Path $temp 'cutout') -Raw).Contains('exec "$SCRIPT_DIR/cutout.bat" "$@"')) 'Git Bash arguments must be forwarded'

    $ico = Join-Path $temp 'cutout.ico'
    $png = Join-Path (Split-Path -Parent $PSScriptRoot) 'icons/picture.png'
    ConvertTo-Ico $png $ico
    $converted = [IO.File]::ReadAllBytes($ico)
    Assert ([BitConverter]::ToUInt16($converted, 2) -eq 1) 'Expected an ICO file'
    Assert ([BitConverter]::ToUInt32($converted, 18) -eq 22) 'Expected PNG data at offset 22'
    Assert ([BitConverter]::ToUInt32($converted, 14) -eq ([IO.FileInfo]$png).Length) 'ICO data length mismatch'

    if ($env:OS -eq 'Windows_NT') {
        # Use an isolated registry key, never the real Explorer menu.
        $root = 'HKCU:\Software\CutoutTests\' + [guid]::NewGuid()
        try {
            Set-MikesToolsRoot $root 'shared.ico'
            Add-MikesVerb $root Other 'Other tool' 'other.ico' 'other.exe'
            Set-MikesToolsRoot $root 'replacement.ico'
            Add-MikesVerb $root Cutout 'Cutout' $ico 'cutout command'
            Add-MikesVerb $root Cutout 'Cutout' $ico 'updated command'
            Assert ((Get-ItemProperty $root).Icon -eq 'shared.ico') 'Shared menu icon was overwritten'
            Assert (Test-Path "$root\shell\Other") 'Another verb was deleted on install'
            Assert ((Get-ItemProperty "$root\shell\Cutout\command").'(Default)' -eq 'updated command') 'Reinstall did not update the command'
            Remove-CutoutVerb $root
            Remove-CutoutVerb $root
            Assert (-not (Test-Path "$root\shell\Cutout")) 'Cutout verb was not removed'
            Assert (Test-Path "$root\shell\Other") 'Another verb was deleted on uninstall'
        } finally {
            if (Test-Path $root) { Remove-Item $root -Recurse -Force }
        }
    } else {
        Write-Host 'SKIP: Windows registry integration requires Windows.'
    }
    Write-Host 'PASS: installer helper tests'
} finally {
    Remove-Item $temp -Recurse -Force
}
