# ============================================================
#  Claude Code - instalace na Windows (PowerShell)
# ------------------------------------------------------------
#  Tento skript je urceny ke spusteni primo z internetu
#  (vzdy se tak vezme nejnovejsi verze z gitu):
#
#    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-windows.ps1 | iex"
#
#  Vlastnosti:
#    - nezavisly na ostatnich skriptech a na poradi,
#    - bezpecne poustet opakovane (idempotentni),
#    - kdyz uz je Claude nainstalovany, zkusi ho aktualizovat.
# ============================================================

$ErrorActionPreference = 'Continue'

function Test-Cmd($name) {
    return ($null -ne (Get-Command $name -ErrorAction SilentlyContinue))
}
function Update-PathInSession {
    $machine = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path','User')
    $local   = Join-Path $env:USERPROFILE '.local\bin'
    $env:Path = "$machine;$user;$local"
}

function Enable-Yolo {
    $p = Join-Path $env:USERPROFILE '.claude\settings.json'
    $d = Split-Path $p
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    $j = if (Test-Path $p) {
        $c = Get-Content $p -Raw
        if ($c) { $c | ConvertFrom-Json } else { [PSCustomObject]@{} }
    } else { [PSCustomObject]@{} }
    if (-not $j.permissions) { $j | Add-Member -NotePropertyName permissions -NotePropertyValue ([PSCustomObject]@{}) -Force }
    $j.permissions | Add-Member -NotePropertyName defaultMode -NotePropertyValue 'bypassPermissions' -Force
    $j | Add-Member -NotePropertyName skipDangerousModePermissionPrompt -NotePropertyValue $true -Force
    $j | ConvertTo-Json -Depth 10 | Set-Content $p -Encoding UTF8
    Write-Host "[OK] YOLO rezim zapnut (plati pro vsechny sessions)." -ForegroundColor Green
}

function Ask-Yolo {
    Write-Host ""
    Write-Host "Chces zapnout YOLO rezim?" -ForegroundColor Cyan
    Write-Host "  YOLO = Claude se nepta na svoleni pro kazdou drobnost (rychlejsi"
    Write-Host "  prace). Plati pro vsechny sessions. Doporuceno pro zacatek."
    $ans = Read-Host "  Zapnout YOLO? [Y/n]"
    if ($ans -match '^[Nn]') {
        Write-Host "YOLO rezim NEzapnuty (Claude se bude ptat na svoleni)."
    } else {
        Enable-Yolo
    }
}

Write-Host ""
Write-Host "=== Instalace Claude Code (Windows) ===" -ForegroundColor Cyan
Write-Host ""

Update-PathInSession

if (Test-Cmd 'claude') {
    Write-Host "[OK] Claude Code uz je nainstalovany." -ForegroundColor Green
    Write-Host "Zkousim aktualizaci..."
    try { claude update } catch { Write-Host "[POZOR] Aktualizaci nelze spustit automaticky (nevadi, Claude se umi updatovat i sam)." -ForegroundColor Yellow }
    Ask-Yolo
    Write-Host ""
    Write-Host "Spustis ho prikazem:  claude"
}
else {
    $done = $false

    # --- Pokus c.1: winget (moderni Windows 10/11) ---
    if (Test-Cmd 'winget') {
        Write-Host "Zkousim instalaci pres winget..."
        try {
            winget install --id Anthropic.ClaudeCode --accept-source-agreements --accept-package-agreements -h
        } catch { }
        Update-PathInSession
        if (Test-Cmd 'claude') { $done = $true }
    }

    # --- Pokus c.2: oficialni installer (funguje i bez wingetu, i na starsich Windows) ---
    if (-not $done) {
        Write-Host "Zkousim oficialni installer z claude.ai..."
        try {
            Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
        } catch {
            Write-Host "[CHYBA] Oficialni installer se nepodarilo spustit." -ForegroundColor Red
        }
        Update-PathInSession
        if (Test-Cmd 'claude') { $done = $true }
    }

    Write-Host ""
    if ($done) {
        Write-Host "[OK] Hotovo - Claude Code je nainstalovany." -ForegroundColor Green
        Ask-Yolo
    } else {
        Write-Host "[POZOR] Instalaci se nepodarilo dokoncit automaticky." -ForegroundColor Yellow
        Write-Host "  - Zkontroluj pripojeni k internetu."
        Write-Host "  - Spust prikaz znovu."
    }
}

Write-Host ""
Write-Host "================ CO DAL ================" -ForegroundColor Cyan
Write-Host "1) Zavri toto okno a otevri NOVE."
Write-Host "   (Stiskni klavesu Windows, napis  cmd  a potvrd Enter.)"
Write-Host "2) Napis:  claude"
Write-Host "3) Pri prvnim spusteni se vypise webova adresa (URL)."
Write-Host "   Zkopiruj ji do prohlizece, prihlas se a potvrd."
Write-Host "   Pak uz si muzes s Claude psat primo v okne."
Write-Host "======================================="
Write-Host ""
