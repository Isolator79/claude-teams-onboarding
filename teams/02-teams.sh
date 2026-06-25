#!/usr/bin/env bash
# ============================================================
#  Krok 02 - napojeni Claude na Microsoft Teams (Linux / macOS)
# ------------------------------------------------------------
#  Tento skript je urceny ke spusteni primo z internetu
#  (vzdy se tak vezme nejnovejsi verze z gitu):
#
#    curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/teams/02-teams.sh | bash
#
#  Co to udela:
#    - doinstaluje git a python3, pokud chybi,
#    - stahne (nebo zaktualizuje) balik skriptu do slozky
#      ~/claude-teams-onboarding,
#    - pri prvnim behu te prihlasi do Teams (Microsoft 365),
#    - spusti most: pises Claudovi v Teams, Claude odpovida.
#  Nezavisle na ostatnich skriptech, bezpecne poustet opakovane.
#
#  POZOR - dva ruzne ucty:
#    1) Claude ucet (kde Claude bezi/plati) - libovolny, klidne Gmail.
#       To resi KROK 01 (instalace Claude Code).
#    2) Teams / Microsoft 365 ucet - VZDY tvuj firemni @bidli.cz.
#       Do nej se prihlasis nize (zkopirujes URL do prohlizece).
# ============================================================

set -uo pipefail

REPO_URL="https://github.com/Isolator79/claude-teams-onboarding.git"
DEST="$HOME/claude-teams-onboarding"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Krok 02: napojeni Claude na Teams ==="
echo ""

# --- spravce balicku (sudo jen kdyz je potreba) ----------------
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

PKG=""
for m in apt-get dnf yum pacman zypper apk brew; do
    command -v "$m" >/dev/null 2>&1 && { PKG="$m"; break; }
done
pkg_install() {
    [ "$#" -eq 0 ] && return 0
    case "$PKG" in
        apt-get) $SUDO apt-get update -qq && $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
        dnf)     $SUDO dnf install -y "$@" ;;
        yum)     $SUDO yum install -y "$@" ;;
        pacman)  $SUDO pacman -Sy --noconfirm "$@" ;;
        zypper)  $SUDO zypper --non-interactive install "$@" ;;
        apk)     $SUDO apk add "$@" ;;
        brew)    brew install "$@" ;;
        *)       return 1 ;;
    esac
}

# --- zajisti git + python3 -------------------------------------
NEED=()
command -v git >/dev/null 2>&1 || NEED+=("git")
PY=""
if command -v python3 >/dev/null 2>&1; then PY="python3"
elif command -v python >/dev/null 2>&1; then PY="python"
else NEED+=("python3"); fi

if [ "${#NEED[@]}" -gt 0 ]; then
    if [ -z "$PKG" ]; then
        err "Chybi: ${NEED[*]} a nepoznal jsem spravce balicku. Nainstaluj je rucne a spust znovu."
        exit 1
    fi
    info "Doinstalovavam: ${NEED[*]}"
    pkg_install "${NEED[@]}" || warn "Cast balicku se nepodarilo doinstalovat - zkousim pokracovat."
    command -v python3 >/dev/null 2>&1 && PY="python3"
    [ -z "$PY" ] && command -v python >/dev/null 2>&1 && PY="python"
fi
if [ -z "$PY" ]; then err "Nenasel jsem python. Nainstaluj python3 a spust znovu."; exit 1; fi
if ! command -v git >/dev/null 2>&1; then err "Nenasel jsem git. Nainstaluj git a spust znovu."; exit 1; fi
ok "git i python jsou k dispozici."

# --- stahni / aktualizuj balik (idempotentne) ------------------
if [ -d "$DEST/.git" ]; then
    info "Balik uz mam, aktualizuji na nejnovejsi verzi (git pull)..."
    git -C "$DEST" pull --ff-only || warn "git pull se nezdaril, pokracuji se stavajici verzi."
else
    info "Stahuji balik do: $DEST"
    git clone --depth 1 "$REPO_URL" "$DEST" || { err "Stazeni se nezdarilo."; exit 1; }
fi
ok "Balik pripraveny v: $DEST"

CORE="$DEST/teams/claude_teams.py"
if [ ! -f "$CORE" ]; then err "Chybi soubor $CORE - neco se nestahlo spravne."; exit 1; fi

# --- upozorneni kdyz chybi Claude (krok 01) --------------------
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
if ! command -v claude >/dev/null 2>&1; then
    warn "Nenasel jsem program 'claude' (Claude Code)."
    warn "Most bude bezet, ale dokud Claude nenainstalujes (KROK 01), nebude umet odpovidat."
    echo ""
fi

# --- prvni prihlaseni do Teams (pokud jeste neni) --------------
if [ ! -f "$DEST/teams/tokens.json" ]; then
    info "Jeste nejsi prihlaseny do Teams - spoustim prihlaseni..."
    echo "(Zkopiruj vypsanou webovou adresu do prohlizece a prihlas se svym @bidli.cz uctem.)"
    echo ""
    "$PY" "$CORE" login || { err "Prihlaseni se nezdarilo. Spust prikaz znovu."; exit 1; }
fi

# --- instalace mostu jako sluzby na pozadi (systemd --user) ----
install_service_systemd() {
    PYBIN="$(command -v "$PY" 2>/dev/null || echo "$PY")"
    UNIT_DIR="$HOME/.config/systemd/user"
    mkdir -p "$UNIT_DIR"
    cat > "$UNIT_DIR/claude-teams.service" <<EOF
[Unit]
Description=Most mezi Microsoft Teams a Claude Code
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$DEST/teams
ExecStart=$PYBIN $CORE run
Restart=always
RestartSec=5
Environment=PATH=$HOME/.local/bin:$HOME/.claude/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload || return 1
    # enable-linger = sluzba bezi i bez prihlaseni a po restartu serveru
    loginctl enable-linger "$(id -un)" >/dev/null 2>&1 \
        || $SUDO loginctl enable-linger "$(id -un)" >/dev/null 2>&1 || true
    systemctl --user enable claude-teams.service >/dev/null 2>&1
    systemctl --user restart claude-teams.service || return 1
    return 0
}

# --- jak most spustit: na pozadi jako sluzba, nebo tady v okne? ---
echo ""
HAS_SYSTEMD=0
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then HAS_SYSTEMD=1; fi

RUN_BG="Y"
if [ -r /dev/tty ]; then
    info "Chces, aby most bezel trvale na pozadi (i po restartu serveru)?"
    echo "  ANO = nainstaluje se jako sluzba, bezi nonstop a sama nabehne po restartu."
    echo "        Toto okno pak muzes klidne zavrit. (doporuceno pro server)"
    echo "  NE  = most pobezi jen tady v tomto okne, dokud ho nezavres (Ctrl+C)."
    printf "  Spustit na pozadi jako sluzbu? [Y/n]: "
    read -r RUN_BG < /dev/tty || RUN_BG="Y"
    [ -z "$RUN_BG" ] && RUN_BG="Y"
fi

case "$RUN_BG" in
    [Nn]*)
        echo ""
        info "Spoustim most tady v okne. Pis si s Claude v Teams (chat 'Claude')."
        info "Most ukoncis stiskem Ctrl+C."
        echo ""
        exec "$PY" "$CORE" run
        ;;
    *)
        if [ "$HAS_SYSTEMD" -eq 1 ]; then
            info "Instaluji most jako sluzbu na pozadi..."
            if install_service_systemd; then
                echo ""
                ok "Most bezi na pozadi jako sluzba 'claude-teams' a sam nabehne i po restartu serveru."
                echo ""
                info "Uzitecne prikazy:"
                echo "  stav:      systemctl --user status claude-teams"
                echo "  zivy log:  journalctl --user -u claude-teams -f"
                echo "  stop:      systemctl --user stop claude-teams"
                echo "  start:     systemctl --user start claude-teams"
                echo ""
                ok "Ted uz si jen pis s Claude v Teams (chat 'Claude'). Okno muzes zavrit."
            else
                warn "Sluzbu se nepodarilo nainstalovat - spoustim most tady v okne (Ctrl+C ukonci)."
                echo ""
                exec "$PY" "$CORE" run
            fi
        else
            warn "Tento system nema systemd (napr. macOS) - spoustim na pozadi pres nohup."
            LOG="$DEST/teams/most.log"
            nohup "$PY" "$CORE" run >"$LOG" 2>&1 &
            echo ""
            ok "Most bezi na pozadi (PID $!). Log: $LOG"
            warn "Pozn.: po restartu pocitace ho spustis znovu prikazem KROK 02."
        fi
        ;;
esac
