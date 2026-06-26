pkg update -y && pkg upgrade -y
pkg install python curl tmux procps -y
pip install requests
termux-wake-lock

termux-setup-storage

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace

cd ~/PetSim99

echo "🚀 SCRIPT START"

# ---------------- STATE ----------------
[ ! -f state.json ] && echo '{"lua_ver":"","py_ver":""}' > state.json

# ---------------- RETRY DOWNLOAD ----------------
retry_download() {
    URL="$1"
    OUT="$2"

    for i in 1 2 3; do
        echo "⬇️ Download Versuch $i: $URL"
        if curl -s --fail --max-time 10 "$URL" -o "$OUT"; then
            echo "✅ Download OK"
            return 0
        fi
        sleep 2
    done

    echo "❌ Download FAILED"
    return 1
}

# ---------------- START API (DEBUG MODE) ----------------
echo "🚀 Starte API (DEBUG)..."

python /storage/emulated/0/Delta/Workspace/API.py &
API_PID=$!

echo "✅ API gestartet PID: $API_PID"

# ---------------- MAIN LOOP ----------------
while true; do

    echo "📥 Lade Config..."

    if ! retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "Config.json"; then
        sleep 180
        continue
    fi

    python - <<'EOF'
import json, sys
try:
    json.load(open("Config.json"))
    print("✅ Config OK")
except Exception as e:
    print("❌ Config ERROR:", e)
    sys.exit(1)
EOF

    [ $? -ne 0 ] && sleep 180 && continue

    LUA_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Url'])")
    LUA_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Version'])")

    PY_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Url'])")
    PY_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Version'])")

    LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua_ver'])")
    PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py_ver'])")

    # -------- LUA --------
    if [ "$LUA_VER" != "$LUA_STATE" ]; then
        echo "📦 Main.lua Update"
        retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua"

        python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))"
    fi

    # -------- PY --------
    UPDATED_API=0

    if [ "$PY_VER" != "$PY_STATE" ]; then
        echo "📦 API.py Update"
        if retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py"; then
            python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))"
            UPDATED_API=1
        fi
    fi

    # -------- RESTART ONLY IF UPDATED --------
    if [ "$UPDATED_API" -eq 1 ]; then
        echo "🔄 API UPDATE DETECTED → RESTART"

        kill $API_PID 2>/dev/null
        sleep 1

        python /storage/emulated/0/Delta/Workspace/API.py &
        API_PID=$!

        echo "✅ API RESTARTED PID: $API_PID"
    fi

    echo "⏳ Sleep 180s..."
    sleep 180

done