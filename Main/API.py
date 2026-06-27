import json
import os
# Main
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
MAX_AGE_SECONDS = 30 * 24 * 60 * 60
REQUEST_TIMEOUT = 10
MAX_RETRIES = 1

SESSION = requests.Session()


# =====================
# FETCH
# =====================

def fetch(url):
    for _ in range(MAX_RETRIES):
        try:
            r = SESSION.get(url, timeout=REQUEST_TIMEOUT)
            r.raise_for_status()
            data = r.json().get("data")

            if isinstance(data, list):
                return data
        except:
            pass
        time.sleep(1)
    return None


# =====================
# BUILD
# =====================

def build():
    with ThreadPoolExecutor() as ex:
        pets, rap = list(ex.map(fetch, [PETS_URL, RAP_URL]))
    if not pets or not rap:
        return None
    now = int(time.time())
    # name -> thumbnail lookup
    lookup = {}
    seen = set()

    # =====================
    # PETS
    # =====================
    for pet in pets:
        if pet.get("category") != "Huge":
            continue
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

        # skip new pets (older than 30 days only)
        if now - pet_time <= MAX_AGE_SECONDS:
            continue

        name = pet.get("configName")
        thumb = config.get("thumbnail")
        if isinstance(name, str) and isinstance(thumb, str):
            if thumb.startswith("rbxassetid://"):
                lookup[name.strip().lower()] = thumb

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
        if thumb in seen:
            continue

        seen.add(thumb)
        output[thumb] = int(value)
    if not output:
        return None

    return {
        "data": output,
        "LastSuccessfulAPIRequest": now
    }


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
    try:
        data = build()
        if data:
            save(data)
    except Exception as e:
        print("Error:", e)

while True:
    main()
    time.sleep(180)