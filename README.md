# Claude pro nas tym

Tady najdes navody a hotove skripty, ktere ti pomohou rozjet vlastniho
Claude (Claude Code) a pozdeji ho napojit na Teams.

Skripty jsou cislovane podle poradi. Zacni cislem **01**.

---

## Krok 01 - Nainstaluj si Claude Code

Vyber si podle toho, na cem to chces provozovat. Mas dve moznosti:

- **Na svem pocitaci** (Windows nebo Mac) - dobre na hrani a vyzkouseni.
- **Na hostingu / serveru** (Linux) - kdyz ma Claude bezet porad.

Vsechny skripty jsou bezpecne - kdyz je spustis vickrat, nic nerozbiji
(napr. po aktualizaci z internetu). Kdyz uz je neco nainstalovane, jen to oznami.

### Windows

1. Stahni soubor [`install/01-claude-windows.cmd`](install/01-claude-windows.cmd).
   (Na strance souboru klikni na **Download raw file** / **Raw** a uloz.)
2. Dvojklik na stazeny soubor.
   - Kdyby Windows hlasil "Windows ochranil pocitac", klikni na
     **Dalsi informace** a pak **Presto spustit**.
3. Pockej, az to dobehne, a ridil se pokyny na konci ("CO DAL").

> Funguje i na starsich/zakladnich Windows. Kdyz neni moderni Terminal
> ani winget, skript pouzije nahradni zpusob automaticky.

### Mac (macOS)

1. Stahni soubor [`install/01-claude-macos.command`](install/01-claude-macos.command).
2. Dvojklik na stazeny soubor.
   - Kdyby to macOS nechtel spustit ("nelze otevrit, neznamy vyvojar"),
     klikni na soubor **pravym tlacitkem** -> **Otevrit** -> **Otevrit**.
   - Kdyby se misto spusteni otevrel text, otevri aplikaci **Terminal**
     (Spotlight - lupa vpravo nahore - napis `Terminal`), pretahni do nej
     stazeny soubor a stiskni Enter.
3. Ridil se pokyny na konci ("CO DAL").

### Linux (hosting / server)

Prihlas se na server a spust:

```bash
curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-linux.sh | bash
```

Nebo, kdyz mas repo stazene, spust primo:

```bash
bash install/01-claude-linux.sh
```

Pak se ridil pokyny na konci ("CO DAL").

---

## Prvni prihlaseni (plati pro vsechny)

Po instalaci v novem okne napis:

```
claude
```

Pri prvnim spusteni se vypise **webova adresa (URL)**. Zkopiruj ji do
prohlizece, prihlas se a potvrd. Pak uz si muzes s Claude psat.

---

## Co bude dal

- **Napojeni na Teams** - aby sis s Claude mohl psat primo ve svem Teams
  (jako pres Telegram). Skript pridame jako dalsi krok.
- **tmux** - aby Claude bezel na serveru porad (i kdyz zavres okno).
  Dostanes samostatne.
