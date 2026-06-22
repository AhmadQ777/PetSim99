# ==============================
# TERMUX ULTRA STABLE WATCHDOG (SMART MAIN CALL MODE)
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

# ---------------- DOWNLOAD SAFE ----------------
retry_download() {
    for i in 1 2 3; do
        curl -s --fail --max-time 10 -H "Cache-Control: no-cache" "$1" -o "$2" && return 0
        sleep 2
    done
    return 1
}

# ---------------- LOOP ----------------
while true; do

    # CONFIG FETCH
    if ! retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "Config.json"; then
        sleep 180
        continue
    fi

    # READ CONFIG
    read LUA_URL LUA_VER PY_URL PY_VER <<EOF
$(python - <<'PY'
import json
try:
    d=json.load(open("Config.json"))
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

    # READ STATE
    read LUA_STATE PY_STATE <<EOF
$(python - <<'PY'
import json
try:
    d=json.load(open("state.json"))
    print(d.get("lua_ver",""), d.get("py_ver",""))
except:
    print("", "")
PY
)
EOF

    # =============================
    # LUA UPDATE (ONLY IF CHANGED)
    # =============================
    if [ "$LUA_VER" != "$LUA_STATE" ]; then
        if retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua"; then
            python - <<PY
import json
d=json.load(open("state.json"))
d["lua_ver"]="$LUA_VER"
json.dump(d,open("state.json","w"))
PY
        fi
    fi

    # =============================
    # PY UPDATE (ONLY IF CHANGED)
    # =============================
    if [ "$PY_VER" != "$PY_STATE" ]; then
        if retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py"; then
            python - <<PY
import json
d=json.load(open("state.json"))
d["py_ver"]="$PY_VER"
json.dump(d,open("state.json","w"))
PY
        fi
    fi

    # =============================
    # ALWAYS CALL MAIN (SAFE IMPORT)
    # =============================
    python - <<'PY' 2>/dev/null || true
import sys
sys.path.append("/storage/emulated/0/Delta/Workspace")

import API

try:
    API.main()
except:
    pass
PY

    echo "▶ API.main() executed at $(date)"

    sleep 180

done