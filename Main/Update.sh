# ==============================
# TERMUX ULTRA STABLE WATCHDOG
# ==============================

pkg update -y && pkg upgrade -y
pkg install python curl tmux procps -y

termux-setup-storage
termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace

cd ~/PetSim99

# ---------------- SAFE STATE INIT ----------------
if [ ! -f state.json ] || ! python -c "import json;json.load(open('state.json'))" 2>/dev/null; then
    echo '{"lua_ver":"","py_ver":""}' > state.json
fi

# ---------------- WEBHOOK ----------------
WEBHOOK="https://discord.com/api/webhooks/XXXXX"

send_hook() {
    curl -s -H "Content-Type: application/json" \
    -d "{\"content\":\"$1\"}" \
    "$WEBHOOK" >/dev/null 2>&1
}

send_hook "🟢 Watchdog gestartet"

# ---------------- START API ----------------
start_api() {
    pkill -f "API.py" 2>/dev/null
    sleep 2
    nohup python /storage/emulated/0/Delta/Workspace/API.py > /dev/null 2>&1 &
}

# ---------------- DOWNLOAD SAFE ----------------
retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

# ---------------- LOOP ----------------
while true; do

    # CONFIG
    if ! retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "Config.json"; then
        sleep 180
        continue
    fi

    # SAFE READ CONFIG (1x python only)
    read LUA_URL LUA_VER PY_URL PY_VER <<EOF
$(python - <<'PY'
import json
d=json.load(open("Config.json"))
print(
d["Info"]["Main"]["Url"],
d["Info"]["Main"]["Version"],
d["Info"]["API"]["Url"],
d["Info"]["API"]["Version"]
)
PY
)
EOF

    read LUA_STATE PY_STATE <<EOF
$(python - <<'PY'
import json
d=json.load(open("state.json"))
print(d.get("lua_ver",""), d.get("py_ver",""))
PY
)
EOF

    # LUA UPDATE
    if [ "$LUA_VER" != "$LUA_STATE" ]; then
        if retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua"; then
            python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))"
            send_hook "📦 LUA updated $LUA_VER"
        fi
    fi

    # PY UPDATE
    if [ "$PY_VER" != "$PY_STATE" ]; then
        if retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py"; then
            python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))"
            send_hook "📦 API updated $PY_VER"
        fi
    fi

    # API CHECK (no spam restart)
    if ! pgrep -f "API.py" >/dev/null; then
        start_api
        send_hook "🔁 API restarted"
        sleep 10
    fi

    sleep 180

done