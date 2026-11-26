#!/usr/bin/env python3
"""Thin client for the TickTick Open API (https://developer.ticktick.com/docs/index.html).

    ticktick.py GET project                        # list projects
    ticktick.py GET project/<id>/data              # a project with its open tasks
    ticktick.py POST task '{"title": "hello"}'     # JSON body as an argument
    ticktick.py POST task/filter - < body.json     # ...or "-" to read it from stdin

Paths are relative to /open/v1/ unless they start with "/". The token comes
from $TICKTICK_API_TOKEN (set in ~/.environment-specifics.zshrc) and is created
in the web app: avatar -> Settings -> Account -> API Token.

Stdlib only, so it runs on the system python3 with nothing installed.
"""

import json
import os
import sys
import urllib.error
import urllib.request

HOST = "https://api.ticktick.com"


def main():
    if len(sys.argv) not in (3, 4) or sys.argv[1] in ("-h", "--help"):
        sys.exit(__doc__)

    token = os.environ.get("TICKTICK_API_TOKEN")
    if not token:
        sys.exit(
            "TICKTICK_API_TOKEN is not set. Create one in the TickTick web app "
            "(avatar -> Settings -> Account -> API Token) and add it to "
            "~/.environment-specifics.zshrc."
        )

    method, path = sys.argv[1].upper(), sys.argv[2]
    if not path.startswith("/"):
        path = "/open/v1/" + path

    body = None
    if len(sys.argv) == 4:
        raw = sys.stdin.read() if sys.argv[3] == "-" else sys.argv[3]
        try:
            body = json.dumps(json.loads(raw)).encode()
        except ValueError as e:
            sys.exit(f"request body is not valid JSON: {e}")

    req = urllib.request.Request(HOST + path, data=body, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    if body is not None:
        req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            text = resp.read().decode()
    except urllib.error.HTTPError as e:
        # A 401 body echoes the rejected token back; keep it out of the terminal.
        detail = e.read().decode().replace(token, "<token>")
        sys.exit(f"{method} {path} -> HTTP {e.code} {e.reason}\n{detail}")
    except urllib.error.URLError as e:
        sys.exit(f"{method} {path} -> {e.reason}")

    try:
        print(json.dumps(json.loads(text), indent=2, ensure_ascii=False))
    except ValueError:
        # Several write endpoints return an empty body on success.
        print(text)


if __name__ == "__main__":
    main()
