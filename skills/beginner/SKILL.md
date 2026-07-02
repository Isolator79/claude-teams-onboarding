---
name: beginner
description: Pro zacatecniky - Claude sam systematizuje tvoji praci do temat (slozek). Sam pozna, k cemu se vracis, zalozi nove tema, uklada kratka shrnuti a priste navaze. Nemusis se starat o zadne soubory ani strukturu.
triggers:
  - explicit: "/beginner"
  - implicit: uzivatel pracuje na tematu, ke kteremu se vraci, nebo rekne "uloz to" / "jdu spat" / "pokracuju v X"
---

# Skill: beginner (systematizace za tebe)

## K cemu to je

Nemusis umet zakladat slozky ani vest poznamky. Tenhle skill to dela za tebe:
pozna, na cem pracujes, ulozi to do spravneho "tematu" a priste navaze. Cil je,
aby to zvladl uplny zacatecnik, ktery se o zadne soubory starat nechce.

## Kam se to uklada

Vse jde do jedne slozky s tematy: `~/claude-temata/`. Kazde tema = podslozka:

- `~/claude-temata/<tema>/README.md` - kratky stav (o cem to je, kde jsme skoncili)
- `~/claude-temata/<tema>/poznamky.md` - prubezne poznamky (pridava se dolu)

Tuhle slozku muzes synchronizovat pres OneDrive / Dropbox / Google Drive ->
stejna temata mas pak na vsech svych pocitacich.

## Co delam automaticky

1. **Start:** mrknu do `~/claude-temata/`. Kdyz aktualni prace odpovida
   existujicimu tematu, reknu *"vypada to na tema X, mam navazat?"*.
2. **Nove tema:** kdyz je to neco noveho, sam zalozim podslozku + `README.md`
   (zeptam se jen na kratky nazev tematu).
3. **Prubezne:** dulezita rozhodnuti a zjisteni zapisu do `poznamky.md`, aby se
   neztratila.
4. **"uloz to" / "jdu spat" / "pauza":** ulozim kratke shrnuti (co se udelalo,
   co dal) do `README.md` i `poznamky.md`.
5. **"pokracuju v X" / "vrat se k X":** prectu `README.md` + posledni poznamky
   a shrnu, kde jsme skoncili.

## Jak mluvim

Lidsky, cesky, strucne. Zadne technicke zkratky, zadne paticky ani casove
znacky. Kdyz se ptam na nazev tematu, nabidnu rovnou svuj navrh.

## Co NEdelam (schvalne jednoduche)

Nezakladam slozite struktury, nevedu tabulky otazek/ukolu, neresim git ani
casove znacky. Kdyz budes chtit plny profesionalni system (vice agentu,
orchestrace, verzovani), existuje pokrocily skill `mhproject`. Tenhle je
zamerne jednoduchy - at se v tom zacatecnik neztrati.
