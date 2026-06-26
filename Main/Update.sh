# ==============================
# TERMUX WATCHDOG (NO STATE FILE, CONFIG-BASED VERSION CHECK)
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

# ---------------- INITIAL DOWNLOAD ----------------
echo "📥 Download Config..."

retry_download \
"https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
"$CONFIG_FILE"

# ---------------- FIRST PARSE ----------------
read OLD_LUA_VER OLD_PY_VER <<EOF
$(python - <<PY
import json
try:
    d=json.load(open("$CONFIG_FILE"))
    print(
        d["Info"]["Main"]["Version"],
        d["Info"]["API"]["Version"]
    )
except:
    print("", "")
PY
)
EOF

# ---------------- DOWNLOAD FILES FIRST ----------------
echo "📦 Initial sync..."

retry_download "$(python -c "import json;print(json.load(open('$CONFIG_FILE'))['Info']['Main']['Url'])")" "$AUTOEXEC/Main.lua"
retry_download "$(python -c "import json;print(json.load(open('$CONFIG_FILE'))['Info']['API']['Url'])")" "$WORKSPACE/API.py"

# ---------------- START API ----------------
start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 Checking updates..."

    retry_download "$CONFIG_FILE" "$CONFIG_FILE"

    read NEW_LUA_VER NEW_PY_VER LUA_URL PY_URL <<EOF
$(python - <<PY
import json
try:
    d=json.load(open("$CONFIG_FILE"))
    print(
        d["Info"]["Main"]["Version"],
        d["Info"]["API"]["Version"],
        d["Info"]["Main"]["Url"],
        d["Info"]["API"]["Url"]
    )
except:
    print("", "", "", "")
PY
)
EOF

    UPDATED_API=0

    # LUA UPDATE CHECK
    if [ "$NEW_LUA_VER" != "$OLD_LUA_VER" ]; then
        echo "📦 Main.lua updated"
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        OLD_LUA_VER="$NEW_LUA_VER"
    fi

    # API UPDATE CHECK
    if [ "$NEW_PY_VER" != "$OLD_PY_VER" ]; then
        echo "📦 API.py updated"
        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            OLD_PY_VER="$NEW_PY_VER"
            UPDATED_API=1
        fi
    fi

    # RESTART ONLY IF UPDATED
    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 Restarting API..."
        start_api
    fi

    echo "⏳ Sleep 180s..."
    sleep 180

done