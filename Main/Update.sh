set -x

pkg update -y && pkg upgrade -y
pkg install python curl tmux procps -y

termux-setup-storage
termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /sdcard/Delta/Autoexecute
mkdir -p /sdcard/Delta/Workspace

cd ~/PetSim99

echo "🚀 SCRIPT STARTED"

WORKSPACE="/sdcard/Delta/Workspace"
AUTOEXEC="/sdcard/Delta/Autoexecute"
CONFIG="$WORKSPACE/Config.json"

retry_download() {
    for i in 1 2 3; do
        echo "⬇️ download attempt $i $1"
        curl -v --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

CONFIG_URL="https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json?nocache=$(date +%s)"

start_api() {
    echo "🚀 START API FUNCTION CALLED"

    pkill -9 -f API.py 2>/dev/null
    sleep 1

    ls -la "$WORKSPACE"

    if [ ! -f "$WORKSPACE/API.py" ]; then
        echo "❌ API FILE MISSING"
        return
    fi

    echo "🚀 RUN API"
    nohup python "$WORKSPACE/API.py" > "$WORKSPACE/log.txt" 2>&1 &

    echo "✅ API STARTED"
}

echo "📥 DOWNLOAD CONFIG"

retry_download "$CONFIG_URL" "$CONFIG"

echo "📄 CONFIG CONTENT:"
cat "$CONFIG"

read OLD_LUA OLD_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("$CONFIG"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

echo "📊 OLD LUA=$OLD_LUA"
echo "📊 OLD PY=$OLD_PY"

retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
retry_download "$PY_URL" "$WORKSPACE/API.py"

start_api

while true; do

    echo "🔁 LOOP RUNNING"

    retry_download "$CONFIG_URL" "$CONFIG"

    echo "📄 NEW CONFIG:"
    cat "$CONFIG"

    read NEW_LUA NEW_PY LUA_URL PY_URL <<EOF
$(python - <<PY
import json
d=json.load(open("$CONFIG"))
print(
    d["Info"]["Main"]["Version"],
    d["Info"]["API"]["Version"],
    d["Info"]["Main"]["Url"],
    d["Info"]["API"]["Url"]
)
PY
)
EOF

    echo "📊 COMPARE"
    echo "$OLD_LUA -> $NEW_LUA"
    echo "$OLD_PY -> $NEW_PY"

    UPDATED=0

    if [ "$NEW_LUA" != "$OLD_LUA" ]; then
        echo "📦 LUA UPDATE"
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        OLD_LUA="$NEW_LUA"
    fi

    if [ "$NEW_PY" != "$OLD_PY" ]; then
        echo "📦 PY UPDATE"
        retry_download "$PY_URL" "$WORKSPACE/API.py"
        OLD_PY="$NEW_PY"
        UPDATED=1
    fi

    if [ "$UPDATED" -eq 1 ]; then
        echo "🔄 RESTART API"
        start_api
    fi

    sleep 180

done