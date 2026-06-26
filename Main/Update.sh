# ==============================
# TERMUX WATCHDOG (CACHE FIX + UPDATE RELIABLE)
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
CONFIG_FILE="$WORKSPACE/Config.json"

# ---------------- DOWNLOAD ----------------
retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

# ---------------- CACHE BUSTER ----------------
get_config_url() {
    echo "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json?nocache=$(date +%s)"
}

# ---------------- START API ----------------
start_api() {
    pkill -9 -f "API.py" 2>/dev/null
    sleep 1

    if [ ! -f "$WORKSPACE/API.py" ]; then
        echo "❌ API.py fehlt"
        return
    fi

    echo "🚀 Starting API..."
    nohup python "$WORKSPACE/API.py" > "$WORKSPACE/log.txt" 2>&1 &
    echo "✅ API running"
}

# ---------------- INITIAL CONFIG ----------------
echo "📥 Download Config..."

retry_download "$(get_config_url)" "$CONFIG_FILE"

if ! python -c "import json;json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
    echo "❌ Config invalid"
    exit 1
fi

echo "✅ Config OK"

read OLD_LUA_VER OLD_PY_VER LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("$CONFIG_FILE"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

echo "📦 Initial download..."

retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
retry_download "$PY_URL" "$WORKSPACE/API.py"

start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 Checking updates..."

    retry_download "$(get_config_url)" "$CONFIG_FILE"

    if ! python -c "import json;json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
        echo "❌ Config broken → skip"
        sleep 180
        continue
    fi

    read NEW_LUA_VER NEW_PY_VER LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("$CONFIG_FILE"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

    echo "📊 LUA: $OLD_LUA_VER → $NEW_LUA_VER"
    echo "📊 PY : $OLD_PY_VER → $NEW_PY_VER"

    UPDATED_API=0

    if [ "$NEW_LUA_VER" != "$OLD_LUA_VER" ]; then
        echo "📦 Updating Main.lua..."
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        OLD_LUA_VER="$NEW_LUA_VER"
    fi

    if [ "$NEW_PY_VER" != "$OLD_PY_VER" ]; then
        echo "📦 Updating API.py..."
        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            OLD_PY_VER="$NEW_PY_VER"
            UPDATED_API=1
        fi
    fi

    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 Restarting API..."
        start_api
    fi

    sleep 180

done