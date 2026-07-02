#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  m365_auth.py - prihlaseni a volani Microsoft 365 (Graph).
# ------------------------------------------------------------
#  Cisté auth jadro (device-code login + obnova tokenu + api()).
#  Zadny "most do Teams" - Claude tenhle modul pouziva jen jako
#  knihovnu (viz graph.py). Token se uklada do tokens.json vedle
#  tohoto souboru.
#
#  Pouziti z prikazove radky:
#    python3 m365_auth.py login     - prvni prihlaseni (device code)
#    python3 m365_auth.py whoami    - na jaky ucet jsem prihlaseny
# ============================================================

import json, os, sys, time
import urllib.request, urllib.parse, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))

# Verejny first-party klient "Microsoft Graph Command Line Tools"
# (podporuje device-code prihlaseni). Neni to tajemstvi, je stejny pro vsechny.
CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
AUTHORITY = "https://login.microsoftonline.com/organizations"

# O co si rikame: cteni profilu, posta, kalendar, soubory (OneDrive/SharePoint)
# a cteni Teams chatu. Plosny admin souhlas uz je udeleny, takze prihlaseni
# neukaze zadnou obrazovku se souhlasem.
SCOPE = ("offline_access User.Read "
         "Chat.ReadWrite ChatMessage.Send "
         "ChannelMessage.Send Channel.ReadBasic.All Team.ReadBasic.All "
         "Mail.ReadWrite Mail.Send Calendars.ReadWrite Files.ReadWrite.All")

GRAPH  = "https://graph.microsoft.com/v1.0"
TOKENS = os.path.join(HERE, "tokens.json")


# ---------- drobne HTTP helpery -----------------------------------------

def _http(method, url, data=None, headers=None, form=False):
    if form:
        body = urllib.parse.urlencode(data).encode()
    else:
        body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, method=method)
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    if body and not form:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode()
            return r.status, (json.loads(txt) if txt else {})
    except urllib.error.HTTPError as e:
        txt = e.read().decode()
        try:
            return e.code, json.loads(txt)
        except Exception:
            return e.code, {"raw": txt}


def _load(path, default=None):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return default if default is not None else {}


def _save(path, obj):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)
    try:
        os.chmod(path, 0o600)
    except Exception:
        pass


# ---------- prihlaseni (device code) ------------------------------------

def login():
    print("")
    print("=== Prihlaseni do Microsoft 365 ===")
    print("")
    st, dc = _http("POST", AUTHORITY + "/oauth2/v2.0/devicecode",
                   {"client_id": CLIENT_ID, "scope": SCOPE}, form=True)
    if st != 200:
        print("[CHYBA] Nepodarilo se zacit prihlaseni:", dc)
        sys.exit(1)

    print("--------------------------------------------------------")
    print(" 1) Otevri v prohlizeci tuto adresu:")
    print("       ", dc.get("verification_uri"))
    print("")
    print(" 2) Zadej tento kod:")
    print("       ", dc.get("user_code"))
    print("")
    print(" 3) Prihlas se svym pracovnim uctem (tvuj-email@bidli.cz).")
    print("--------------------------------------------------------")
    print("")
    print("Cekam, az se prihlasis...")

    interval = int(dc.get("interval", 5))
    deadline = time.time() + int(dc.get("expires_in", 900))
    while time.time() < deadline:
        time.sleep(interval)
        st, tok = _http("POST", AUTHORITY + "/oauth2/v2.0/token", {
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            "client_id": CLIENT_ID,
            "device_code": dc["device_code"],
        }, form=True)
        if st == 200:
            tok["obtained_at"] = int(time.time())
            _save(TOKENS, tok)
            print("")
            print("[OK] Prihlaseno. Hotovo.")
            return
        err = tok.get("error")
        if err == "authorization_pending":
            continue
        if err == "slow_down":
            interval += 5
            continue
        print("[CHYBA] Prihlaseni se nezdarilo:", tok.get("error_description", err))
        sys.exit(2)
    print("[CHYBA] Kod vyprsel. Spust prihlaseni znovu.")
    sys.exit(3)


def access_token():
    t = _load(TOKENS)
    if not t:
        print("[CHYBA] Nejsi prihlaseny. Spust nejdriv:  python3 m365_auth.py login")
        sys.exit(1)
    if time.time() < t.get("obtained_at", 0) + t.get("expires_in", 0) - 120:
        return t["access_token"]
    # obnova tokenu
    st, nt = _http("POST", AUTHORITY + "/oauth2/v2.0/token", {
        "grant_type": "refresh_token",
        "client_id": CLIENT_ID,
        "refresh_token": t["refresh_token"],
        "scope": SCOPE,
    }, form=True)
    if st != 200:
        print("[CHYBA] Obnova prihlaseni selhala. Spust znovu:  python3 m365_auth.py login")
        print("       ", nt.get("error_description", nt))
        sys.exit(1)
    nt.setdefault("refresh_token", t["refresh_token"])
    nt["obtained_at"] = int(time.time())
    _save(TOKENS, nt)
    return nt["access_token"]


def api(method, path, body=None):
    # mezery v URL (napr. $orderby=... desc) musi byt zakodovane
    path = path.replace(" ", "%20")
    return _http(method, GRAPH + path, body,
                 headers={"Authorization": "Bearer " + access_token()})


def is_logged_in():
    return bool(_load(TOKENS))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "login":
        login()
    elif cmd == "whoami":
        st, d = api("GET", "/me?$select=displayName,mail,userPrincipalName")
        if st == 200:
            print("[OK] Prihlaseny jako:", d.get("displayName"),
                  "(" + str(d.get("mail") or d.get("userPrincipalName")) + ")")
        else:
            print("[CHYBA] Nepodarilo se overit prihlaseni:", d)
            sys.exit(1)
    else:
        print(__doc__)
        sys.exit(1)
