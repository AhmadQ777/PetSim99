import json
import requests
import os
import time

# =====================
# CONFIG
# =====================

PETS_URL = "https://ps99.biggamesapi.io/api/collection/Pets"
RAP_URL  = "https://ps99.biggamesapi.io/api/rap"

OUTPUT_FILE = "/storage/emulated/0/Delta/Workspace/PETS_DATA.json"

HUGE_MIN_VALUE = 0
HUGE_MAX_VALUE = 30_000_000

REQUEST_TIMEOUT = 10
MAX_RETRIES = 2


# =====================
# FETCH
# =====================

def fetch(url):
    for _ in range(MAX_RETRIES):
        try:
            response = requests.get(url, timeout=REQUEST_TIMEOUT)
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

        time.sleep(1)

    return None


# =====================
# BUILD / MERGE
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

        if not isinstance(config, dict):
            continue

        thumbnail = config.get("thumbnail")

        if (
            isinstance(name, str)
            and isinstance(thumbnail, str)
            and thumbnail
        ):
            lookup[name.strip().lower()] = thumbnail

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

        thumbnail = lookup.get(pet_name.strip().lower())

        if thumbnail:
            output[thumbnail] = value

    return output


# =====================
# SAVE
# =====================

def save(data):
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as file:
        json.dump(data, file, separators=(",", ":"))


# =====================
# RUN
# =====================

def main():
    data = build()

    if data is not None:
        save(data)


if __name__ == "__main__":
    main()