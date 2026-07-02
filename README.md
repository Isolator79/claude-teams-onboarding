# Claude pro nas tym

Tady najdes navody a hotove skripty, ktere ti pomohou rozjet vlastniho
Claude (Claude Code) a pozdeji ho napojit na Teams nebo Telegram.

Kazdy krok = **jeden prikaz**, ktery zkopirujes a spustis. Prikaz si
pokazde stahne **aktualni verzi z internetu** a spusti ji, takze:

- kdyz prikaz spustis znovu, automaticky se aktualizuje na nejnovejsi verzi,
- na poradi nezalezi a zadny krok nepotrebuje jiny,
- spoustet vickrat je bezpecne (nic to nerozbije).

---

## Krok 01 - Nainstaluj si Claude Code

Vyber si podle toho, na cem to chces provozovat:

- **Na svem pocitaci** (Windows nebo Mac) - dobre na hrani a vyzkouseni.
- **Na hostingu / serveru** (Linux) - kdyz ma Claude bezet porad.

### Windows

Stiskni klavesu **Windows**, napis `powershell`, otevri **Windows PowerShell**
a vloz tento prikaz (Enter):

```
irm https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-windows.ps1 | iex
```

> Funguje i na starsich/zakladnich Windows. Kdyz neni winget, pouzije se
> nahradni zpusob automaticky.
>
> Komu se nechce nic psat: stahni [`install/01-claude-windows.cmd`](install/01-claude-windows.cmd)
> (na strance souboru **Raw** -> uloz) a dvojklik. Dela presne to same a
> taky si vzdy stahne aktualni verzi. Kdyby Windows hlasil "Windows ochranil
> pocitac", klikni **Dalsi informace** -> **Presto spustit**.

### Mac (macOS)

Otevri aplikaci **Terminal** (Spotlight - lupa vpravo nahore - napis `Terminal`)
a vloz tento prikaz (Enter):

```bash
curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-macos.command | bash
```

### Linux (hosting / server)

Prihlas se na server a vloz tento prikaz (Enter):

```bash
curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-linux.sh | bash
```

Pak se ridil pokyny na konci ("CO DAL").

---

## Prvni prihlaseni (plati pro vsechny)

Po instalaci zavri okno, otevri **nove** a napis:

```
claude
```

Pri prvnim spusteni se vypise **webova adresa (URL)**. Zkopiruj ji do
prohlizece, prihlas se a potvrd. Pak uz si muzes s Claude psat.

---

## Krok M365 - Pripoj Claude k Microsoft 365

Aby Claude umel pracovat s tvym **Microsoft 365** - mailem, kalendarem,
soubory na OneDrive/SharePointu a **cist tve Teams chaty**. Pak mu staci
napsat (v terminalu nebo pres Telegram) *"podivej se mi do mailu"* nebo
*"co mam dnes v kalendari"* a on to udela.

> Jen pro **selfhosted server** (Linux/macOS), kde Claude bezi. Na Windows
> se nic z Microsoftu neinstaluje.

**Dulezite - dva ruzne ucty se nepletou:**

- Ucet, na kterem bezi **Claude** (krok 01), muze byt jakykoliv
  (klidne placena verze na Gmailu). S Microsoftem nema nic spolecneho.
- Tady se prihlasujes do sveho **pracovniho uctu Microsoft 365**,
  tedy **tvuj-email@bidli.cz**.

Prikaz si sam doinstaluje co potrebuje (git, Python) a stahne se do slozky
`claude-teams-onboarding` v tvem domovskem adresari. Pri opakovanem spusteni
se aktualizuje. Prihlaseni se pamatuje - podruhe uz kod nezadavas.

```bash
curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/m365/03-m365.sh | bash
```

Pri prvnim spusteni zkopiruj vypsanou **adresu + kod do prohlizece** a
prihlas se uctem bidli.cz. Skript pak rekne Claudovi (pres `~/.claude/CLAUDE.md`),
ze umi tvuj M365 ovladat - od te chvile mu staci napsat, co chces.

> Prihlaseni plati dlouhodobe (token se sam obnovuje). Znovu prihlasit:
> `cd ~/claude-teams-onboarding/m365 && python3 m365_auth.py login`.

---

## Krok 03 - Pripoj Claude k Telegramu (snadnejsi varianta)

Pokud chces psat Claudovi radeji v **Telegramu** (notifikace tam chodi uplne
normalne a nastaveni je jednodussi nez Teams), pouzij tohle. Bezi v **oddelene
session** nez Teams - klidne muzes mit oboji zaroven.

Co budes potrebovat: **token bota** od **@BotFather** (skript te tim provede -
v Telegramu napises @BotFather `/newbot`, das jmeno a dostanes token).

> Uz nejakeho Telegram bota pouzivas jinde? Vytvor si pro tohle **noveho**
> bota (vlastni token) - dva programy nemohou cist stejneho bota najednou,
> tlouklo by se to. Skript se te pri nastaveni zepta, **pod jakym jmenem**
> se ma bot v Telegramu zobrazovat (at je odlisis).

### Mac / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/telegram/03-telegram.sh | bash
```

Skript se zepta na token, pak te poprosi napsat svemu botovi zpravu (aby se
spojil prave s tebou) a nainstaluje se jako **sluzba na pozadi** (bezi nonstop,
nabehne i po restartu serveru). Pak uz jen pises botovi v Telegramu.

> Sprava sluzby: `systemctl --user status claude-telegram` (stav),
> `... stop ...` / `... start ...`.
>
> Pokud mas rozjety i Teams (krok 02), umi ti Claude i pres Telegram kouknout
> do mailu a kalendare (pouzije stejne M365 prihlaseni).

---

## Krok 04 - TM (snadne prepinani tmux sessions)

`TM` je maly pomocnik na **tmux** - rucni spousteni a prepinani sessions na
serveru (alternativa/doplnek ke sluzbe na pozadi). Po instalaci napises odkudkoliv
`tm` (nebo `TM`) a dostanes interaktivni menu: nova session, pripojeni,
zavreni, prejmenovani.

### Mac / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/tm/04-tm.sh | bash
```

Skript doinstaluje tmux (pokud chybi), nakopiruje `tm` do `~/.local/bin`
(vc. variant `TM`/`tM`/`Tm`, aby fungoval at ho napises jakkoliv) a zajisti,
ze je v PATH. Pak zavri okno, otevri nove a napis `tm`.

---

## Co bude dal

- Dalsi kroky podle potreby (napr. spolecny rozcestnik `menu`).
