import json
import requests
from datetime import datetime
import os
import traceback

PETS_URL = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL = "https://ps99.biggamesapi.io/api/rap"

OUTPUT_FILE = "Server/ITEMS_DATA.json"
WEBHOOK_URL = "https://discord.com/api/webhooks/XXXXXXXX"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 30000000


def send_discord(msg):
    try:
        requests.post(WEBHOOK_URL, json={"content": msg}, timeout=10)
    except:
        pass


def fetch(url):
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        return r.json().get("data", [])
    except:
        send_discord("FAILED TO RECEIVE API DATA")
        return None


def build():
    pets = fetch(PETS_URL)
    rap = fetch(RAP_URL)

    if not pets or not rap:
        return None

    lookup = {}

    for p in pets:
        if p.get("category") == "Huge":
            name = p.get("configName")
            thumb = p.get("configData", {}).get("thumbnail")
            if name and thumb:
                lookup[name] = thumb

    out = {}

    for r in rap:
        cfg = r.get("configData") or {}
        name = cfg.get("id")
        val = r.get("value", 0)

        thumb = lookup.get(name)
        if thumb and HUGE_MIN_VALUE <= val <= HUGE_MAX_VALUE:
            out[thumb] = val

    return out if out else None


def save(data):
    os.makedirs("Server", exist_ok=True)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))


def main():
    try:
        data = build()

        if data:
            save(data)
            send_discord(f"UPDATE OK | {len(data)} items")
        else:
            send_discord("NO DATA")

    except Exception:
        send_discord("FATAL ERROR")
        send_discord(traceback.format_exc()[:1500])


if __name__ == "__main__":
    main()