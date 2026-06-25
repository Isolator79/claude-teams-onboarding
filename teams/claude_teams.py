#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  Most mezi Microsoft Teams a Claude Code.
# ------------------------------------------------------------
#  Co to dela:
#   - login : prihlasi te do tveho M365 / Teams uctu (bidli.cz)
#             pres "device code" (zkopirujes kod do prohlizece).
#   - run   : pak hlida v Teams skupinovy chat s nazvem "Claude"
#             (jen ty v nem). Co tam napises, preda Claude Code
#             a odpoved napise zpatky do chatu (s prefixem robota).
#
#  Genericke: zadne jmeno ani tenant nejsou natvrdo. Funguje
#  pro libovolny ucet na tenantu bidli.cz - prihlasis se SAM.
#  Bezpecne poustet opakovane (idempotentni).
# ============================================================

import json, os, sys, time, subprocess, uuid
import urllib.request, urllib.parse, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))

# Verejny first-party klient "Microsoft Graph Command Line Tools"
# (podporuje device-code prihlaseni). Neni to tajemstvi, je stejny pro vsechny.
CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
AUTHORITY = "https://login.microsoftonline.com/organizations"

# O co si rikame. Pro Teams staci chat; pridavame i mail/kalendar/soubory,
# aby pozdeji Claude umel pres Teams i tyto veci. Plosny souhlas uz je udeleny,
# takze prihlaseni neukaze zadnou obrazovku se souhlasem.
SCOPE = ("offline_access User.Read "
         "Chat.ReadWrite ChatMessage.Send "
         "Mail.ReadWrite Mail.Send Calendars.ReadWrite Files.ReadWrite.All")

GRAPH = "https://graph.microsoft.com/v1.0"
TOKENS = os.path.join(HERE, "tokens.json")
STATE  = os.path.join(HERE, "state.json")

CHAT_TOPIC  = "Claude"          # nazev skupinoveho chatu, ktery hlidame
BOT_PREFIX  = "\U0001F916 "      # robot emoji + mezera = znacka "tohle psal Claude"
POLL_SECONDS = 4                 # jak casto se divat na nove zpravy


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
    print("=== Prihlaseni do Teams / M365 ===")
    print("")
    # Stage 1: vyzadej kod
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

    # Stage 2: cekej na prihlaseni
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
        print("[CHYBA] Nejsi prihlaseny. Spust nejdriv: login")
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
        print("[CHYBA] Obnova prihlaseni selhala. Spust znovu: login")
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


# ---------- chat "Claude" -----------------------------------------------

def me_id():
    st, d = api("GET", "/me?$select=id,displayName")
    if st != 200:
        print("[CHYBA] Nepodarilo se nacist tvuj ucet:", d)
        sys.exit(1)
    return d["id"], d.get("displayName", "")


def find_or_create_chat():
    """Najde existujici skupinovy chat s nazvem 'Claude', jinak ho vytvori.
    Idempotentni - pri opakovanem spusteni pouzije ten samy chat."""
    state = _load(STATE)
    if state.get("chat_id"):
        return state["chat_id"]

    # zkus najit existujici
    st, d = api("GET", "/me/chats?$select=id,chatType,topic&$top=50")
    if st == 200:
        for c in d.get("value", []):
            if c.get("chatType") == "group" and (c.get("topic") or "") == CHAT_TOPIC:
                state["chat_id"] = c["id"]
                _save(STATE, state)
                return c["id"]

    # nenalezen -> vytvor novy
    uid, _ = me_id()
    body = {
        "chatType": "group",
        "topic": CHAT_TOPIC,
        "members": [{
            "@odata.type": "#microsoft.graph.aadUserConversationMember",
            "roles": ["owner"],
            "user@odata.bind": "https://graph.microsoft.com/v1.0/users('%s')" % uid,
        }],
    }
    st, d = api("POST", "/chats", body)
    if st not in (200, 201):
        print("[CHYBA] Nepodarilo se vytvorit chat 'Claude':", d)
        sys.exit(1)
    state["chat_id"] = d["id"]
    _save(STATE, state)
    return d["id"]


def _chunks(s, n):
    # Teams ma limit na delku zpravy - dlouhy text rozsekame na kusy.
    s = str(s)
    if len(s) <= n:
        return [s]
    return [s[i:i + n] for i in range(0, len(s), n)]


def send(chat_id, text):
    """Posle zpravu do Teams chatu. Hlida chyby (drive je spolkl tise)
    a dlouhe zpravy posila po castech."""
    if text is None:
        return
    for ch in _chunks(text, 3500):
        if not ch.strip():
            continue
        st, d = api("POST", "/chats/%s/messages" % chat_id,
                    {"body": {"contentType": "text", "content": BOT_PREFIX + ch}})
        if st not in (200, 201):
            print("[POZOR] Zpravu se nepodarilo poslat do Teams (stav %s): %s" % (st, d))


def get_new_user_messages(chat_id, last_id):
    """Vrati nove zpravy od cloveka (ne od Claude, ne systemove),
    serazene od nejstarsi. last_id = id posledni zpracovane zpravy."""
    st, d = api("GET", "/chats/%s/messages?$top=20" % chat_id)
    if st != 200:
        return [], last_id
    msgs = d.get("value", [])
    # Graph vraci od nejnovejsi - otocime na chronologicke poradi
    msgs = list(reversed(msgs))
    out = []
    newest = last_id
    for m in msgs:
        mid = m.get("id")
        if m.get("messageType") != "message":
            continue
        content = ((m.get("body") or {}).get("content") or "")
        # preskoc zpravy od Claude (zacinaji znackou robota)
        if content.startswith(BOT_PREFIX.strip()):
            newest = mid
            continue
        # zpracuj jen zpravy novejsi nez posledni videna
        if last_id is None:
            # prvni beh: nastav zarazku na nejnovejsi, nic zpetne neresime
            newest = mid
            continue
        if str(mid) > str(last_id):
            out.append((mid, _strip_html(content)))
            newest = mid
    return out, newest


def _strip_html(s):
    # zpravy z Teams byvaji v HTML (<p>...</p>) - hrubo ocistime
    import re
    s = re.sub(r"<[^>]+>", " ", s)
    s = (s.replace("&nbsp;", " ").replace("&amp;", "&")
           .replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"'))
    return " ".join(s.split()).strip()


# ---------- Claude Code -------------------------------------------------

def _tool_note(name, inp):
    """Z volani nastroje udela kratkou lidskou hlasku do Teams,
    aby uzivatel videl, co Claude prave dela (jako v session)."""
    name = name or "nastroj"
    inp = inp or {}
    if name == "Bash":
        detail = inp.get("command", "")
    elif name in ("Read", "Edit", "Write", "NotebookEdit"):
        detail = inp.get("file_path", "")
    elif name in ("Grep", "Glob"):
        detail = inp.get("pattern", "")
    elif name in ("WebFetch", "WebSearch"):
        detail = inp.get("url", inp.get("query", ""))
    else:
        try:
            detail = json.dumps(inp, ensure_ascii=False)
        except Exception:
            detail = str(inp)
    detail = " ".join(str(detail).split())
    if len(detail) > 200:
        detail = detail[:200] + "..."
    return ("[ %s ] %s" % (name, detail)).strip()


def ask_claude_stream(text, session_id, first, chat_id):
    """Spusti Claude Code v rezimu streamu a kazdy krok (muj text i volani
    nastroju) prubezne posila do Teams - aby to bylo jako ziva session.
    Bezi s pristupem k nastrojum (vc. graph.py na M365) v teto slozce."""
    claude = _find_claude()
    if not claude:
        send(chat_id, "[Nemohu najit program 'claude'. Je Claude Code nainstalovany? Viz KROK 01.]")
        return
    base = [claude, "-p", "--output-format", "stream-json", "--verbose",
            "--permission-mode", "bypassPermissions"]
    if first:
        cmd = base + ["--session-id", session_id, text]
    else:
        cmd = base + ["--resume", session_id, text]
    try:
        # cwd=HERE -> Claude nacte CLAUDE.md v teto slozce a vidi graph.py.
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             text=True, cwd=HERE, bufsize=1)
    except Exception as e:
        send(chat_id, "[Chyba pri spousteni Claude: %s]" % e)
        return

    sent_any = False
    final = None
    try:
        for line in p.stdout:
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
            except Exception:
                continue
            t = ev.get("type")
            if t == "assistant":
                for block in (ev.get("message") or {}).get("content", []):
                    bt = block.get("type")
                    if bt == "text":
                        tx = (block.get("text") or "").strip()
                        if tx:
                            send(chat_id, tx)
                            sent_any = True
                    elif bt == "tool_use":
                        send(chat_id, _tool_note(block.get("name"), block.get("input")))
                        sent_any = True
            elif t == "result":
                final = (ev.get("result") or "").strip()
        try:
            p.wait(timeout=600)
        except Exception:
            p.kill()
    except Exception as e:
        send(chat_id, "[Chyba pri cteni odpovedi: %s]" % e)

    # Kdyby stream nic neposlal (napr. jen vysledek), posli aspon finalni text.
    if not sent_any:
        send(chat_id, final or "[Claude nevratil zadnou odpoved.]")


def _find_claude():
    from shutil import which
    p = which("claude")
    if p:
        return p
    for cand in [os.path.expanduser("~/.local/bin/claude"),
                 os.path.expanduser("~/.claude/bin/claude")]:
        if os.path.exists(cand):
            return cand
    return None


# ---------- hlavni smycka -----------------------------------------------

def run():
    chat_id = find_or_create_chat()
    state = _load(STATE)
    last_id = state.get("last_id")
    session_id = state.get("session_id")
    if not session_id:
        session_id = str(uuid.uuid4())
        state["session_id"] = session_id
        _save(STATE, state)
    first = not state.get("session_started")

    _, name = me_id()
    print("")
    print("=== Claude je pripojeny k Teams ===")
    print("Ucet:   ", name)
    print("Chat:   ", CHAT_TOPIC, "(najdes ho v Teams jako skupinovy chat jen s tebou)")
    print("")
    print("Napis si do toho chatu cokoliv - Claude ti odpovi a uvidis i prubeh.")
    print("Umi i tvuj mail, kalendar, OneDrive a Teams zpravy (staci poprosit).")
    print("Pokud most bezi jako sluzba na pozadi, muzes toto okno zavrit.")
    print("")

    # uvitaci zprava pri kazdem startu mostu (ne casteji nez po 5 minutach,
    # aby pripadny restart sluzby nezahltil chat)
    now = int(time.time())
    if now - state.get("last_welcome", 0) > 300:
        send(chat_id, "Ahoj, jsem online a napojeny na tvuj Teams. "
                      "Napis mi sem prompt - uvidis i prubeh prace. "
                      "Umim i tvuj mail, kalendar, OneDrive a Teams zpravy, staci rict.")
        state["last_welcome"] = now
        _save(STATE, state)

    while True:
        try:
            msgs, newest = get_new_user_messages(chat_id, last_id)
            if newest != last_id:
                last_id = newest
                state["last_id"] = last_id
                _save(STATE, state)
            for mid, text in msgs:
                if not text:
                    continue
                print("[ty]", text)
                send(chat_id, "Pracuji na tom...")
                ask_claude_stream(text, session_id, first, chat_id)
                first = False
                state["session_started"] = True
                _save(STATE, state)
                print("[claude] (prubeh i odpoved odeslany do Teams)")
            time.sleep(POLL_SECONDS)
        except KeyboardInterrupt:
            print("\nUkonceno.")
            return
        except Exception as e:
            print("[POZOR] docasna chyba:", e)
            time.sleep(POLL_SECONDS)


# ---------- vstupni bod -------------------------------------------------

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "login":
        login()
    elif cmd == "run":
        run()
    else:
        print("Pouziti: python3 claude_teams.py [login|run]")
        sys.exit(1)
