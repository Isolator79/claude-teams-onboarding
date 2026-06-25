# ============================================================
#  Krok 02 - napojeni Claude na Microsoft Teams (Windows)
# ------------------------------------------------------------
#  Spousti se primo z internetu (vzdy nejnovejsi verze z gitu):
#
#    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/teams/02-teams.ps1 | iex"
#
#  Co to udela:
#    - doinstaluje git a Python, pokud chybi (pres winget),
#    - stahne/zaktualizuje balik do %USERPROFILE%\claude-teams-onboarding,
#    - pri prvnim behu te prihlasi do Teams (@bidli.cz),
#    - spusti most: pises Claudovi v Teams, Claude odpovida.
#  Nezavisle na ostatnich skriptech, bezpecne poustet opakovane.
#
#  POZOR - dva ruzne ucty:
#    1) Claude ucet (krok 01) - libovolny, klidne Gmail.
#    2) Teams / Microsoft 365 ucet - VZDY tvuj firemni @bidli.cz.
# ============================================================

$ErrorActionPreference = 'Continue'

$RepoUrl = 'https://github.com/Isolator79/claude-teams-onboarding.git'
$Dest    = Join-Path $env:USERPROFILE 'claude-teams-onboarding'

function Test-Cmd($name) { return ($null -ne (Get-Command $name -ErrorAction SilentlyContinue)) }
function Get-Py {
    if (Test-Cmd 'python') { return 'python' }
    if (Test-Cmd 'py')     { return 'py' }
    return $null
}

Write-Host ""
Write-Host "=== Krok 02: napojeni Claude na Teams ===" -ForegroundColor Cyan
Write-Host ""

# --- zajisti git ---
if (-not (Test-Cmd 'git')) {
    if (Test-Cmd 'winget') {
        Write-Host "Doinstalovavam git..."
        winget install --id Git.Git --accept-source-agreements --accept-package-agreements -h
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
    }
}
if (-not (Test-Cmd 'git')) {
    Write-Host "[CHYBA] Nenasel jsem 'git'. Nainstaluj ho z https://git-scm.com a spust prikaz znovu." -ForegroundColor Red
    return
}

# --- zajisti Python ---
if (-not (Get-Py)) {
    if (Test-Cmd 'winget') {
        Write-Host "Doinstalovavam Python..."
        winget install --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements -h
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
    }
}
$Py = Get-Py
if (-not $Py) {
    Write-Host "[CHYBA] Nenasel jsem Python. Nainstaluj ho z https://python.org (zaskrtni 'Add Python to PATH') a spust znovu." -ForegroundColor Red
    return
}
Write-Host "[OK] git i Python jsou k dispozici." -ForegroundColor Green

# --- stahni / aktualizuj balik (idempotentne) ---
if (Test-Path (Join-Path $Dest '.git')) {
    Write-Host "Balik uz mam, aktualizuji na nejnovejsi verzi (git pull)..."
    git -C $Dest pull --ff-only
} else {
    Write-Host "Stahuji balik do: $Dest"
    git clone --depth 1 $RepoUrl $Dest
}

$Core = Join-Path $Dest 'teams\claude_teams.py'
if (-not (Test-Path $Core)) {
    Write-Host "[CHYBA] Chybi soubor $Core - neco se nestahlo spravne." -ForegroundColor Red
    return
}
Write-Host "[OK] Balik pripraveny v: $Dest" -ForegroundColor Green

# --- upozorneni kdyz chybi Claude (krok 01) ---
if (-not (Test-Cmd 'claude')) {
    Write-Host "[POZOR] Nenasel jsem program 'claude' (Claude Code)." -ForegroundColor Yellow
    Write-Host "        Most pobezi, ale dokud Claude nenainstalujes (KROK 01), nebude umet odpovidat." -ForegroundColor Yellow
    Write-Host ""
}

# --- prvni prihlaseni do Teams ---
$Tokens = Join-Path $Dest 'teams\tokens.json'
if (-not (Test-Path $Tokens)) {
    Write-Host "Jeste nejsi prihlaseny do Teams - spoustim prihlaseni..."
    Write-Host "(Zkopiruj vypsanou webovou adresu do prohlizece a prihlas se svym @bidli.cz uctem.)"
    Write-Host ""
    & $Py $Core login
    if (-not (Test-Path $Tokens)) {
        Write-Host "[CHYBA] Prihlaseni se nezdarilo. Spust prikaz znovu." -ForegroundColor Red
        return
    }
}

# --- spust most ---
Write-Host ""
Write-Host "Spoustim most Teams <-> Claude. Pis si s Claude v Teams (chat 'Claude')." -ForegroundColor Cyan
Write-Host "Most ukoncis stiskem Ctrl+C." -ForegroundColor Cyan
Write-Host ""
& $Py $Core run
