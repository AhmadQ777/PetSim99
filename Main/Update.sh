pkg update -y && pkg upgrade -y && pkg install python curl -y && pip install requests && termux-setup-storage && termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace
cd ~/PetSim99

[ ! -f state.json ] && echo '{"lua_ver":"","py_ver":""}' > state.json

while true; do

# ---------------- CONFIG DOWNLOAD ----------------
curl -s --fail --max-time 10 \
"https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
-o Config.json || { sleep 180; continue; }

# ---------------- VALID JSON CHECK ----------------
python - <<'EOF'
import json, sys
try:
    json.load(open("Config.json"))
except:
    sys.exit(1)
EOF
[ $? -ne 0 ] && sleep 180 && continue

# ---------------- READ CONFIG ----------------
LUA_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Url'])")
LUA_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Version'])")

PY_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Url'])")
PY_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Version'])")

# ---------------- STATE READ ----------------
LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua_ver'])")
PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py_ver'])")

# ---------------- LUA UPDATE ----------------
if [ "$LUA_VER" != "$LUA_STATE" ] || [ ! -f /storage/emulated/0/Delta/Autoexecute/Main.lua ]; then
    curl -s --fail --max-time 10 "$LUA_URL" -o /storage/emulated/0/Delta/Autoexecute/Main.lua && \
    python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))"
fi

# ---------------- PY UPDATE ----------------
if [ "$PY_VER" != "$PY_STATE" ] || [ ! -f /storage/emulated/0/Delta/Workspace/API.py ]; then
    curl -s --fail --max-time 10 "$PY_URL" -o /storage/emulated/0/Delta/Workspace/API.py && \
    python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))"
fi

# ---------------- API RESTART (ALWAYS) ----------------
pkill -f "/storage/emulated/0/Delta/Workspace/API.py" 2>/dev/null
sleep 1
nohup python /storage/emulated/0/Delta/Workspace/API.py >/dev/null 2>&1 &

# ---------------- LOOP DELAY ----------------
sleep 180

done