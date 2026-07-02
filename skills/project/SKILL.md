---
name: project
description: Na velky ukol pusti vic agentu (pomocniku) najednou a jeden z nich vysledek zkontroluje - rychleji a bez halucinaci. Pro slozitejsi veci, co by v jedne konverzaci byly neprehledne.
triggers:
  - explicit: "/project"
  - implicit: velky nebo slozity ukol, ktery se da rozdelit na vic samostatnych casti
---

# Skill: project (vic pomocniku najednou)

## K cemu to je

Velky ukol se da rozseknout na mensi casti a nechat je delat **vic agentu
(pomocniku) soucasne**. Jde to rychleji a kazda cast ma "cistou hlavu"
(min chyb a halucinaci). Nakonec jeden pomocnik vysledek **zkontroluje**.

## Jak postupuju

1. **Rozdelim** ukol na samostatne casti, ktere na sobe nezavisi.
2. **Rozdam praci** mezi vic agentu, co bezi najednou (Claude Code to umi
   pres tzv. subagenty).
3. **Posbiram** vysledky dohromady.
4. **Kontrola:** jeden agent overi, ze to sedi - hleda chyby, ne potvrzeni.
   Teprve pak to beru za hotove.

## Pravidlo "udelej -> zkontroluj"

Nikdy neverim prvnimu vysledku naslepo. Kazdou dulezitou cast **overim zvlast**
(jiny agent, ktery se snazi najit chybu). Co neprojde, opravim a zkontroluju
znovu. Tim se drzi kvalita i u velkych uloh.

## Kdy to pouzit / nepouzit

- **Pouzit:** reserse z vic zdroju, projit hodne souboru, vic nezavislych
  uprav najednou, "udelej to dukladne".
- **Nepouzit:** drobny jednorazovy dotaz - staci obycejny chat. Vic agentu by
  byl zbytecny overhead a spalene tokeny.

## Jak mluvim

Lidsky, cesky, strucne. Na konci reknu, co se udelalo a jestli to proslo
kontrolou. Slozitou mechaniku (kolik agentu, jak presne) neresim nahlas, pokud
o to vylozene nepozadas.

## Vztah k `mhproject`

Tohle je zjednodusena verze. Kdyz budes chtit plnou orchestraci (retez
samostatnych sessions, automaticke pousteni, self-heal, paralelni vetve),
pouzij pokrocily skill `mhproject`. `project` je pro rychle "pust vic pomocniku
a zkontroluj to" bez uceni cele mašinerie.
