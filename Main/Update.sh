pkg update -y && pkg upgrade -y && pkg install python curl tmux procps -y && pip install requests && termux-setup-storage && termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace
cd ~/PetSim99

# ---------------- STATE ----------------
[ ! -f state.json ] && echo '{"lua_ver":"","py_ver":""}' > state.json

# ---------------- RETRY DOWNLOAD ----------------
retry_download() {
    URL="$1"
    OUT="$2"

    for i in 1 2 3; do
        if curl -s --fail --max-time 10 "$URL" -o "$OUT"; then
            return 0
        fi
        sleep 2
    done
    return 1
}

# ---------------- START API ----------------
echo "🚀 Starte API..."
nohup python /storage/emulated/0/Delta/Workspace/API.py >/dev/null 2>&1 &
echo "✅ API gestartet"

# ---------------- MAIN LOOP ----------------
while true; do

    echo "📥 Lade Config herunter..."

    if ! retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "Config.json"; then
        echo "❌ Config konnte nicht heruntergeladen werden."
        sleep 180
        continue
    fi

    python - <<'EOF'
import json, sys
try:
    json.load(open("Config.json"))
except:
    sys.exit(1)
EOF

    [ $? -ne 0 ] && echo "❌ Ungültige Config." && sleep 180 && continue

    # -------- READ CONFIG --------
    LUA_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Url'])")
    LUA_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Version'])")

    PY_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Url'])")
    PY_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Version'])")

    LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua_ver'])")
    PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py_ver'])")

    # -------- LUA UPDATE --------
    if [ "$LUA_VER" != "$LUA_STATE" ] || [ ! -f /storage/emulated/0/Delta/Autoexecute/Main.lua ]; then
        echo "📦 Aktualisiere Main.lua..."
        if retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua"; then
            python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))"
            echo "✅ Main.lua auf Version $LUA_VER aktualisiert."
        else
            echo "❌ Main.lua konnte nicht heruntergeladen werden."
        fi
    fi

    # -------- PY UPDATE --------
    UPDATED_API=0

    if [ "$PY_VER" != "$PY_STATE" ] || [ ! -f /storage/emulated/0/Delta/Workspace/API.py ]; then
        echo "📦 Aktualisiere API.py..."
        if retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py"; then
            python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))"
            UPDATED_API=1
            echo "✅ API.py auf Version $PY_VER aktualisiert."
        else
            echo "❌ API.py konnte nicht heruntergeladen werden."
        fi
    fi

    # -------- RESTART API AFTER UPDATE --------
    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 Starte API neu..."
        pkill -f "API.py" 2>/dev/null
        sleep 1
        nohup python /storage/emulated/0/Delta/Workspace/API.py >/dev/null 2>&1 &
        echo "✅ API neu gestartet."
    fi

    echo "⏳ Warte 180 Sekunden..."
    sleep 180

done