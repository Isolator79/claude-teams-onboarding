# Kontext: mas pristup k Microsoft 365 uctu uzivatele

V teto slozce je nastroj `graph.py`, ktery je uz PRIHLASENY do uzivatelova
Microsoft 365 uctu (token v `tokens.json`). Kdyz te uzivatel pozada o neco
ohledne jeho posty, kalendare, souboru nebo Teams zprav, POUZIJ ho pres Bash.
Neptej se na prihlaseni - uz prihlaseny jsi.

Priklady (spoustej z teto slozky, nebo pres plnou cestu):

- "podivej se mi do mailu" / "mam neco noveho?"
    python3 graph.py mail 10
- "posli mail na adresa@firma.cz, predmet ..., text ..."
    python3 graph.py send-mail "adresa@firma.cz" "Predmet" "Text zpravy"
- "co mam dnes / tento tyden v kalendari"
    python3 graph.py calendar 10
- "ukaz moje Teams chaty" (jen cteni)
    python3 graph.py chats 20
- "precti zpravy z chatu <id>"
    python3 graph.py messages <chatId> 20
- "co mam na OneDrive" (volitelne cesta, napr. /Dokumenty)
    python3 graph.py files /
- kdo jsem / na jaky ucet jsem prihlaseny
    python3 graph.py whoami
- cokoliv jineho z Microsoft Graphu (obecne volani):
    python3 graph.py GET "/me/messages?$top=5&$select=subject,from"

Vystup je JSON ve tvaru {"status": <kod>, "data": {...}}. Precti ho a odpovez
uzivateli LIDSKY, cesky a strucne. Surovy JSON nevypisuj, pokud o to vylozene
nepozada.

## Hranice (dulezite)

- Smis pracovat JEN v ramci JEHO uctu - jeho posta, kalendar, soubory, chaty.
  Nikdy nemenis nastaveni firmy ani prava jinych lidi.
- U CTENI (precti mail, ukaz kalendar) se neptej, rovnou to udelej.
- Pred AKCI, ktera neco posila nebo meni navenek (odeslani mailu, vytvoreni
  udalosti), kratce rekni, co se chystas udelat.
