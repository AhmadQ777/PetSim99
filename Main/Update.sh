# ==============================
# TERMUX WATCHDOG (FIXED START ORDER + SAFE DOWNLOAD FIRST)
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
STATE_FILE="$WORKSPACE/state.json"

# ---------------- INIT STATE ----------------
mkdir -p "$WORKSPACE"

if [ ! -f "$STATE_FILE" ] || ! python -c "import json;json.load(open('$STATE_FILE'))" 2>/dev/null; then
    echo '{"lua_ver":"","py_ver":""}' > "$STATE_FILE"
fi

# ---------------- DOWNLOAD FUNCTION ----------------
retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

# ---------------- LOAD CONFIG ----------------
CONFIG_FILE="$WORKSPACE/Config.json"

echo "📥 Download Config..."

retry_download \
"https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
"$CONFIG_FILE"

# ---------------- PARSE CONFIG ----------------
read LUA_URL LUA_VER PY_URL PY_VER <<EOF
$(python - <<PY
import json
try:
    d=json.load(open("$CONFIG_FILE"))
    print(
        d["Info"]["Main"]["Url"],
        d["Info"]["Main"]["Version"],
        d["Info"]["API"]["Url"],
        d["Info"]["API"]["Version"]
    )
except:
    print("", "", "", "")
PY
)
EOF

read LUA_STATE PY_STATE <<EOF
$(python - <<PY
import json
try:
    d=json.load(open("$STATE_FILE"))
    print(d.get("lua_ver",""), d.get("py_ver",""))
except:
    print("", "")
PY
)
EOF

# ---------------- DOWNLOAD FILES FIRST ----------------
echo "📦 Checking downloads..."

UPDATED_API=0

# LUA
if [ "$LUA_VER" != "$LUA_STATE" ] || [ ! -f "$AUTOEXEC/Main.lua" ]; then
    echo "⬇️ Download Main.lua"
    retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
    python -c "import json;d=json.load(open('$STATE_FILE'));d['lua_ver']='$LUA_VER';json.dump(d,open('$STATE_FILE','w'))"
fi

# API
if [ "$PY_VER" != "$PY_STATE" ] || [ ! -f "$WORKSPACE/API.py" ]; then
    echo "⬇️ Download API.py"
    if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
        python -c "import json;d=json.load(open('$STATE_FILE'));d['py_ver']='$PY_VER';json.dump(d,open('$STATE_FILE','w'))"
        UPDATED_API=1
    fi
fi

# ---------------- START API ONLY AFTER EXISTS ----------------
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

# START ON FIRST RUN
start_api

# ---------------- LOOP ----------------
while true; do

    echo "🔁 Checking updates..."

    retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "$CONFIG_FILE"

    read LUA_URL LUA_VER PY_URL PY_VER <<EOF
$(python - <<PY
import json
try:
    d=json.load(open("$CONFIG_FILE"))
    print(
        d["Info"]["Main"]["Url"],
        d["Info"]["Main"]["Version"],
        d["Info"]["API"]["Url"],
        d["Info"]["API"]["Version"]
    )
except:
    print("", "", "", "")
PY
)
EOF

    read LUA_STATE PY_STATE <<EOF
$(python - <<PY
import json
try:
    d=json.load(open("$STATE_FILE"))
    print(d.get("lua_ver",""), d.get("py_ver",""))
except:
    print("", "")
PY
)
EOF

    UPDATED_API=0

    # LUA UPDATE
    if [ "$LUA_VER" != "$LUA_STATE" ]; then
        echo "📦 Updating Main.lua"
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        python -c "import json;d=json.load(open('$STATE_FILE'));d['lua_ver']='$LUA_VER';json.dump(d,open('$STATE_FILE','w'))"
    fi

    # API UPDATE
    if [ "$PY_VER" != "$PY_STATE" ]; then
        echo "📦 Updating API.py"
        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            python -c "import json;d=json.load(open('$STATE_FILE'));d['py_ver']='$PY_VER';json.dump(d,open('$STATE_FILE','w'))"
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