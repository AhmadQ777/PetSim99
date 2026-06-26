# ==============================
# TERMUX WATCHDOG (NO STATE FILE, MEMORY VERSION TRACKING)
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

WORKSPACE="/sdcard/Delta/Workspace"
AUTOEXEC="/sdcard/Delta/Autoexecute"

CONFIG_URL="https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json"

# ---------------- DOWNLOAD ----------------
retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

# ---------------- START API ----------------
start_api() {
    pkill -9 -f "API.py" 2>/dev/null
    sleep 1

    if [ ! -f "$WORKSPACE/API.py" ]; then
        echo "❌ API missing"
        return
    fi

    echo "🚀 START API"
    nohup python "$WORKSPACE/API.py" > "$WORKSPACE/log.txt" 2>&1 &
}

# ---------------- INITIAL LOAD (MEMORY VARS) ----------------
retry_download "$CONFIG_URL?nocache=$(date +%s)" "$WORKSPACE/Config.json"

if ! python -c "import json;json.load(open('$WORKSPACE/Config.json'))" 2>/dev/null; then
    echo "❌ Invalid config"
    exit 1
fi

read OLD_LUA OLD_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("/sdcard/Delta/Workspace/Config.json"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

# download initial files
retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
retry_download "$PY_URL" "$WORKSPACE/API.py"

start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 CHECK CONFIG"

    retry_download "$CONFIG_URL?nocache=$(date +%s)" "$WORKSPACE/Config.json"

    if ! python -c "import json;json.load(open('$WORKSPACE/Config.json'))" 2>/dev/null; then
        echo "❌ Config error"
        sleep 180
        continue
    fi

    read NEW_LUA NEW_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("/sdcard/Delta/Workspace/Config.json"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

    UPDATED_API=0

    # LUA UPDATE
    if [ "$NEW_LUA" != "$OLD_LUA" ]; then
        echo "📦 UPDATE LUA"
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        OLD_LUA="$NEW_LUA"
    fi

    # API UPDATE
    if [ "$NEW_PY" != "$OLD_PY" ]; then
        echo "📦 UPDATE API"

        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            OLD_PY="$NEW_PY"
            UPDATED_API=1
        fi
    fi

    # RESTART API ONLY IF NEW OR UPDATED
    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 RESTART API"
        start_api
    fi

    sleep 180

done