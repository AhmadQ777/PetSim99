# ==============================
# TERMUX WATCHDOG (RAM STATE ONLY, NO STATE FILE)
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

CONFIG_URL="https://raw.githubusercontent.com/AhmadQ777/PetSim99/refs/heads/main/Data/Config.json"

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

# ---------------- INITIAL DOWNLOAD ----------------
echo "📥 downloading config..."

retry_download "$CONFIG_URL?nocache=$(date +%s)" "$WORKSPACE/config.tmp.json"

if ! python -c "import json;json.load(open('$WORKSPACE/config.tmp.json'))" 2>/dev/null; then
    echo "❌ invalid config"
    exit 1
fi

read OLD_LUA OLD_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("/sdcard/Delta/Workspace/config.tmp.json"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

echo "📦 initial download..."

retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
retry_download "$PY_URL" "$WORKSPACE/API.py"

start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 checking config..."

    retry_download "$CONFIG_URL?nocache=$(date +%s)" "$WORKSPACE/config.tmp.json"

    if ! python -c "import json;json.load(open('$WORKSPACE/config.tmp.json'))" 2>/dev/null; then
        echo "❌ config invalid"
        sleep 180
        continue
    fi

    read NEW_LUA NEW_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("/sdcard/Delta/Workspace/config.tmp.json"))
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
        echo "📦 LUA UPDATE"
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        OLD_LUA="$NEW_LUA"
    fi

    # API UPDATE
    if [ "$NEW_PY" != "$OLD_PY" ]; then
        echo "📦 API UPDATE"
        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            OLD_PY="$NEW_PY"
            UPDATED_API=1
        fi
    fi

    # RESTART ONLY IF API UPDATED
    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 RESTART API"
        start_api
    fi

    sleep 180

done