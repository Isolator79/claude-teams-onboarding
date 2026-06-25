#!/bin/bash
# ============================================================
#  Claude Code - instalace na macOS (Apple)
# ------------------------------------------------------------
#  Pro koho: pro tve Apple PC (MacBook, iMac).
#  Spustit ho muzes dvojklikem na stazeny soubor, nebo prikazem
#  v Terminalu (viz README). Bezpecne poustet opakovane.
#  Na konci se zepta, jestli chces YOLO rezim (default ANO).
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

# --- seed ~/.claude/settings.json -----------------------------
#  RemoteControl (remoteControlAtStartup) zapiname VZDY = ovladani
#  z aplikace Claude v kazde session, bez ptani.
#  YOLO (bypassPermissions) jen kdyz si ho user zvoli (param $1 = 1).
seed_settings() {
    YOLO="${1:-0}"
    S="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$S" "$YOLO" <<'PY'
import json, os, sys
p, yolo = sys.argv[1], sys.argv[2]
d = {}
if os.path.exists(p):
    try:
        with open(p) as f:
            d = json.load(f)
    except Exception:
        d = {}
d["remoteControlAtStartup"] = True
if yolo == "1":
    d.setdefault("permissions", {})["defaultMode"] = "bypassPermissions"
    d["skipDangerousModePermissionPrompt"] = True
with open(p, "w") as f:
    json.dump(d, f, indent=2)
PY
        if [ "$YOLO" = "1" ]; then ok "RemoteControl + YOLO rezim zapnuty (plati pro vsechny sessions)."
        else ok "RemoteControl zapnuty pro vsechny sessions."; fi
    elif [ ! -f "$S" ]; then
        if [ "$YOLO" = "1" ]; then
            cat > "$S" <<'EOF'
{
  "remoteControlAtStartup": true,
  "permissions": {
    "defaultMode": "bypassPermissions"
  },
  "skipDangerousModePermissionPrompt": true
}
EOF
            ok "RemoteControl + YOLO rezim zapnuty (plati pro vsechny sessions)."
        else
            cat > "$S" <<'EOF'
{
  "remoteControlAtStartup": true
}
EOF
            ok "RemoteControl zapnuty pro vsechny sessions."
        fi
    else
        warn "Nemam python3 a settings.json uz existuje - nastav rucne:"
        warn "  v $S nastav \"remoteControlAtStartup\": true"
        [ "$YOLO" = "1" ] && warn "  a permissions.defaultMode na \"bypassPermissions\"."
    fi
}

ask_yolo() {
    echo ""
    info "Chces zapnout YOLO rezim?"
    echo "  YOLO = Claude se nepta na svoleni pro kazdou drobnost (rychlejsi"
    echo "  prace). Plati pro vsechny sessions. Doporuceno pro zacatek."
    ans="Y"
    if [ -r /dev/tty ]; then
        printf "  Zapnout YOLO? [Y/n]: "
        read -r ans < /dev/tty || ans="Y"
        [ -z "$ans" ] && ans="Y"
    else
        echo "  (Neinteraktivni beh - zapinam YOLO automaticky.)"
    fi
    case "$ans" in
        [Nn]*) info "YOLO rezim NEzapnuty (Claude se bude ptat na svoleni)."
               seed_settings 0 ;;
        *)     seed_settings 1 ;;
    esac
}

pause_end() {
    echo ""
    if [ -r /dev/tty ]; then
        read -n 1 -s -r -p "Stiskni libovolnou klavesu pro zavreni..." < /dev/tty || true
        echo ""
    fi
}

# --- 1) Uz nainstalovano? (idempotence) -----------------------
if command -v claude >/dev/null 2>&1; then
    VER="$(claude --version 2>/dev/null || echo '?')"
    ok "Claude Code uz je nainstalovany (verze: ${VER})."
    info "Zkousim aktualizaci..."
    claude update 2>/dev/null && ok "Aktualizace probehla (nebo uz mas nejnovejsi)." || warn "Aktualizaci nelze spustit automaticky (nevadi)."
    ask_yolo
    echo ""
    info "Spustis ho prikazem:  claude"
    pause_end
    exit 0
fi

# --- 2) curl je na macOS soucasti systemu ---------------------
if ! command -v curl >/dev/null 2>&1; then
    err "Chybi 'curl' (na macOS byva vzdy). Neco je neobvykle - napis nam."
    pause_end
    exit 1
fi

# --- 3) Vlastni instalace -------------------------------------
info "Stahuji a instaluji Claude Code (oficialni installer z claude.ai)..."
if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "Installer dobehl."
else
    err "Instalace selhala. Zkontroluj pripojeni k internetu a spust skript znovu."
    pause_end
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

# --- 5) YOLO rezim --------------------------------------------
ask_yolo

# --- 6) Overeni -----------------------------------------------
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
pause_end
