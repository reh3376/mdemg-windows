#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    MDEMG PowerShell wrapper — thin shim that calls mdemg.exe
.DESCRIPTION
    Locates mdemg.exe (same directory, or PATH) and forwards all arguments.
    Provides helpful error messages if the binary is not found.
#>
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

# Locate mdemg.exe — check same directory first, then PATH
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$candidates = @(
    (Join-Path $scriptDir "mdemg.exe"),
    (Join-Path $scriptDir ".." "mdemg.exe")
)

$binary = $null
foreach ($c in $candidates) {
    if (Test-Path $c) {
        $binary = (Resolve-Path $c).Path
        break
    }
}

if (-not $binary) {
    $inPath = Get-Command mdemg.exe -ErrorAction SilentlyContinue
    if ($inPath) {
        $binary = $inPath.Source
    }
}

if (-not $binary) {
    Write-Host "Error: mdemg.exe not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install the native binary:" -ForegroundColor Yellow
    Write-Host "  mdemg upgrade" -ForegroundColor White
    Write-Host ""
    Write-Host "Or download manually from:" -ForegroundColor Yellow
    Write-Host "  https://github.com/reh3376/mdemg/releases" -ForegroundColor White
    Write-Host ""
    Write-Host "Expected locations:" -ForegroundColor Gray
    foreach ($c in $candidates) { Write-Host "  $c" -ForegroundColor Gray }
    exit 1
}

# Forward all arguments to mdemg.exe
& $binary @Arguments
exit $LASTEXITCODE
