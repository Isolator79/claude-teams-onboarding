# Telegram napojeni - cesta B (prompt pro odvazne)

> Cesta A (pro vsechny) je jeden prikaz `03-telegram.sh` - viz README.
> Tady je cesta B: **rekni to Claudovi a on se napoji sam.** Hodi se jako
> ukazka agentni sily. Predpoklad: Claude Code uz bezi (KROK 01) a mas
> **token bota od @BotFather** (v Telegramu napis @BotFather `/newbot`).

## Jak na to

Spust `claude` na serveru a vloz mu tento prompt (token nahrad svym):

---

```
Napoj se na muj Telegram, at ti muzu psat z mobilu. Postupuj takto:

1) Balik uz mam v ~/claude-teams-onboarding (pokud ne, naklonuj
   https://github.com/Isolator79/claude-teams-onboarding.git tam).
2) Muj bot token od @BotFather je:  <SEM VLOZ TOKEN>
   Uloz ho do ~/claude-teams-onboarding/telegram/telegram_token.json
   ve tvaru {"token": "<TOKEN>"} a nastav prava 600.
3) Over token pres Telegram API getMe (curl na
   https://api.telegram.org/bot<TOKEN>/getMe) - vypis mi jmeno bota.
4) Rekni mi, at svemu botovi v Telegramu napisu zpravu (napr. /start).
   Pak preo getUpdates zjisti moje chat_id a uloz ho do
   telegram/telegram_state.json.
5) Spust most jako sluzbu na pozadi: pouzij hotovy skript
   telegram/03-telegram.sh (uz umi systemd --user unit), nebo kdyz
   uz mam token i chat_id nastavene, rovnou:
   systemctl --user restart claude-telegram (pripadne unit vytvor).
6) Posli mi do Telegramu testovaci zpravu, ze most bezi.

Vsechno mi prubezne hlas. Token nikam neposilej a necommituj.
```

---

## Pozn.

- Token ani `telegram_state.json` se **necommituji** (jsou v `.gitignore`).
- Vysledek je stejny jako cesta A - jen to Claude udela "rukama" misto
  hotoveho skriptu. Kdyz se neco zvrtne, spolehni se na cestu A.
