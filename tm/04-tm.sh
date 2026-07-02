#!/usr/bin/env bash
# ============================================================
#  Krok 04 - instalace TM (tmux helper) do PATH (Linux / macOS)
# ------------------------------------------------------------
#  Spousti se primo z internetu (vzdy nejnovejsi verze z gitu):
#
#    curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/tm/04-tm.sh | bash
#
#  Co to udela:
#    - doinstaluje git, tmux a python3, pokud chybi,
#    - stahne (nebo zaktualizuje) balik skriptu do ~/claude-teams-onboarding,
#    - nakopiruje 'tm' do ~/.local/bin a vytvori varianty TM/tM/Tm
#      (aby fungoval prikaz napsany jakkoliv velkymi/malymi pismeny),
#    - zajisti, ze ~/.local/bin je v PATH (do .bashrc / .zshrc).
#  Nezavisle na ostatnich skriptech, bezpecne poustet opakovane.
# ============================================================

set -uo pipefail

REPO_URL="https://github.com/Isolator79/claude-teams-onboarding.git"
DEST="$HOME/claude-teams-onboarding"
BIN="$HOME/.local/bin"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}[POZOR]${NC} $*"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Krok 04: instalace TM (tmux helper) ==="
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

# --- zajisti git + tmux ----------------------------------------
NEED=()
command -v git  >/dev/null 2>&1 || NEED+=("git")
command -v tmux >/dev/null 2>&1 || NEED+=("tmux")
if [ "${#NEED[@]}" -gt 0 ]; then
    if [ -z "$PKG" ]; then
        err "Chybi: ${NEED[*]} a nepoznal jsem spravce balicku. Nainstaluj je rucne a spust znovu."
        exit 1
    fi
    info "Doinstalovavam: ${NEED[*]}"
    pkg_install "${NEED[@]}" || warn "Cast balicku se nepodarilo doinstalovat - zkousim pokracovat."
fi
command -v git  >/dev/null 2>&1 || { err "Nenasel jsem git. Nainstaluj git a spust znovu."; exit 1; }
command -v tmux >/dev/null 2>&1 || warn "tmux se nepodarilo doinstalovat - TM bez nej nepojede, doinstaluj ho rucne."
ok "Zakladni knihovny pripraveny."

# --- stahni / aktualizuj balik (idempotentne) ------------------
if [ -d "$DEST/.git" ]; then
    info "Balik uz mam, aktualizuji na nejnovejsi verzi (git pull)..."
    git -C "$DEST" pull --ff-only || warn "git pull se nezdaril, pokracuji se stavajici verzi."
else
    info "Stahuji balik do: $DEST"
    git clone --depth 1 "$REPO_URL" "$DEST" || { err "Stazeni se nezdarilo."; exit 1; }
fi

SRC="$DEST/tm/tm"
if [ ! -f "$SRC" ]; then err "Chybi soubor $SRC - neco se nestahlo spravne."; exit 1; fi

# --- nakopiruj tm + varianty velikosti pismen ------------------
mkdir -p "$BIN"
install -m 0755 "$SRC" "$BIN/tm"
for v in TM tM Tm; do
    ln -sf tm "$BIN/$v"
done
ok "TM nainstalovan do $BIN (varianty: tm, TM, tM, Tm)."

# --- zajisti ~/.local/bin v PATH do budoucich oken -------------
LINE='export PATH="$HOME/.local/bin:$PATH"'
RC="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && RC="$HOME/.zshrc"
case "$(uname -s)" in
    Darwin) [ -f "$HOME/.zshrc" ] && RC="$HOME/.zshrc" || RC="$HOME/.bash_profile" ;;
esac
if [ -f "$RC" ] && grep -qF '.local/bin' "$RC"; then
    :
else
    printf '\n# TM / lokalni programy - cesta\n%s\n' "$LINE" >> "$RC"
    ok "Cesta ~/.local/bin pridana do $RC"
fi
export PATH="$HOME/.local/bin:$PATH"

# --- paticka (tmux status bar): nazev serveru + IP + cas -------
# Genericke, bere hostname automaticky pres #H (zadny natvrdo zapsany nazev).
# Zapisuje se jako spravovany blok do ~/.tmux.conf (idempotentne).
TMUXCONF="$HOME/.tmux.conf"
MARK_A="# >>> TM paticka (spravovano skriptem, needituj rucne) >>>"
MARK_B="# <<< TM paticka <<<"
read -r -d '' TM_FOOTER <<'EOF'
set -g status on
set -g status-interval 5
set -g status-bg colour235
set -g status-fg white
set -g status-justify centre
set -g status-left "#[bg=colour33,fg=white,bold] #S #[bg=colour235] "
set -g status-left-length 30
set -g status-right-length 80
set -g status-right "#[bg=colour33,fg=white,bold] #H #[bg=colour237,fg=white] #(hostname -I 2>/dev/null | awk '{print $1}') #[bg=colour235] %H:%M "
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
setw -g window-status-current-style "bg=colour33,fg=white,bold"
EOF
# odstran stary spravovany blok (idempotence), pak pridej cerstvy
if [ -f "$TMUXCONF" ] && grep -qF "$MARK_A" "$TMUXCONF"; then
    cp "$TMUXCONF" "$TMUXCONF.bak.$$" 2>/dev/null
    sed -i.tmpbak "/^$(printf '%s' "$MARK_A" | sed 's/[][\.*^$/]/\\&/g')$/,/^$(printf '%s' "$MARK_B" | sed 's/[][\.*^$/]/\\&/g')$/d" "$TMUXCONF" 2>/dev/null
    rm -f "$TMUXCONF.tmpbak"
fi
{ printf '\n%s\n%s\n%s\n' "$MARK_A" "$TM_FOOTER" "$MARK_B"; } >> "$TMUXCONF"
ok "Paticka nastavena (nazev serveru + IP + cas) do $TMUXCONF."
# kdyz uz tmux bezi, nacti hned at je paticka videt
tmux source-file "$TMUXCONF" >/dev/null 2>&1 || true

# --- overeni ---------------------------------------------------
echo ""
if command -v tm >/dev/null 2>&1; then
    ok "Hotovo. Napis  tm  (nebo TM) pro interaktivni tmux menu."
else
    ok "Hotovo."
    warn "Prikaz 'tm' zatim neni videt v tomto okne - zavri ho a otevri NOVY,"
    warn "pak napis:  tm"
fi
echo ""
