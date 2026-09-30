$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$failed = $false
foreach ($file in (Get-ChildItem -Path $repo -Filter '*.ps1' -Recurse -File)) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -gt 0) {
        $failed = $true
        Write-Host $file.FullName
        $parseErrors | ForEach-Object { Write-Host $_ }
    }
}
if ($failed) { throw 'PowerShell parse checks failed.' }
Write-Host 'PASS: parsed every PowerShell script'
