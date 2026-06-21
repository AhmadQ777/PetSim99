import json
import requests
from datetime import datetime
from zoneinfo import ZoneInfo
import os
import traceback

PETS_URL = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL = "https://ps99.biggamesapi.io/api/rap"

OUTPUT_FILE = "Server/ITEMS_DATA.json"
WEBHOOK_URL = "https://discord.com/api/webhooks/XXXXXXXX"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 30_000_000


def now_de():
    return datetime.now(ZoneInfo("Europe/Berlin")).strftime("%Y-%m-%d %H:%M:%S")


def send_discord(msg):
    try:
        requests.post(WEBHOOK_URL, json={"content": msg}, timeout=10)
    except Exception:
        pass


def fetch(url, name):
    for attempt in range(5):
        try:
            r = requests.get(url, timeout=10)
            r.raise_for_status()
            return r.json().get("data", [])
        except Exception:
            time.sleep(2 * (attempt + 1))

    send_discord(f"API FAILED AFTER 5 TRIES: {name} | {now_de()}")
    return None


def build():
    pets = fetch(PETS_URL, "PETS")
    rap = fetch(RAP_URL, "RAP")

    if pets is None or rap is None:
        send_discord(f"FEHLER: API nicht erreichbar | {now_de()}")
        return None

    lookup = {}

    for p in pets:
        if p.get("category") == "Huge":
            name = p.get("configName")
            thumb = p.get("configData", {}).get("thumbnail")
            if name and thumb:
                lookup[name] = thumb

    out = {}

    for entry in rap:
        name = entry.get("configName")
        val = entry.get("value", 0)

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
            send_discord(f"UPDATE OK | {len(data)} Items | {now_de()}")
        else:
            send_discord(f"KEINE DATEN | Huge-Pets nicht gefunden | {now_de()}")

    except Exception:
        send_discord(f"FATALER FEHLER | {now_de()}")
        send_discord(traceback.format_exc()[:1500])


if __name__ == "__main__":
    main()