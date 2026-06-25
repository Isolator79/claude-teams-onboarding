#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  Most mezi Telegramem a Claude Code.
# ------------------------------------------------------------
#  Co to dela:
#   - setup : nastavi tvuj Telegram bot token (od @BotFather)
#             a spari ho s tvym chatem (napises botovi zpravu).
#   - run   : hlida zpravy od tebe v Telegramu. Co napises, preda
#             Claude Code a odpoved (vc. prubehu prace) posila zpet.
#
#  Vyhody proti Teams: bot ma vlastni identitu (od BotFather),
#  takze notifikace chodi normalne. Funguje za NATem (jen odchozi
#  spojeni, long-polling). Bezi v JINE, oddelene session nez Teams.
#  Bezpecne poustet opakovane (idempotentni).
# ============================================================

import json, os, sys, time, subprocess, uuid
import urllib.request, urllib.parse, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
TOKENS = os.path.join(HERE, "telegram_token.json")   # bot token (gitignored)
STATE  = os.path.join(HERE, "telegram_state.json")   # chat_id, offset, session (gitignored)

POLL_TIMEOUT = 25   # long-polling: jak dlouho Telegram drzi spojeni a ceka na zpravu


# ---------- drobne HTTP helpery -----------------------------------------

def _http(method, url, data=None, timeout=60):
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, method=method)
    if body:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
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


def _ask(prompt_text):
    """Precte jeden radek od uzivatele. Funguje i pri 'curl | bash':
    pokud je standardni vstup terminal (shell ho umi presmerovat z /dev/tty),
    cte se odtud; jinak se sahne primo na controlling terminal /dev/tty.
    Nikdy nevyhazuje vyjimku - kdyz nic nedostane, vrati prazdny retezec."""
    sys.stdout.write(prompt_text)
    sys.stdout.flush()
    # 1) standardni vstup, pokud je to terminal (napr. 'setup </dev/tty')
    try:
        if sys.stdin is not None and sys.stdin.isatty():
            line = sys.stdin.readline()
            if line:
                return line.strip()
    except Exception:
        pass
    # 2) nouzovka: primo controlling terminal
    try:
        with open("/dev/tty") as tty:
            return (tty.readline() or "").strip()
    except Exception:
        return ""


# ---------- Telegram API ------------------------------------------------

def _token():
    t = _load(TOKENS)
    tok = t.get("token") if t else None
    if not tok:
        print("[CHYBA] Chybi bot token. Spust nejdriv: setup")
        sys.exit(1)
    return tok


def tg(method, params=None, timeout=60):
    url = "https://api.telegram.org/bot%s/%s" % (_token(), method)
    return _http("POST", url, params or {}, timeout=timeout)


def send(chat_id, text):
    """Posle zpravu do Telegramu. Dlouhy text posila po castech (limit 4096)."""
    if text is None:
        return
    for ch in _chunks(text, 3500):
        if not ch.strip():
            continue
        st, d = tg("sendMessage", {"chat_id": chat_id, "text": ch})
        if st != 200:
            print("[POZOR] Telegram odmitl zpravu (stav %s): %s" % (st, d))


def _chunks(s, n):
    s = str(s)
    if len(s) <= n:
        return [s]
    return [s[i:i + n] for i in range(0, len(s), n)]


# ---------- nastaveni (token + sparovani s chatem) ----------------------

def setup():
    print("")
    print("=== Nastaveni Telegram bota ===")
    print("")
    print("Jak ziskat token (jednou):")
    print("  1) V Telegramu najdi @BotFather a napis /newbot")
    print("  2) Zvol jmeno a username bota")
    print("  3) BotFather ti vypise TOKEN (neco jako 123456789:ABC...)")
    print("")
    print("POZOR: pokud uz nejakeho Telegram bota mas a pouzivas ho jinde,")
    print("vytvor si pro tohle NOVEHO bota (vlastni token). Dva ruzne programy")
    print("nemohou cist zpravy stejneho bota najednou - tlouklo by se to.")
    print("")
    token = sys.argv[2].strip() if len(sys.argv) > 2 else ""
    if not token:
        token = _ask("Vloz sem token od @BotFather: ")
    if not token:
        print("[CHYBA] Nedostal jsem zadny token. Spust prikaz znovu a token vloz,")
        print("        pripadne ho predej rovnou: setup <token>")
        sys.exit(1)

    _save(TOKENS, {"token": token})
    st, me = tg("getMe")
    if st != 200 or not me.get("ok"):
        print("[CHYBA] Token nefunguje:", me)
        sys.exit(1)
    uname = me["result"].get("username", "?")
    curname = me["result"].get("first_name", "") or uname
    print("[OK] Bot funguje: @%s (zobrazuje se jako: %s)" % (uname, curname))
    print("")

    # Volitelne: pod jakym jmenem se bot zobrazuje v Telegramu (Bot API setMyName).
    # Hodi se, kdyz uz mas jineho bota a chces je od sebe rozlisit.
    if len(sys.argv) > 3:
        newname = sys.argv[3].strip()
    else:
        newname = _ask("Pod jakym jmenem se ma bot zobrazovat? "
                       "(Enter = nechat '%s'): " % curname)
    if newname:
        st2, r2 = tg("setMyName", {"name": newname})
        if st2 == 200 and r2.get("ok"):
            print("[OK] Jmeno bota nastaveno na: %s" % newname)
        else:
            print("[POZOR] Jmeno se nepodarilo zmenit (stav %s): %s" % (st2, r2))
        print("")

    print("Ted otevri Telegram, najdi sveho bota  @%s  a napis mu cokoliv" % uname)
    print("(napr. /start nebo 'ahoj'). Cekam na tvou prvni zpravu...")

    state = _load(STATE)
    offset = state.get("offset", 0)
    deadline = time.time() + 300
    while time.time() < deadline:
        st, d = tg("getUpdates", {"offset": offset, "timeout": 20}, timeout=30)
        if st == 200 and d.get("ok"):
            for u in d["result"]:
                offset = u["update_id"] + 1
                msg = u.get("message") or u.get("edited_message")
                chat = (msg or {}).get("chat") if msg else None
                if chat and chat.get("id") is not None:
                    state["chat_id"] = chat["id"]
                    state["offset"] = offset
                    _save(STATE, state)
                    print("")
                    print("[OK] Spojeno s tvym chatem. Hotovo.")
                    send(chat["id"], "Hotovo, jsem napojeny. Napis mi prompt a uvidis i prubeh prace.")
                    return
        time.sleep(1)
    print("[CHYBA] Nedosla zadna zprava. Spust setup znovu a napis svemu botovi.")
    sys.exit(1)


# ---------- Claude Code (stream do Telegramu) ---------------------------

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


def _tool_note(name, inp):
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
    """Spusti Claude Code v rezimu streamu a prubezne posila do Telegramu
    text i volani nastroju - jako ziva session. Bezi s pristupem k nastrojum
    (cwd=tato slozka, takze nacte CLAUDE.md)."""
    claude = _find_claude()
    if not claude:
        send(chat_id, "[Nemohu najit program 'claude'. Je Claude Code nainstalovany? Viz KROK 01.]")
        return
    base = [claude, "-p", "--output-format", "stream-json", "--verbose",
            "--permission-mode", "bypassPermissions"]
    cmd = base + (["--session-id", session_id, text] if first
                  else ["--resume", session_id, text])
    try:
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

    if not sent_any:
        send(chat_id, final or "[Claude nevratil zadnou odpoved.]")


# ---------- hlavni smycka -----------------------------------------------

def run():
    state = _load(STATE)
    chat_id = state.get("chat_id")
    if chat_id is None:
        print("[CHYBA] Neni sparovany chat. Spust nejdriv: setup")
        sys.exit(1)

    session_id = state.get("session_id") or str(uuid.uuid4())
    state["session_id"] = session_id
    _save(STATE, state)
    first = not state.get("session_started")
    offset = state.get("offset", 0)

    print("")
    print("=== Claude je pripojeny k Telegramu ===")
    print("Pis svemu botovi v Telegramu - Claude ti odpovi a uvidis i prubeh.")
    print("Pokud most bezi jako sluzba na pozadi, muzes toto okno zavrit.")
    print("")

    now = int(time.time())
    if now - state.get("last_welcome", 0) > 300:
        send(chat_id, "Ahoj, jsem online. Napis mi prompt - uvidis i prubeh prace.")
        state["last_welcome"] = now
        _save(STATE, state)

    while True:
        try:
            st, d = tg("getUpdates", {"offset": offset, "timeout": POLL_TIMEOUT},
                       timeout=POLL_TIMEOUT + 10)
            if st == 200 and d.get("ok"):
                for u in d["result"]:
                    offset = u["update_id"] + 1
                    state["offset"] = offset
                    _save(STATE, state)
                    msg = u.get("message")
                    if not msg:
                        continue
                    if str((msg.get("chat") or {}).get("id")) != str(chat_id):
                        continue
                    text = (msg.get("text") or "").strip()
                    if not text:
                        continue
                    print("[ty]", text)
                    send(chat_id, "Pracuji na tom...")
                    ask_claude_stream(text, session_id, first, chat_id)
                    first = False
                    state["session_started"] = True
                    _save(STATE, state)
                    print("[claude] (prubeh i odpoved odeslany do Telegramu)")
            else:
                time.sleep(3)
        except KeyboardInterrupt:
            print("\nUkonceno.")
            return
        except Exception as e:
            print("[POZOR] docasna chyba:", e)
            time.sleep(3)


# ---------- vstupni bod -------------------------------------------------

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "setup":
        setup()
    elif cmd == "run":
        run()
    else:
        print("Pouziti: python3 telegram_claude.py [setup|run]")
        sys.exit(1)
