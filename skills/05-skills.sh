#!/usr/bin/env bash
# ============================================================
#  Krok 05 - instalace skillu do Claude (beginner + project)
# ------------------------------------------------------------
#  Spustit primo z internetu (vzdy nejnovejsi verze z gitu):
#
#    curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/skills/05-skills.sh | bash
#
#  Co to udela:
#    - nakopiruje skilly do ~/.claude/skills/ (beginner + project),
#    - od te chvile je v Claude vyvolas napsanim /beginner nebo /project.
#  Bezpecne poustet opakovane (jen prepise na nejnovejsi verzi).
# ============================================================

set -uo pipefail

RAW="https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/skills"
DEST="$HOME/.claude/skills"

GREEN='\033[0;32m'; BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${BOLD}$*${NC}"; }
err()  { echo -e "${RED}[CHYBA]${NC} $*"; }

echo ""
info "=== Krok 05: instalace skillu (beginner + project) ==="
echo ""

if ! command -v curl >/dev/null 2>&1; then
    err "Chybi curl. Nainstaluj ho a spust znovu."
    exit 1
fi

FAIL=0
for s in beginner project; do
    mkdir -p "$DEST/$s"
    if curl -fsSL -o "$DEST/$s/SKILL.md" "$RAW/$s/SKILL.md"; then
        ok "Skill '$s' nainstalovan -> $DEST/$s/SKILL.md"
    else
        err "Nepodarilo se stahnout skill '$s'."
        FAIL=1
    fi
done

echo ""
if [ "$FAIL" -eq 0 ]; then
    ok "Hotovo. V Claude je vyvolas napsanim:"
    echo "  /beginner - systematizace za tebe (temata/slozky automaticky)"
    echo "  /project  - vic pomocniku najednou na velky ukol + kontrola"
    echo ""
    echo "(Pokud mas Claude prave otevreny, zavri ho a spust znovu, at se skilly nactou.)"
else
    err "Cast skillu se nestahla - zkus prikaz spustit znovu."
    exit 1
fi
echo ""
