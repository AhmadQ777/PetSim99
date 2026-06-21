import json
import requests
from datetime import datetime
import os
import traceback

PETS_URL  = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL   = "https://ps99.biggamesapi.io/api/rap"
OUTPUT_FILE = "Server/ITEMS_DATA.json"
WEBHOOK_URL = "https://discord.com/api/webhooks/1518233664771588307/pbbS7bP6GRvczqDjs-fzhjRVuTabzOaohnnffrpjWApjuInrqsFCcHgIx72TPvubH36X"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 30_000_000


def send_discord(msg):
    try:
        requests.post(WEBHOOK_URL, json={"content": msg}, timeout=10)
    except Exception:
        pass


def fetch(url):
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        return r.json().get("data", [])
    except Exception:
        return None  # None = Fehler, [] = leere aber gültige Antwort


def build():
    pets = fetch(PETS_URL)
    rap  = fetch(RAP_URL)

    if pets is None or rap is None:
        send_discord("FEHLER: API nicht erreichbar")
        return None

    # Thumbnail-Lookup aus Pets-API aufbauen
    lookup = {}
    for p in pets:
        if p.get("category") == "Huge":
            name  = p.get("configName")
            thumb = p.get("configData", {}).get("thumbnail")
            if name and thumb:
                lookup[name] = thumb

    out = {}
    for entry in rap:
        # configName liegt im root-Objekt, NICHT in configData
        name = entry.get("configName")
        val  = entry.get("value", 0)
        pt   = (entry.get("configData") or {}).get("pt", 1)

        # Nur Huge-Pets mit Thumbnail und im Werte-Bereich
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
            send_discord(f"UPDATE OK | {len(data)} Items | {datetime.utcnow().strftime('%H:%M UTC')}")
        else:
            send_discord("KEINE DATEN | Huge-Pets nicht gefunden")
    except Exception:
        send_discord("FATALER FEHLER")
        send_discord(traceback.format_exc()[:1500])


if __name__ == "__main__":
    main()
