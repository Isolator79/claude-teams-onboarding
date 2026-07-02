#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  graph.py - tenky klient na Microsoft Graph (M365) pro Claude.
# ------------------------------------------------------------
#  Prihlaseni (tokens.json) resi m365_auth.py. Kdyz uz jsi
#  prihlaseny (KROK M365 login), funguje to hned - bez dalsiho
#  prihlasovani.
#
#  Claude tenhle nastroj vola SAM, kdyz ho o neco poprosis
#  ("podivej se mi do mailu", "co mam dnes v kalendari", ...).
#
#  Pouziti z prikazove radky:
#    python3 graph.py whoami
#    python3 graph.py mail [N]                 - poslednich N mailu
#    python3 graph.py send-mail <komu> <predmet> <text>
#    python3 graph.py calendar [N]             - nadchazejici udalosti
#    python3 graph.py chats [N]                - tve Teams chaty (cteni)
#    python3 graph.py messages <chatId> [N]    - zpravy z chatu (cteni)
#    python3 graph.py files [cesta]            - OneDrive (vychozi koren)
#  Obecne volani Graphu (cokoliv dalsiho):
#    python3 graph.py GET  "/me/messages?$top=5&$select=subject,from"
#    python3 graph.py POST /me/sendMail '{...}'
#    (metody: GET POST PATCH PUT DELETE; 3. argument = telo jako JSON)
# ============================================================

import sys, json
import m365_auth as ct

USAGE = __doc__


def _out(st, d):
    print(json.dumps({"status": st, "data": d}, ensure_ascii=False, indent=2))
    return 0 if (st and st < 400) else 1


def cmd_raw(method, path, body=None):
    st, d = ct.api(method, path, body)
    return _out(st, d)


def cmd_whoami():
    st, d = ct.api("GET", "/me?$select=displayName,mail,userPrincipalName,jobTitle")
    return _out(st, d)


def cmd_mail(n):
    path = ("/me/messages?$top=%d&$select=subject,from,receivedDateTime,"
            "bodyPreview,isRead&$orderby=receivedDateTime desc" % n)
    st, d = ct.api("GET", path)
    return _out(st, d)


def cmd_send_mail(to, subject, text):
    body = {"message": {"subject": subject,
                        "body": {"contentType": "Text", "content": text},
                        "toRecipients": [{"emailAddress": {"address": to}}]},
            "saveToSentItems": True}
    st, d = ct.api("POST", "/me/sendMail", body)
    return _out(st, d if d else {"sent": True})


def cmd_calendar(n):
    path = ("/me/events?$top=%d&$select=subject,start,end,location,organizer"
            "&$orderby=start/dateTime" % n)
    st, d = ct.api("GET", path)
    return _out(st, d)


def cmd_chats(n):
    path = ("/me/chats?$top=%d&$select=id,topic,chatType,lastUpdatedDateTime"
            "&$orderby=lastUpdatedDateTime desc" % n)
    st, d = ct.api("GET", path)
    return _out(st, d)


def cmd_messages(chat_id, n):
    st, d = ct.api("GET", "/chats/%s/messages?$top=%d" % (chat_id, n))
    return _out(st, d)


def cmd_files(path):
    if path and path not in ("/", ""):
        url = "/me/drive/root:%s:/children?$select=name,size,folder,file,webUrl" % path
    else:
        url = "/me/drive/root/children?$select=name,size,folder,file,webUrl"
    st, d = ct.api("GET", url)
    return _out(st, d)


def main(a):
    if not a:
        print(USAGE)
        return 1
    c = a[0]
    try:
        if c in ("GET", "POST", "PATCH", "PUT", "DELETE"):
            body = json.loads(a[2]) if len(a) > 2 else None
            return cmd_raw(c, a[1], body)
        if c == "whoami":
            return cmd_whoami()
        if c == "mail":
            return cmd_mail(int(a[1]) if len(a) > 1 else 10)
        if c == "send-mail":
            return cmd_send_mail(a[1], a[2], a[3])
        if c == "calendar":
            return cmd_calendar(int(a[1]) if len(a) > 1 else 10)
        if c == "chats":
            return cmd_chats(int(a[1]) if len(a) > 1 else 20)
        if c == "messages":
            return cmd_messages(a[1], int(a[2]) if len(a) > 2 else 20)
        if c == "files":
            return cmd_files(a[1] if len(a) > 1 else "/")
        print(USAGE)
        return 1
    except IndexError:
        print("[CHYBA] Chybi argument.")
        print(USAGE)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
