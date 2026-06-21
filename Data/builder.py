import json
import os
import time
import requests

# =====================
# CONFIG
# =====================

PETS_URL = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL = "https://ps99.biggamesapi.io/api/rap"

OUTPUT_FILE = "/storage/emulated/0/Delta/Workspace/PETS_DATA.json"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 30_000_000

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
            response = SESSION.get(
                url,
                headers=HEADERS,
                timeout=REQUEST_TIMEOUT
            )

            response.raise_for_status()

            payload = response.json()

            if not isinstance(payload, dict):
                continue

            data = payload.get("data")

            if isinstance(data, list):
                return data

        except requests.RequestException:
            pass
        except ValueError:
            pass

        if attempt + 1 < MAX_RETRIES:
            time.sleep(1)

    return None


# =====================
# BUILD
# =====================


def build():
    pets = fetch(PETS_URL)
    rap = fetch(RAP_URL)

    if pets is None or rap is None:
        return None

    lookup = {}

    for pet in pets:
        if pet.get("category") != "Huge":
            continue

        name = pet.get("configName")
        config = pet.get("configData")

        if not isinstance(name, str):
            continue

        if not isinstance(config, dict):
            continue

        thumbnail = config.get("thumbnail")

        if not isinstance(thumbnail, str):
            continue

        if not thumbnail.startswith("rbxassetid://"):
            continue

        lookup[name.strip().lower()] = thumbnail

    output = {}

    for entry in rap:
        config = entry.get("configData")

        if not isinstance(config, dict):
            continue

        pet_name = config.get("id")
        value = entry.get("value")

        if not isinstance(pet_name, str):
            continue

        if not isinstance(value, (int, float)):
            continue

        if not (HUGE_MIN_VALUE <= value <= HUGE_MAX_VALUE):
            continue

        thumbnail = lookup.get(pet_name.strip().lower())

        if not thumbnail:
            continue

        output[thumbnail] = int(value)

    return output if output else None


# =====================
# SAVE
# =====================

def save(data):
    temp_file = OUTPUT_FILE + ".tmp"

    with open(temp_file, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))

    os.replace(temp_file, OUTPUT_FILE)


# =====================
# MAIN
# =====================

def main():
    data = build()

    if data:
        save(data)


if __name__ == "__main__":
    main()