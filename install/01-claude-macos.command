#!/bin/bash
# ============================================================
#  Claude Code + nastroje - instalace na macOS (Apple)
# ------------------------------------------------------------
#  Pro koho: pro tve Apple PC (MacBook, iMac).
#  Spustit dvojklikem na stazeny soubor, nebo prikazem v Terminalu.
#  Co to dela: nainstaluje Claude Code (terminal) + pres Homebrew
#  Claude Desktop (okenni app), VS Code a Cyberduck (nahravani na
#  server; macOS analog WinSCP), a napevno zapne RemoteControl +
#  YOLO rezim. Bezpecne poustet opakovane (idempotentni).
# ============================================================

set -uo pipefail
cd "$(dirname "$0")" 2>/dev/null || true

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Instalace Claude Code + nastroje (macOS) ==="
echo ""

export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- seed ~/.claude/settings.json -----------------------------
#  RemoteControl vzdy + YOLO napevno (bypassPermissions). Kdyz je
#  python3 (na macOS byva), pripojime klice k existujicimu souboru,
#  jinak zapiseme cely soubor.
seed_settings() {
    S="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$S" <<'PY'
import json, os, sys
p = sys.argv[1]
d = {}
if os.path.exists(p):
    try:
        with open(p) as f: d = json.load(f)
    except Exception: d = {}
d["remoteControlAtStartup"] = True
d.setdefault("permissions", {})["defaultMode"] = "bypassPermissions"
d["skipDangerousModePermissionPrompt"] = True
with open(p, "w") as f: json.dump(d, f, indent=2)
PY
    else
        cat > "$S" <<'EOF'
{
  "remoteControlAtStartup": true,
  "permissions": {
    "defaultMode": "bypassPermissions"
  },
  "skipDangerousModePermissionPrompt": true
}
EOF
    fi
    ok "RemoteControl + YOLO rezim zapnuty (plati pro vsechny sessions)."
}

pause_end() {
    echo ""
    if [ -r /dev/tty ]; then
        read -n 1 -s -r -p "Stiskni libovolnou klavesu pro zavreni..." < /dev/tty || true
        echo ""
    fi
}

# --- Homebrew (spravce aplikaci pro GUI programy) -------------
ensure_brew() {
    if command -v brew >/dev/null 2>&1; then return 0; fi
    info "Homebrew (spravce aplikaci) neni nainstalovany - instaluji..."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || warn "Homebrew se nepodarilo nainstalovat (okenni aplikace preskocim)."
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ]   && eval "$(/usr/local/bin/brew shellenv)"
    command -v brew >/dev/null 2>&1
}

# --- 1) Claude Code CLI (terminal) ----------------------------
if command -v claude >/dev/null 2>&1; then
    ok "Claude Code uz je nainstalovany (verze: $(claude --version 2>/dev/null || echo '?'))."
    info "Zkousim aktualizaci..."
    claude update 2>/dev/null && ok "Aktualizace probehla (nebo uz mas nejnovejsi)." \
        || warn "Aktualizaci nelze spustit automaticky (nevadi)."
else
    if ! command -v curl >/dev/null 2>&1; then
        err "Chybi 'curl' (na macOS byva vzdy). Neco je neobvykle - napis nam."
        pause_end; exit 1
    fi
    info "Stahuji a instaluji Claude Code (oficialni installer z claude.ai)..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
        ok "Installer dobehl."
    else
        err "Instalace selhala. Zkontroluj internet a spust skript znovu."
        pause_end; exit 1
    fi
    # PATH do budoucich oken (zsh je na macOS vychozi)
    LINE='export PATH="$HOME/.local/bin:$PATH"'
    for RC in "$HOME/.zshrc" "$HOME/.bash_profile"; do
        if ! { [ -f "$RC" ] && grep -qF '.local/bin' "$RC"; }; then
            { echo ""; echo '# Claude Code - cesta k programu'; echo "$LINE"; } >> "$RC"
            ok "Cesta k programu pridana do $RC"
        fi
    done
    export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
fi

# --- 2) Okenni aplikace pres Homebrew (best-effort) -----------
echo ""
info "Instaluji okenni aplikace (Claude Desktop, VS Code, Cyberduck)..."
if ensure_brew; then
    #  claude            = Claude Desktop (okenni app)
    #  visual-studio-code = VS Code (editor)
    #  cyberduck         = nahravani souboru na server (analog WinSCP)
    for cask in claude visual-studio-code cyberduck; do
        if brew install --cask "$cask" 2>/dev/null; then
            ok "$cask - nainstalovan / aktualni"
        else
            warn "$cask se nepodarilo nainstalovat (preskoceno, muzes pozdeji rucne)."
        fi
    done
else
    warn "Bez Homebrew okenni aplikace preskakuji - Claude Code v terminalu funguje i tak."
fi

# --- 3) Nastaveni (RemoteControl + YOLO napevno) --------------
echo ""
seed_settings

# --- 4) Overeni -----------------------------------------------
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
echo ""
echo "   Navazat na predchozi konverzaci muzes prikazem:  claude --resume"
echo "======================================="
pause_end
