#!/usr/bin/env bash
# ============================================================
#  Krok 02 - Pripojeni Claude k tvemu Teams (Linux / Mac)
# ------------------------------------------------------------
#  Co to udela:
#   1) Pokud jeste nejsi prihlaseny, prihlasi te do Teams
#      (zkopirujes kod do prohlizece a prihlasis se svym
#       uctem tvuj-email@bidli.cz).
#   2) Spusti "most": v Teams ti vznikne skupinovy chat
#      "Claude" (jen ty v nem). Co tam napises, Claude
#      precte a odpovi ti primo do chatu.
#
#  Predpoklad: nainstalovany Claude Code (viz krok 01) a Python 3.
#  Bezpecne poustet opakovane (idempotentni).
# ============================================================

set -uo pipefail
cd "$(dirname "$0")" 2>/dev/null || true

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

# --- Python 3 ---
PY=""
command -v python3 >/dev/null 2>&1 && PY=python3
[ -z "$PY" ] && command -v python >/dev/null 2>&1 && PY=python
if [ -z "$PY" ]; then
    err "Neni nainstalovany Python 3. Nainstaluj ho a spust skript znovu."
    exit 1
fi

# --- Claude Code ---
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
    warn "Nenasel jsem program 'claude'. Nejdriv projdi krok 01 (instalace Claude Code)."
    warn "Pokracuji dal - prihlaseni do Teams pujde, ale odpovidat bude az s Claude."
fi

# --- 1) Prihlaseni, pokud chybi ---
if [ ! -f "tokens.json" ]; then
    info "Jeste nejsi prihlaseny do Teams. Spustim prihlaseni..."
    "$PY" claude_teams.py login || exit 1
else
    info "Uz jsi prihlaseny do Teams (pouzivam ulozene prihlaseni)."
fi

# --- 2) Spusteni mostu ---
echo ""
info "Spoustim spojeni Teams <-> Claude. Nech toto okno otevrene."
echo ""
exec "$PY" claude_teams.py run
