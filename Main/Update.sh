# ==============================
# TERMUX WATCHDOG (ROBUST + NO CACHE + CLEAN COMPARE)
# ==============================

pkg update -y && pkg upgrade -y
pkg install python curl tmux procps -y

termux-setup-storage
termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /sdcard/Delta/Autoexecute
mkdir -p /sdcard/Delta/Workspace

cd ~/PetSim99

WORKSPACE="/sdcard/Delta/Workspace"
AUTOEXEC="/sdcard/Delta/Autoexecute"
CONFIG="$WORKSPACE/Config.json"

echo "🚀 WATCHDOG START"

retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

# FORCE NO CACHE URL
CONFIG_URL="https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json?nocache="

start_api() {
    pkill -9 -f "API.py" 2>/dev/null
    sleep 1
    [ ! -f "$WORKSPACE/API.py" ] && echo "❌ API fehlt" && return
    nohup python "$WORKSPACE/API.py" > "$WORKSPACE/log.txt" 2>&1 &
    echo "🚀 API RUNNING"
}

# ---------------- INITIAL ----------------
retry_download "${CONFIG_URL}$(date +%s)" "$CONFIG"

read OLD_LUA OLD_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("$CONFIG"))
print(
    str(d["Info"]["Main"]["Version"]).strip(),
    str(d["Info"]["API"]["Version"]).strip(),
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
retry_download "$PY_URL" "$WORKSPACE/API.py"

start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 CHECK CONFIG..."

    retry_download "${CONFIG_URL}$(date +%s)" "$CONFIG"

    if ! python -c "import json;json.load(open('$CONFIG'))" 2>/dev/null; then
        echo "❌ CONFIG INVALID"
        sleep 180
        continue
    fi

    read NEW_LUA NEW_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("$CONFIG"))
print(
    str(d["Info"]["Main"]["Version"]).strip(),
    str(d["Info"]["API"]["Version"]).strip(),
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

    echo "📊 LUA $OLD_LUA → $NEW_LUA"
    echo "📊 PY  $OLD_PY → $NEW_PY"

    UPDATED=0

    if [ "$NEW_LUA" != "$OLD_LUA" ]; then
        echo "📦 LUA UPDATE"
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        OLD_LUA="$NEW_LUA"
    fi

    if [ "$NEW_PY" != "$OLD_PY" ]; then
        echo "📦 API UPDATE"
        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            OLD_PY="$NEW_PY"
            UPDATED=1
        fi
    fi

    if [ "$UPDATED" -eq 1 ]; then
        echo "🔄 RESTART API"
        start_api
    fi

    sleep 180

done