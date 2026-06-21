import json
import os
import time
import requests
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

# =====================
# CONFIG
# =====================

PETS_URL = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL  = "https://ps99.biggamesapi.io/api/rap"

OUTPUT_FILE = "/storage/emulated/0/Delta/Workspace/PETS_DATA.json"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 35_000_000

MAX_AGE_SECONDS = 14 * 24 * 60 * 60

REQUEST_TIMEOUT = 10
MAX_RETRIES = 2

HEADERS = {
    "User-Agent": "PS99-Local-Updater/1.0"
}

SESSION = requests.Session()


# =====================
# FETCH
# =====================

def fetch(url):
    for attempt in range(MAX_RETRIES):
        try:
            r = SESSION.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT)
            r.raise_for_status()

            data = r.json().get("data")
            if isinstance(data, list):
                return data

        except:
            pass

        if attempt + 1 < MAX_RETRIES:
            time.sleep(1)

    return None


# =====================
# BUILD
# =====================

def build():
    # 🔥 2x faster API load (parallel requests)
    with ThreadPoolExecutor() as ex:
        pets, rap = list(ex.map(fetch, [PETS_URL, RAP_URL]))

    if pets is None or rap is None:
        return None

    now = time.time()

    lookup = {}
    seen = set()  # 🔥 anti duplicate

    # =====================
    # PETS
    # =====================

    for pet in pets:
        if pet.get("category") != "Huge":
            continue

        # 🔥 tradable filter (safe fallback)
        config = pet.get("configData") or {}
        if config.get("tradable") is False or config.get("tradeable") is False:
            continue

        date_str = pet.get("dateModified")
        if not date_str:
            continue

        try:
            pet_time = datetime.fromisoformat(date_str.replace("Z", "+00:00")).timestamp()
        except:
            continue

        if now - pet_time <= MAX_AGE_SECONDS:
            continue

        name = pet.get("configName")
        thumbnail = config.get("thumbnail")

        if not isinstance(name, str) or not isinstance(thumbnail, str):
            continue

        if not thumbnail.startswith("rbxassetid://"):
            continue

        lookup[name.strip().lower()] = thumbnail

    # =====================
    # RAP
    # =====================

    output = {}

    for entry in rap:
        config = entry.get("configData") or {}

        pet_name = config.get("id")
        value = entry.get("value")

        if not isinstance(pet_name, str):
            continue

        if not isinstance(value, (int, float)):
            continue

        if not (HUGE_MIN_VALUE <= value <= HUGE_MAX_VALUE):
            continue

        thumb = lookup.get(pet_name.strip().lower())
        if not thumb:
            continue

        # 🔥 anti duplicate system
        if thumb in seen:
            continue

        seen.add(thumb)
        output[thumb] = int(value)

    return {
        "LastSuccessfulAPIRequest": int(now),
        "data": output
    } if output else None


# =====================
# SAVE
# =====================

def save(data):
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    tmp = OUTPUT_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))

    os.replace(tmp, OUTPUT_FILE)


# =====================
# MAIN
# =====================

def main():
    data = build()
    if data:
        save(data)


if __name__ == "__main__":
    main()