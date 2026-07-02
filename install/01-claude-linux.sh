#!/usr/bin/env bash
# ============================================================
#  Claude Code - instalace na Linux (Ubuntu / Debian a podobne)
# ------------------------------------------------------------
#  Pro koho: pro hosting / server kde bezi Linux.
#  Co to udela:
#    - doinstaluje zakladni knihovny, pokud na cerstvem OS chybi
#      (curl, ca-certificates, git, python3),
#    - kdyz ho spustis jako ROOT (cerstvy server): zepta se na jmeno
#      a heslo, ZALOZI ti bezneho uzivatele (Claude v YOLO rezimu pod
#      rootem bezet nesmi) a Claude nainstaluje rovnou jako on,
#    - nainstaluje program "claude" (Claude Code), nebo kdyz uz je,
#      zkusi ho aktualizovat (update),
#    - zapne YOLO rezim NAPEVNO (Claude se nepta na kazdou drobnost)
#      + RemoteControl - plati pro vsechny sessions.
#  Bezpecne poustet opakovane (idempotentni). Bezi i neinteraktivne
#  (curl ... | bash) - krome zalozeni uzivatele, kdy se pta na jmeno/heslo.
# ============================================================

set -uo pipefail

RAW_URL="https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-linux.sh"

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
        # POZOR: "env VAR=val" (ne "$SUDO VAR=val"), jinak pri prazdnem
        # $SUDO (root) bash vezme VAR=val jako nazev prikazu -> chyba.
        apt-get) $SUDO apt-get update -qq && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
        dnf)     $SUDO dnf install -y "$@" ;;
        yum)     $SUDO yum install -y "$@" ;;
        pacman)  $SUDO pacman -Sy --noconfirm "$@" ;;
        zypper)  $SUDO zypper --non-interactive install "$@" ;;
        apk)     $SUDO apk add "$@" ;;
        *)       return 1 ;;
    esac
}

# --- zaklad pro cerstvy OS: doinstaluj, co chybi ---------------
install_base_libs() {
    info "Kontroluji zakladni knihovny (pro jistotu na cerstvem systemu)..."
    NEED=()
    command -v curl    >/dev/null 2>&1 || NEED+=("curl")
    command -v git     >/dev/null 2>&1 || NEED+=("git")
    command -v python3 >/dev/null 2>&1 || NEED+=("python3")
    # ca-certificates jen kdyz opravdu chybi (jinak zbytecny apt beh)
    if [ "$PKG" = "apt-get" ] || [ "$PKG" = "dnf" ] || [ "$PKG" = "yum" ]; then
        if ! { [ -e /etc/ssl/certs/ca-certificates.crt ] || [ -e /etc/pki/tls/certs/ca-bundle.crt ]; }; then
            NEED+=("ca-certificates")
        fi
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
}

# --- seed ~/.claude/settings.json -----------------------------
#  RemoteControl (remoteControlAtStartup) zapiname VZDY = ovladani
#  z aplikace Claude v kazde session, bez ptani.
#  YOLO (bypassPermissions) zapiname napevno (param $1 = 1).
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

enable_yolo() {
    echo ""
    info "Zapinam YOLO rezim (napevno) + RemoteControl."
    echo "  YOLO = Claude se nepta na svoleni pro kazdou drobnost (rychlejsi"
    echo "  prace). RemoteControl = ovladani session z aplikace Claude."
    echo "  Plati pro vsechny sessions."
    seed_settings 1
}

# ============================================================
#  ROOT: Claude v YOLO pod rootem bezet nesmi. Zaloz uzivatele,
#  base knihovny doinstaluj jako root (aby beh usera nepotreboval
#  sudo heslo) a Claude nainstaluj uz jako novy uzivatel.
# ============================================================
if [ "$(id -u)" -eq 0 ]; then
    # base knihovny jako root (bez sudo) - aby je pozdejsi beh usera uz nemusel resit
    install_base_libs
    if ! command -v curl >/dev/null 2>&1; then
        err "Chybi 'curl' a nepodarilo se ho doinstalovat. Nainstaluj ho rucne a spust znovu."
        exit 1
    fi

    if [ ! -r /dev/tty ]; then
        err "Nemam interaktivni terminal (/dev/tty) pro dotaz na jmeno a heslo."
        err "Spust skript v beznem SSH terminalu nebo ve webove konzoli serveru."
        exit 1
    fi

    # --- jmeno uzivatele (validace + idempotence) ---
    #  Kdyz uzivatel uz existuje (opakovany beh), nabidneme jen doinstalaci
    #  Claude jako on - heslo NEMENIME, ucet nepretvarime.
    NEWUSER=""
    USER_EXISTS=0
    while true; do
        NEWUSER=""; USER_EXISTS=0
        read -r -p "Zvol jmeno uzivatele [user1]: " NEWUSER < /dev/tty || NEWUSER=""
        [ -z "$NEWUSER" ] && NEWUSER="user1"
        if ! printf '%s' "$NEWUSER" | grep -qE '^[a-z_][a-z0-9_-]{0,31}$'; then
            warn "Nepovolene jmeno. Jen mala pismena, cislice, _ a - ; zacni pismenem;"
            warn "bez mezer a bez diakritiky. Zkus to znovu."
            continue
        fi
        if id "$NEWUSER" >/dev/null 2>&1; then
            ans=""
            read -r -p "Uzivatel '$NEWUSER' uz existuje. Pouzit ho a jen (pre)instalovat Claude? [A/n]: " ans < /dev/tty || ans="A"
            case "$ans" in
                [Nn]*) continue ;;
                *) USER_EXISTS=1; break ;;
            esac
        fi
        break
    done

    if [ "$USER_EXISTS" -eq 1 ]; then
        info "Pouzivam existujiciho uzivatele '$NEWUSER' (heslo nechavam beze zmeny)."
    else
        # --- heslo (skryte, dvakrat, musi se shodovat) ---
        NEWPW=""
        while true; do
            p1=""; p2=""
            read -rs -p "Zvol heslo pro uzivatele '$NEWUSER': " p1 < /dev/tty; echo "" > /dev/tty
            read -rs -p "Zopakuj stejne heslo: "               p2 < /dev/tty; echo "" > /dev/tty
            if [ -z "$p1" ]; then warn "Heslo nesmi byt prazdne. Zkus to znovu."; continue; fi
            if [ "$p1" != "$p2" ]; then warn "Hesla se neshoduji. Zkus to znovu."; continue; fi
            NEWPW="$p1"
            break
        done

        # --- vytvoreni uzivatele ---
        echo ""
        info "Vytvarim uzivatele '$NEWUSER'..."
        if ! useradd -m -s /bin/bash "$NEWUSER" 2>/dev/null; then
            err "Nepodarilo se vytvorit uzivatele '$NEWUSER'."
            exit 1
        fi
        if ! printf '%s:%s\n' "$NEWUSER" "$NEWPW" | chpasswd; then
            err "Uzivatel vznikl, ale nepodarilo se nastavit heslo."
            exit 1
        fi
        if getent group sudo >/dev/null 2>&1; then
            usermod -aG sudo "$NEWUSER"
        elif getent group wheel >/dev/null 2>&1; then
            usermod -aG wheel "$NEWUSER"
        fi
        ok "Uzivatel '$NEWUSER' vytvoren (s pravy spravce / sudo)."
    fi

    # --- instalace Claude uz jako novy uzivatel ---
    echo ""
    info "Instaluji Claude Code jako uzivatel '$NEWUSER' (chvili to potrva)..."
    su - "$NEWUSER" -c "curl -fsSL '$RAW_URL' | bash"

    echo ""
    info "================ HOTOVO ================"
    echo "Od ted pracuj pod uzivatelem:  $NEWUSER   (NE root)"
    echo ""
    echo "  SSH:     ssh $NEWUSER@<IP-serveru>"
    echo "  WinSCP:  host = IP serveru, uzivatel = $NEWUSER, heslo = ktere jsi ted zadal"
    echo "  Claude:  napis  claude  (uz jsi prepnuty na $NEWUSER)"
    echo "======================================="
    echo ""

    # Rovnou prepnout na noveho uzivatele (login shell -> nactena cesta,
    # claude hned funguje). Pri odhlaseni (exit) se vratis do rootu.
    if [ -e /dev/tty ]; then
        info "Prepinam te na uzivatele '$NEWUSER'."
        echo ""
        exec su - "$NEWUSER" < /dev/tty
    fi
    exit 0
fi

# ============================================================
#  BEZNY UZIVATEL: vlastni instalace Claude Code.
#  (Sem se dostane i delegovany beh z root vetve vyse.)
# ============================================================
install_base_libs
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
    enable_yolo
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
enable_yolo

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
echo "1) Odhlas se a prihlas znovu (nebo otevri NOVY terminal), aby se nacetla cesta."
echo "2) Napis:  claude"
echo "3) Pri prvnim spusteni se vypise webova adresa (URL)."
echo "   Zkopiruj ji do prohlizece, prihlas se a potvrd."
echo "   Pak uz si muzes s Claude psat primo v terminalu."
echo ""
echo "   Navazat na predchozi konverzaci muzes prikazem:  claude --resume"
echo "======================================="
echo ""
