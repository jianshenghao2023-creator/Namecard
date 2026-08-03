param(
    [string]$Python = "",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$Venv = Join-Path $Base ".venv_tk"
$Exe = Join-Path $Venv "Scripts\python.exe"

function Test-PythonTk {
    param([string]$Candidate)
    if (-not $Candidate) { return $null }
    $TkCheck = @'
import tkinter
print(tkinter.TkVersion)
'@
    $result = $TkCheck | & $Candidate - 2>$null
    if ($LASTEXITCODE -eq 0) {
        return [pscustomobject]@{ Path = $Candidate; Tk = $result }
    }
    return $null
}

$Candidates = @()
if ($Python) { $Candidates += $Python }
$Candidates += "C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
$Candidates += "python"

$Selected = $null
foreach ($candidate in $Candidates) {
    $Selected = Test-PythonTk -Candidate $candidate
    if ($Selected) { break }
}

if (-not $Selected) {
    throw "No Python with tkinter/Tcl-Tk was found. Install official Python for Windows with Tcl/Tk, or pass -Python <path>."
}

$Python = $Selected.Path
$TkResult = $Selected.Tk
Write-Host "Using Python with Tcl/Tk: $TkResult"

if ($Clean -and (Test-Path -LiteralPath $Venv)) {
    Remove-Item -LiteralPath $Venv -Recurse -Force
}

if (!(Test-Path -LiteralPath $Exe -PathType Leaf)) {
    & $Python -m venv $Venv
}

& $Exe -m pip install --upgrade pip
& $Exe -m pip install -r (Join-Path $Base "requirements.txt")

Push-Location $Base
try {
    & $Exe -m PyInstaller `
        --noconfirm `
        --clean `
        --onefile `
        --windowed `
        --name NamecardUpdater `
        namecard_updater.py
}
finally {
    Pop-Location
}

Write-Host "Built: $(Join-Path $Base 'dist\NamecardUpdater.exe')"
