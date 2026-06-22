pkg update -y && pkg upgrade -y && pkg install python curl -y && pip install requests && termux-setup-storage && termux-wake-lock && mkdir -p ~/PetSim99 && mkdir -p /storage/emulated/0/Delta/Autoexecute && mkdir -p /storage/emulated/0/Delta/Workspace && cd ~/PetSim99 && while true; do

curl -s --fail "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" -o Config.json || continue

python - <<'EOF'
import json
try:
    json.load(open("Config.json"))
except:
    exit(1)
EOF
[ $? -ne 0 ] && sleep 180 && continue

LUA_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Url'])")
LUA_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Version'])")

PY_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Url'])")
PY_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Version'])")

[ ! -f state.json ] && echo '{"lua":"","py":""}' > state.json

LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua'])")
PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py'])")

# ---------------- MAIN ----------------
if [ "$LUA_VER" != "$LUA_STATE" ] || [ ! -f /storage/emulated/0/Delta/Autoexecute/Main.lua ]; then
    curl -s --fail "$LUA_URL" -o /storage/emulated/0/Delta/Autoexecute/Main.lua
    [ $? -eq 0 ] && python -c "import json;d=json.load(open('state.json'));d['lua']='$LUA_VER';json.dump(d,open('state.json','w'))"
fi

# ---------------- API ----------------
if [ "$PY_VER" != "$PY_STATE" ] || [ ! -f /storage/emulated/0/Delta/Workspace/API.py ]; then
    curl -s --fail "$PY_URL" -o /storage/emulated/0/Delta/Workspace/API.py
    [ $? -eq 0 ] && python -c "import json;d=json.load(open('state.json'));d['py']='$PY_VER';json.dump(d,open('state.json','w'))"
fi

# ---------------- RUN API ----------------
if [ -f /storage/emulated/0/Delta/Workspace/API.py ]; then
    python /storage/emulated/0/Delta/Workspace/API.py
fi

sleep 180
done