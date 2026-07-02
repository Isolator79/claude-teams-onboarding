#!/usr/bin/env bash
# ============================================================
#  Krok M365 - napojeni Claude na Microsoft 365 (Linux / macOS)
# ------------------------------------------------------------
#  Spustit primo z internetu (vzdy nejnovejsi verze z gitu):
#
#    curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/m365/03-m365.sh | bash
#
#  Co to udela:
#    - doinstaluje git a python3, pokud chybi,
#    - stahne (nebo zaktualizuje) balik do ~/claude-teams-onboarding,
#    - pri prvnim behu te prihlasi do Microsoft 365 (device code -
#      zkopirujes URL + kod do prohlizece, prihlasis se @bidli.cz),
#    - rekne Claudovi (pres ~/.claude/CLAUDE.md), ze umi tvuj M365
#      ovladat (mail, kalendar, OneDrive/SharePoint, cteni Teams chatu).
#  ZADNY "most do Teams" - komunikujes s Claudem normalne (terminal /
#  Telegram). Bezpecne poustet opakovane (idempotentni).
#
#  POZOR - dva ruzne ucty:
#    1) Claude ucet (kde Claude bezi/plati) - resi KROK 01 (instalace).
#    2) Microsoft 365 ucet - VZDY tvuj firemni @bidli.cz. Do nej se
#       prihlasis nize (zkopirujes URL + kod do prohlizece).
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
info "=== Krok M365: napojeni Claude na Microsoft 365 ==="
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
        # POZOR: "env VAR=val" (ne "$SUDO VAR=val") - pri prazdnem $SUDO by
        # bash bral VAR=val jako nazev prikazu -> "command not found".
        apt-get) $SUDO apt-get update -qq && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
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
        err "Chybi: ${NEED[*]} a nepoznal jsem spravce balicku. Nainstaluj rucne a spust znovu."
        exit 1
    fi
    info "Doinstalovavam: ${NEED[*]}"
    pkg_install "${NEED[@]}" || warn "Cast balicku se nepodarilo doinstalovat - zkousim pokracovat."
    command -v python3 >/dev/null 2>&1 && PY="python3"
    [ -z "$PY" ] && command -v python >/dev/null 2>&1 && PY="python"
fi
[ -z "$PY" ] && { err "Nenasel jsem python. Nainstaluj python3 a spust znovu."; exit 1; }
command -v git >/dev/null 2>&1 || { err "Nenasel jsem git. Nainstaluj git a spust znovu."; exit 1; }
ok "git i python jsou k dispozici."

# --- stahni / aktualizuj balik (idempotentne) ------------------
if [ -d "$DEST/.git" ]; then
    info "Balik uz mam, aktualizuji (git pull)..."
    git -C "$DEST" pull --ff-only || warn "git pull se nezdaril, pokracuji se stavajici verzi."
else
    info "Stahuji balik do: $DEST"
    git clone --depth 1 "$REPO_URL" "$DEST" || { err "Stazeni se nezdarilo."; exit 1; }
fi
M365="$DEST/m365"
[ -f "$M365/graph.py" ] || { err "Chybi $M365/graph.py - neco se nestahlo spravne."; exit 1; }
ok "Balik pripraveny v: $DEST"

# --- prvni prihlaseni do M365 (jen kdyz jeste neni) ------------
if [ -f "$M365/tokens.json" ]; then
    ok "Uz jsi prihlaseny do Microsoft 365 (token nalezen) - preskakuji prihlaseni."
else
    info "Jeste nejsi prihlaseny - spoustim prihlaseni do Microsoft 365..."
    echo "(Zkopiruj vypsanou adresu + kod do prohlizece a prihlas se svym @bidli.cz uctem.)"
    echo ""
    ( cd "$M365" && "$PY" m365_auth.py login ) || { err "Prihlaseni se nezdarilo. Spust prikaz znovu."; exit 1; }
fi

# --- rekni Claudovi (globalni CLAUDE.md), ze umi M365 ----------
#  Idempotentne: blok mezi znackami se vlozi nebo prepise (ne duplikuje).
info "Zapisuji Claudovi info o M365 nastroji do ~/.claude/CLAUDE.md ..."
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"
"$PY" - "$CLAUDE_MD" "$M365" <<'PY'
import sys, os
md, m365 = sys.argv[1], sys.argv[2]
BEGIN, END = "<!-- M365:BEGIN -->", "<!-- M365:END -->"
block = f"""{BEGIN}
## Microsoft 365 (mail / kalendar / soubory / Teams cteni)
Mas pristup k M365 uctu uzivatele. Pouzij nastroj (uz je prihlaseny, tokens.json):
  python3 {m365}/graph.py <prikaz>
Prikazy: whoami | mail [N] | send-mail <komu> <predmet> <text> | calendar [N]
 | chats [N] | messages <chatId> [N] | files [cesta] | GET/POST <path> [telo-json]
U CTENI (mail, kalendar, soubory) rovnou udelej. Pred ODESLANIM/ZMENOU navenek
(mail, udalost) kratce rekni, co delas. Odpovidej lidsky cesky, ne surovy JSON.
{END}"""
old = ""
if os.path.exists(md):
    with open(md, encoding="utf-8") as f:
        old = f.read()
if BEGIN in old and END in old:
    pre = old[:old.index(BEGIN)]
    post = old[old.index(END) + len(END):]
    new = pre + block + post
else:
    sep = "" if old.endswith("\n\n") or old == "" else ("\n" if old.endswith("\n") else "\n\n")
    new = old + sep + block + "\n"
with open(md, "w", encoding="utf-8") as f:
    f.write(new)
print("[OK] ~/.claude/CLAUDE.md aktualizovano.")
PY

# --- overeni prihlaseni ---------------------------------------
echo ""
info "Overuji prihlaseni..."
( cd "$M365" && "$PY" m365_auth.py whoami ) || warn "Nepodarilo se overit (token muze byt jeste cerstvy - zkus pozdeji 'whoami')."

# --- co tim user prave ziskal ---------------------------------
echo ""
info "================ HOTOVO ================"
echo "Claude ted umi pracovat s tvym Microsoft 365. Staci mu napsat (v terminalu"
echo "nebo pres Telegram) treba:"
echo "  - Podivej se mi do mailu, mam neco noveho?"
echo "  - Posli mail na jan@firma.cz, predmet Schuzka, text Muzeme v patek?"
echo "  - Co mam dnes v kalendari?"
echo "  - Ukaz moje posledni Teams chaty"
echo "  - Co mam na OneDrive?"
echo ""
echo "Prihlaseni plati dlouhodobe (token se sam obnovuje). Znovu prihlasit:"
echo "  cd $M365 && $PY m365_auth.py login"
echo "======================================="
echo ""
