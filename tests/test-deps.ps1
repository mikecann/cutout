# Fake Python and rembg to exercise dependency setup without network or models.
$ErrorActionPreference = 'Stop'
$deps = Join-Path (Split-Path -Parent $PSScriptRoot) 'deps.ps1'
$cutoutDepsTestState = @{ Calls = @(); Ready = $false; GpuFails = $false; CpuFails = $false }
function python {
    if ($args[0] -eq '-c') {
        $global:LASTEXITCODE = $(if ($cutoutDepsTestState.Ready) { 0 } else { 1 })
        return
    }
    $cutoutDepsTestState.Calls += $args[-1]
    $fail = ($args[-1] -eq 'rembg[gpu,cli]' -and $cutoutDepsTestState.GpuFails) -or
            ($args[-1] -eq 'rembg[cpu,cli]' -and $cutoutDepsTestState.CpuFails)
    $global:LASTEXITCODE = $(if ($fail) { 1 } else { 0 })
    if (-not $fail) { $cutoutDepsTestState.Ready = $true }
}
function rembg {
    $global:LASTEXITCODE = $(if ($cutoutDepsTestState.Ready) { 0 } else { 1 })
}
function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}

$cutoutDepsTestState.Ready = $true
& $deps
Assert ($cutoutDepsTestState.Calls.Count -eq 0) 'Reinstall should not install working dependencies'

$cutoutDepsTestState.Ready = $false
& $deps
Assert ($cutoutDepsTestState.Calls.Count -eq 1 -and $cutoutDepsTestState.Calls[0] -eq 'rembg[gpu,cli]') 'Fresh install must include CLI extras'

$cutoutDepsTestState.Calls = @()
$cutoutDepsTestState.Ready = $false
$cutoutDepsTestState.GpuFails = $true
& $deps
Assert (($cutoutDepsTestState.Calls -join ',') -eq 'rembg[gpu,cli],rembg[cpu,cli]') 'Expected CPU fallback'

$cutoutDepsTestState.Ready = $false
$cutoutDepsTestState.CpuFails = $true
$failed = $false
try { & $deps } catch { $failed = $true }
Assert $failed 'Both dependency installs failing must stop the installer'
Write-Host 'PASS: dependency setup tests'
