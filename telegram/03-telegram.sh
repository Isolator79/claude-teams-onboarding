#!/usr/bin/env bash
# ============================================================
#  Krok 03 - napojeni Claude na Telegram (Linux / macOS)
# ------------------------------------------------------------
#  Tento skript je urceny ke spusteni primo z internetu
#  (vzdy se tak vezme nejnovejsi verze z gitu):
#
#    curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/telegram/03-telegram.sh | bash
#
#  Co to udela:
#    - doinstaluje git a python3, pokud chybi,
#    - stahne (nebo zaktualizuje) balik skriptu do ~/claude-teams-onboarding,
#    - pri prvnim behu te provede nastavenim Telegram bota (token od @BotFather),
#    - spusti most na pozadi jako sluzbu: pises botovi v Telegramu, Claude
#      odpovida (vc. prubehu prace). Notifikace chodi normalne.
#  Nezavisle na ostatnich skriptech, bezpecne poustet opakovane.
#  Bezi v JINE, oddelene session nez Teams (KROK 02).
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
info "=== Krok 03: napojeni Claude na Telegram ==="
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

CORE="$DEST/telegram/telegram_claude.py"
if [ ! -f "$CORE" ]; then err "Chybi soubor $CORE - neco se nestahlo spravne."; exit 1; fi

# --- upozorneni kdyz chybi Claude (krok 01) --------------------
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
if ! command -v claude >/dev/null 2>&1; then
    warn "Nenasel jsem program 'claude' (Claude Code)."
    warn "Most bude bezet, ale dokud Claude nenainstalujes (KROK 01), nebude umet odpovidat."
    echo ""
fi

# --- prvni nastaveni bota (pokud jeste neni) -------------------
if [ ! -f "$DEST/telegram/telegram_token.json" ] || [ ! -f "$DEST/telegram/telegram_state.json" ]; then
    info "Jeste nemas nastaveneho Telegram bota - spoustim nastaveni..."
    echo ""
    "$PY" "$CORE" setup || { err "Nastaveni se nezdarilo. Spust prikaz znovu."; exit 1; }
fi

# --- instalace mostu jako sluzby na pozadi (systemd --user) ----
install_service_systemd() {
    PYBIN="$(command -v "$PY" 2>/dev/null || echo "$PY")"
    UNIT_DIR="$HOME/.config/systemd/user"
    mkdir -p "$UNIT_DIR"
    cat > "$UNIT_DIR/claude-telegram.service" <<EOF
[Unit]
Description=Most mezi Telegramem a Claude Code
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$DEST/telegram
ExecStart=$PYBIN $CORE run
Restart=always
RestartSec=5
Environment=PATH=$HOME/.local/bin:$HOME/.claude/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload || return 1
    loginctl enable-linger "$(id -un)" >/dev/null 2>&1 \
        || $SUDO loginctl enable-linger "$(id -un)" >/dev/null 2>&1 || true
    systemctl --user enable claude-telegram.service >/dev/null 2>&1
    systemctl --user restart claude-telegram.service || return 1
    return 0
}

# --- spust most na pozadi (vzdy, bez ptani) --------------------
echo ""
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    info "Instaluji most jako sluzbu na pozadi (bezi nonstop, nabehne i po restartu serveru)..."
    if install_service_systemd; then
        echo ""
        ok "Most bezi na pozadi jako sluzba 'claude-telegram'. Toto okno muzes zavrit."
        echo ""
        info "Uzitecne prikazy:"
        echo "  stav:      systemctl --user status claude-telegram"
        echo "  zivy log:  journalctl --user -u claude-telegram -f"
        echo "  stop:      systemctl --user stop claude-telegram"
        echo "  start:     systemctl --user start claude-telegram"
        echo ""
        ok "Ted uz si jen pis se svym botem v Telegramu."
    else
        warn "Sluzbu se nepodarilo nainstalovat - spoustim na pozadi pres nohup."
        LOG="$DEST/telegram/most.log"
        nohup "$PY" "$CORE" run >"$LOG" 2>&1 &
        ok "Most bezi na pozadi (PID $!). Log: $LOG"
    fi
else
    warn "Tento system nema systemd (napr. macOS) - spoustim na pozadi pres nohup."
    LOG="$DEST/telegram/most.log"
    nohup "$PY" "$CORE" run >"$LOG" 2>&1 &
    echo ""
    ok "Most bezi na pozadi (PID $!). Log: $LOG"
    warn "Pozn.: po restartu pocitace ho spustis znovu prikazem KROK 03."
fi
