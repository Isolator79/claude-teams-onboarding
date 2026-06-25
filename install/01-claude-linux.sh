#!/usr/bin/env bash
# ============================================================
#  Claude Code - instalace na Linux (Ubuntu / Debian a podobne)
# ------------------------------------------------------------
#  Pro koho: pro hosting / server kde bezi Linux.
#  Co to udela:
#    - doinstaluje zakladni knihovny, pokud na cerstvem OS chybi
#      (curl, ca-certificates, git, python3 - python3 je potreba
#       pro pozdejsi napojeni na Teams),
#    - nainstaluje program "claude" (Claude Code), nebo kdyz uz je,
#      zkusi ho aktualizovat (update),
#    - zepta se, jestli chces YOLO rezim (Claude se nepta na kazdou
#      drobnost) - defaultne ANO, plati pro vsechny sessions.
#  Bezpecne poustet opakovane (idempotentni).
# ============================================================

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Instalace Claude Code (Linux) ==="
echo ""

# Installer obvykle uklada do ~/.local/bin - pridame do PATH pro tento beh.
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- pomocnik: spustit pod rootem (sudo jen kdyz je potreba) ---
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi

# --- detekce spravce balicku -----------------------------------
PKG=""
for m in apt-get dnf yum pacman zypper apk; do
    if command -v "$m" >/dev/null 2>&1; then PKG="$m"; break; fi
done

pkg_install() {
    # pkg_install <balicky...> - nainstaluje pres dostupny spravce balicku
    [ "$#" -eq 0 ] && return 0
    case "$PKG" in
        apt-get) $SUDO apt-get update -qq && $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
        dnf)     $SUDO dnf install -y "$@" ;;
        yum)     $SUDO yum install -y "$@" ;;
        pacman)  $SUDO pacman -Sy --noconfirm "$@" ;;
        zypper)  $SUDO zypper --non-interactive install "$@" ;;
        apk)     $SUDO apk add "$@" ;;
        *)       return 1 ;;
    esac
}

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

# --- zaklad pro cerstvy OS: doinstaluj, co chybi ---------------
info "Kontroluji zakladni knihovny (pro jistotu na cerstvem systemu)..."
NEED=()
command -v curl  >/dev/null 2>&1 || NEED+=("curl")
command -v git   >/dev/null 2>&1 || NEED+=("git")
# python3 pouzije az krok 02 (Teams) a YOLO zapis, ale doinstalujeme rovnou.
command -v python3 >/dev/null 2>&1 || NEED+=("python3")
# ca-certificates kvuli https (na holem systemu casto chybi)
if [ "$PKG" = "apt-get" ] || [ "$PKG" = "dnf" ] || [ "$PKG" = "yum" ]; then
    NEED+=("ca-certificates")
fi

if [ "${#NEED[@]}" -gt 0 ]; then
    if [ -z "$PKG" ]; then
        warn "Nepoznal jsem spravce balicku. Chybi: ${NEED[*]}"
        warn "Nainstaluj je rucne a spust skript znovu."
    else
        info "Doinstalovavam: ${NEED[*]}"
        if pkg_install "${NEED[@]}"; then ok "Zakladni knihovny pripraveny."
        else warn "Nektere balicky se nepodarilo doinstalovat - zkousim pokracovat."; fi
    fi
else
    ok "Zakladni knihovny uz jsou k dispozici."
fi

# curl je nezbytny pro instalaci Claude
if ! command -v curl >/dev/null 2>&1; then
    err "Chybi 'curl' a nepodarilo se ho doinstalovat. Nainstaluj ho rucne a spust znovu."
    exit 1
fi

# --- uz nainstalovano? -> aktualizace (idempotence) -----------
if command -v claude >/dev/null 2>&1; then
    ok "Claude Code uz je nainstalovany (verze: $(claude --version 2>/dev/null || echo '?'))."
    info "Zkousim aktualizaci..."
    if claude update 2>/dev/null; then ok "Aktualizace probehla (nebo uz mas nejnovejsi)."
    else warn "Aktualizaci se nepodarilo spustit automaticky (nevadi, Claude se umi updatovat i sam)."; fi
    ask_yolo
    echo ""
    info "Spustis ho prikazem:  claude"
    exit 0
fi

# --- vlastni instalace ----------------------------------------
info "Stahuji a instaluji Claude Code (oficialni installer z claude.ai)..."
if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "Installer dobehl."
else
    err "Instalace selhala. Zkontroluj pripojeni k internetu a spust skript znovu."
    exit 1
fi

# --- PATH do budoucich oken (idempotentne) --------------------
LINE='export PATH="$HOME/.local/bin:$PATH"'
RC="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && RC="$HOME/.zshrc"
if [ -f "$RC" ] && grep -qF '.local/bin' "$RC"; then
    :
else
    printf '\n# Claude Code - cesta k programu\n%s\n' "$LINE" >> "$RC"
    ok "Cesta k programu pridana do $RC"
fi
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

# --- YOLO rezim ------------------------------------------------
ask_yolo

# --- overeni --------------------------------------------------
echo ""
if command -v claude >/dev/null 2>&1; then
    ok "Hotovo. Verze: $(claude --version 2>/dev/null || echo '?')"
else
    warn "Program 'claude' zatim neni videt v tomto okne."
    warn "Zavri terminal, otevri NOVY a zkus napsat:  claude"
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
