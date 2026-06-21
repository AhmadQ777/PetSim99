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

    thumbnail_lookup = {}

    for pet in pets:
        if pet.get("category") != "Huge":
            continue

        name = pet.get("configName")
        config = pet.get("configData")

        if not isinstance(config, dict):
            continue

        thumbnail = config.get("thumbnail")

        if not isinstance(name, str):
            continue

        if not isinstance(thumbnail, str):
            continue

        thumbnail = thumbnail.strip()

        if not thumbnail.startswith("rbxassetid://"):
            continue

        thumbnail_lookup[name.strip().lower()] = thumbnail

    output = {}

    for entry in rap:
        config = entry.get("configData")

        if not isinstance(config, dict):
            continue

        pet_name = config.get("id")

        if not isinstance(pet_name, str):
            continue

        value = entry.get("value")

        if not isinstance(value, (int, float)):
            continue

        if not (HUGE_MIN_VALUE <= value <= HUGE_MAX_VALUE):
            continue

        thumbnail = thumbnail_lookup.get(
            pet_name.strip().lower()
        )

        if thumbnail:
            output[thumbnail] = int(value)

    return output


# =====================
# SAVE
# =====================

def save(data):
    directory = os.path.dirname(OUTPUT_FILE)

    if directory:
        os.makedirs(directory, exist_ok=True)

    temp_file = OUTPUT_FILE + ".tmp"

    with open(temp_file, "w", encoding="utf-8") as file:
        json.dump(
            data,
            file,
            separators=(",", ":"),
            ensure_ascii=False
        )

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