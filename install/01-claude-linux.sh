#!/usr/bin/env bash
# ============================================================
#  Claude Code - instalace na Linux (Ubuntu / Debian a podobne)
# ------------------------------------------------------------
#  Pro koho: pro hosting / server kde bezi Linux.
#  Co to udela: nainstaluje program "claude" (Claude Code).
#  Bezpecne poustet opakovane - kdyz uz je nainstalovano,
#  skript to pozna a jen to oznami (idempotentni).
# ============================================================

# Zamerne BEZ `set -e` u celku - chceme prubezne hlasky i kdyz
# nejaky dilci krok selze. Chyby resime rucne.
set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Instalace Claude Code (Linux) ==="
echo ""

# --- 0) Kde hledat program po instalaci -----------------------
# Installer obvykle uklada do ~/.local/bin. Pridame to do PATH
# pro tento bezici skript, abychom umeli overit verzi hned.
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- 1) Uz nainstalovano? (idempotence) -----------------------
if command -v claude >/dev/null 2>&1; then
    VER="$(claude --version 2>/dev/null || echo '?')"
    ok "Claude Code uz je nainstalovany (verze: ${VER})."
    info "Aktualizaci si Claude resi sam. Pokud chces rucne: claude update"
    echo ""
    info "Spustis ho prikazem:  claude"
    exit 0
fi

# --- 2) Zajisti curl ------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
    warn "Chybi 'curl', zkousim doinstalovat..."
    if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update -qq && sudo apt-get install -y -qq curl
    elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y curl
    elif command -v yum     >/dev/null 2>&1; then sudo yum install -y curl
    elif command -v pacman  >/dev/null 2>&1; then sudo pacman -Sy --noconfirm curl
    elif command -v zypper  >/dev/null 2>&1; then sudo zypper install -y curl
    else
        err "Nevim jak nainstalovat curl na tomto systemu. Nainstaluj ho rucne a spust skript znovu."
        exit 1
    fi
fi
command -v curl >/dev/null 2>&1 && ok "curl je k dispozici."

# --- 3) Vlastni instalace Claude Code -------------------------
info "Stahuji a instaluji Claude Code (oficialni installer z claude.ai)..."
if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "Installer dobehl."
else
    err "Instalace selhala. Zkontroluj pripojeni k internetu a spust skript znovu."
    exit 1
fi

# --- 4) PATH do budoucich oken (idempotentne) -----------------
# Aby prikaz 'claude' fungoval i po otevreni noveho terminalu.
LINE='export PATH="$HOME/.local/bin:$PATH"'
RC="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && RC="$HOME/.zshrc"
if [ -f "$RC" ] && grep -qF '.local/bin' "$RC"; then
    : # uz tam je, nepridavame podruhe
else
    echo "" >> "$RC"
    echo '# Claude Code - cesta k programu' >> "$RC"
    echo "$LINE" >> "$RC"
    ok "Cesta k programu pridana do $RC"
fi
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- 5) Overeni -----------------------------------------------
echo ""
if command -v claude >/dev/null 2>&1; then
    ok "Hotovo. Verze: $(claude --version 2>/dev/null || echo '?')"
else
    warn "Program 'claude' zatim neni videt v tomto okne."
    warn "Zavri tento terminal, otevri NOVY a zkus napsat:  claude"
fi

echo ""
info "================ CO DAL ================"
echo "1) Zavri tento terminal a otevri NOVY (aby se nacetla cesta k programu)."
echo "2) Napis:  claude"
echo "3) Pri prvnim spusteni se vypise webova adresa (URL)."
echo "   Zkopiruj ji do prohlizece, prihlas se a potvrd."
echo "   Pak uz si muzes s Claude psat primo v terminalu."
echo "======================================="
echo ""
