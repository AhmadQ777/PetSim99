# ==============================
# TERMUX WATCHDOG (AUTO PATH FIX + NO SILENT FAIL)
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

# ---------------- PATH DETECTION ----------------
WORKSPACE="/sdcard/Delta/Workspace"
AUTOEXEC="/sdcard/Delta/Autoexecute"

if [ ! -d "$WORKSPACE" ]; then
    WORKSPACE="/storage/emulated/0/Delta/Workspace"
    AUTOEXEC="/storage/emulated/0/Delta/Autoexecute"
fi

echo "📁 Using Workspace: $WORKSPACE"

# ---------------- STATE ----------------
STATE_FILE="$WORKSPACE/state.json"

if [ ! -f "$STATE_FILE" ] || ! python -c "import json;json.load(open('$STATE_FILE'))" 2>/dev/null; then
    echo '{"lua_ver":"","py_ver":""}' > "$STATE_FILE"
fi

# ---------------- RETRY DOWNLOAD ----------------
retry_download() {
    for i in 1 2 3; do
        echo "⬇️ Download attempt $i: $1"
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    echo "❌ FAILED: $1"
    return 1
}

# ---------------- START API ----------------
start_api() {
    pkill -9 -f "API.py" 2>/dev/null
    sleep 1

    if [ ! -f "$WORKSPACE/API.py" ]; then
        echo "❌ API.py NOT FOUND in $WORKSPACE"
        return
    fi

    echo "🚀 Starting API..."
    nohup python "$WORKSPACE/API.py" > "$WORKSPACE/log.txt" 2>&1 &
    echo "✅ API STARTED"
}

start_api

# ---------------- LOOP ----------------
while true; do

    echo "📥 Download Config..."

    if ! retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "$WORKSPACE/Config.json"; then
        sleep 180
        continue
    fi

    read LUA_URL LUA_VER PY_URL PY_VER <<EOF
$(python - <<'PY'
import json
try:
    d=json.load(open("/sdcard/Delta/Workspace/Config.json"))
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
$(python - <<'PY'
import json
try:
    d=json.load(open("/sdcard/Delta/Workspace/state.json"))
    print(d.get("lua_ver",""), d.get("py_ver",""))
except:
    print("", "")
PY
)
EOF

    UPDATED_API=0

    # ---------------- LUA ----------------
    if [ "$LUA_VER" != "$LUA_STATE" ]; then
        echo "📦 Updating Main.lua..."
        retry_download "$LUA_URL" "$AUTOEXEC/Main.lua"
        python -c "import json;d=json.load(open('$STATE_FILE'));d['lua_ver']='$LUA_VER';json.dump(d,open('$STATE_FILE','w'))"
    fi

    # ---------------- PY ----------------
    if [ "$PY_VER" != "$PY_STATE" ]; then
        echo "📦 Updating API.py..."
        if retry_download "$PY_URL" "$WORKSPACE/API.py"; then
            python -c "import json;d=json.load(open('$STATE_FILE'));d['py_ver']='$PY_VER';json.dump(d,open('$STATE_FILE','w'))"
            UPDATED_API=1
        fi
    fi

    # ---------------- RESTART ONLY IF UPDATED ----------------
    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 API UPDATED → RESTART"
        start_api
    fi

    echo "⏳ Sleep 180s..."
    sleep 180

done