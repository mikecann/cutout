# Install the CLI extras as well as the inference backend, using the same Python.
# Windows PowerShell turns native stderr into error records. Check exit codes
# ourselves so a failed GPU install can reach the CPU fallback.
$ErrorActionPreference = 'Continue'
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw 'Install Python and pip and add them to PATH, then rerun install.ps1.'
}
Write-Host '  [cutout] Checking dependencies...' -ForegroundColor Cyan
python -c "import rembg" 2>$null
if ($LASTEXITCODE -eq 0 -and (Get-Command rembg -ErrorAction SilentlyContinue)) {
    rembg --help *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host '    OK rembg CLI is already installed' -ForegroundColor Green
        return
    }
}
Write-Host '    Installing rembg[gpu,cli] via pip...' -ForegroundColor Yellow
python -m pip install 'rembg[gpu,cli]'
if ($LASTEXITCODE -ne 0) {
    Write-Host '    GPU install failed; trying rembg[cpu,cli]...' -ForegroundColor Yellow
    python -m pip install 'rembg[cpu,cli]'
    if ($LASTEXITCODE -ne 0) { throw 'rembg installation failed. Check Python and pip.' }
}
if (-not (Get-Command rembg -ErrorAction SilentlyContinue)) {
    throw 'rembg was installed, but its command is not on PATH. Add your Python Scripts folder and rerun.'
}
rembg --help *> $null
if ($LASTEXITCODE -ne 0) { throw 'rembg CLI could not start. Check its dependencies.' }
Write-Host '    OK rembg CLI installed' -ForegroundColor Green
