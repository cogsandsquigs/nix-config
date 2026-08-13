#!/usr/bin/env python3
"""Print the session id from a claude -p json result, which is now a list of events, not one dict."""
import json
import sys

try:
    d = json.load(open(sys.argv[1]))
    d = d[-1] if isinstance(d, list) else d
    print(d.get("session_id", ""))
except Exception:
    print("")
