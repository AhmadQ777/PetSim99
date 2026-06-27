# ==============================
# TERMUX WATCHDOG (PURE RAM, NO FILE RELIABILITY ISSUES)
# ==============================

pkg update -y && pkg upgrade -y
pkg install python curl tmux procps -y

termux-setup-storage
termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /sdcard/Delta/Autoexecute
mkdir -p /sdcard/Delta/Workspace

cd ~/PetSim99

echo "🚀 WATCHDOG START"

AUTOEXEC="/sdcard/Delta/Autoexecute"
WORKSPACE="/sdcard/Delta/Workspace"

retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

start_api() {
    pkill -9 -f API.py 2>/dev/null
    sleep 1

    if [ ! -f "$WORKSPACE/API.py" ]; then
        echo "❌ API missing"
        return
    fi

    echo "🚀 START API"
    nohup python "$WORKSPACE/API.py" > "$WORKSPACE/log.txt" 2>&1 &
}

fetch_config() {
    python - <<PY
import requests
data = requests.get(
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/refs/heads/main/Data/Config.json?nocache=$(date +%s)"
).json()
print(
    str(data["Info"]["Main"]["Version"]).strip(),
    str(data["Info"]["API"]["Version"]).strip(),
    data["Info"]["Main"]["Url"],
    data["Info"]["API"]["Url"]
)
PY
}

# ---------------- INITIAL ----------------
echo "📥 loading config..."

read OLD_LUA OLD_PY LUA_URL PY_URL < <(fetch_config)

echo "📦 initial download"

curl -s "$LUA_URL" -o "$AUTOEXEC/Main.lua"
curl -s "$PY_URL" -o "$WORKSPACE/API.py"

start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 CHECK CONFIG"

    read NEW_LUA NEW_PY LUA_URL PY_URL < <(fetch_config)

    UPDATED=0

    if [ "$NEW_LUA" != "$OLD_LUA" ]; then
        echo "📦 LUA UPDATE"
        curl -s "$LUA_URL" -o "$AUTOEXEC/Main.lua"
        OLD_LUA="$NEW_LUA"
    fi

    if [ "$NEW_PY" != "$OLD_PY" ]; then
        echo "📦 API UPDATE"
        curl -s "$PY_URL" -o "$WORKSPACE/API.py"
        OLD_PY="$NEW_PY"
        UPDATED=1
    fi

    if [ "$UPDATED" -eq 1 ]; then
        echo "🔄 RESTART API"
        start_api
    fi

    sleep 180

done