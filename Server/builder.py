import json
import requests
import os

# =====================
# CONFIG
# =====================

PETS_URL = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL  = "https://ps99.biggamesapi.io/api/rap"

OUTPUT_FILE = "Server/ITEMS_DATA.json"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 30_000_000


# =====================
# FETCH
# =====================

def fetch(url):
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        return r.json().get("data", [])
    except:
        return None


# =====================
# BUILD / MERGE
# =====================

def build():
    pets = fetch(PETS_URL)
    rap  = fetch(RAP_URL)

    if pets is None or rap is None:
        return None

    lookup = {}

    for p in pets:
        if str(p.get("category", "")).lower() != "huge":
            continue

        name = (p.get("configName") or "").strip().lower()
        thumb = (p.get("configData") or {}).get("thumbnail")

        if name and thumb:
            lookup[name] = thumb

    out = {}

    for r in rap:
        name = ((r.get("configData") or {}).get("id") or "").strip().lower()
        value = r.get("value", 0)

        thumb = lookup.get(name)

        if thumb and HUGE_MIN_VALUE <= value <= HUGE_MAX_VALUE:
            out[thumb] = value

    return out


# =====================
# SAVE
# =====================

def save(data):
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))


# =====================
# RUN
# =====================

def main():
    data = build()

    if data:
        save(data)


if __name__ == "__main__":
    main()