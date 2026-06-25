#!/bin/bash
# ============================================================
#  Claude Code - instalace na macOS (Apple)
# ------------------------------------------------------------
#  Pro koho: pro tve Apple PC (MacBook, iMac).
#  Jak spustit: dvojklik na tento soubor. Kdyby to slo otevrit
#  v textovem editoru misto spusteni, viz navod v README.
#  Bezpecne poustet opakovane (idempotentni).
# ============================================================

set -uo pipefail

# Aby dvojklik fungoval i kdyz je soubor jinde - prejdi do sve slozky.
cd "$(dirname "$0")" 2>/dev/null || true

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Instalace Claude Code (macOS) ==="
echo ""

# Kde hleda program po instalaci.
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- 1) Uz nainstalovano? (idempotence) -----------------------
if command -v claude >/dev/null 2>&1; then
    VER="$(claude --version 2>/dev/null || echo '?')"
    ok "Claude Code uz je nainstalovany (verze: ${VER})."
    info "Aktualizaci si Claude resi sam. Pokud chces rucne: claude update"
    echo ""
    info "Spustis ho prikazem:  claude"
    echo ""
    read -n 1 -s -r -p "Stiskni libovolnou klavesu pro zavreni..."
    echo ""
    exit 0
fi

# --- 2) curl je na macOS soucasti systemu ---------------------
if ! command -v curl >/dev/null 2>&1; then
    err "Chybi 'curl' (na macOS byva vzdy). Neco je neobvykle - napis nam."
    exit 1
fi

# --- 3) Vlastni instalace -------------------------------------
info "Stahuji a instaluji Claude Code (oficialni installer z claude.ai)..."
if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "Installer dobehl."
else
    err "Instalace selhala. Zkontroluj pripojeni k internetu a spust skript znovu."
    read -n 1 -s -r -p "Stiskni libovolnou klavesu pro zavreni..."
    exit 1
fi

# --- 4) PATH do budoucich oken (idempotentne) -----------------
# macOS pouziva vychozi shell zsh -> ~/.zshrc.
LINE='export PATH="$HOME/.local/bin:$PATH"'
for RC in "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [ -f "$RC" ] && grep -qF '.local/bin' "$RC"; then
        : # uz tam je
    else
        echo "" >> "$RC"
        echo '# Claude Code - cesta k programu' >> "$RC"
        echo "$LINE" >> "$RC"
        ok "Cesta k programu pridana do $RC"
    fi
done
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- 5) Overeni -----------------------------------------------
echo ""
if command -v claude >/dev/null 2>&1; then
    ok "Hotovo. Verze: $(claude --version 2>/dev/null || echo '?')"
else
    warn "Program 'claude' zatim neni videt v tomto okne."
    warn "Zavri Terminal, otevri NOVY a zkus napsat:  claude"
fi

echo ""
info "================ CO DAL ================"
echo "1) Zavri toto okno Terminalu a otevri NOVE."
echo "   (Terminal najdes: Spotlight - lupa vpravo nahore - napis 'Terminal'.)"
echo "2) Napis:  claude"
echo "3) Pri prvnim spusteni se vypise webova adresa (URL)."
echo "   Zkopiruj ji do prohlizece, prihlas se a potvrd."
echo "   Pak uz si muzes s Claude psat primo v Terminalu."
echo "======================================="
echo ""
read -n 1 -s -r -p "Stiskni libovolnou klavesu pro zavreni..."
echo ""
