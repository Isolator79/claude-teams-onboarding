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

---

## Krok 02 - Pripoj Claude k Teams

Aby sis s Claude mohl psat primo ve svem **Teams** (podobne jako pres
Telegram). V Teams ti vznikne skupinovy chat **"Claude"** (jen ty v nem).
Co tam napises, Claude precte a odpovi ti primo do chatu.

**Dulezite - dva ruzne ucty se nepletou:**

- Ucet, na kterem bezi **Claude** (krok 01), muze byt jakykoliv
  (klidne placena verze na Gmailu). S Teams nema nic spolecneho.
- Tady v kroku 02 se prihlasujes do sveho **pracovniho uctu na Teams**,
  tedy **tvuj-email@bidli.cz**. Vsichni u nas maji Teams na bidli.cz.

Predpoklad: hotovy krok 01 (nainstalovany Claude Code) a **Python 3**.

### Windows

1. Stahni celou slozku `teams/` (nebo cely tento projekt).
2. Dvojklik na [`teams/02-teams.cmd`](teams/02-teams.cmd).
3. Pri prvnim spusteni se vypise **kod** a **webova adresa**.
   Adresu zkopiruj do prohlizece, zadej kod a prihlas se uctem bidli.cz.
4. Hotovo - okno nech otevrene a piš si s Claude v Teams v chatu "Claude".

### Mac / Linux

```bash
bash teams/02-teams.sh
```

Pri prvnim spusteni zkopiruj vypsanou **adresu do prohlizece**, zadej
**kod** a prihlas se uctem bidli.cz. Pak uz si pis s Claude v Teams.

> Program nech bezet (na serveru klidne pres `tmux`). Ukoncis ho
> klavesami Ctrl + C. Prihlaseni se pamatuje, podruhe uz kod nezadavas.

---

## Co bude dal

- **tmux** - aby Claude bezel na serveru porad (i kdyz zavres okno).
  Dostanes samostatne.
