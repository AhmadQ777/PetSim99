pkg update -y && pkg upgrade -y && pkg install python curl -y && pip install requests && termux-setup-storage && termux-wake-lock && mkdir -p ~/PetSim99 && mkdir -p /storage/emulated/0/Delta/Autoexecute && mkdir -p /storage/emulated/0/Delta/Workspace && cd ~/PetSim99 && while true; do

curl -s "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/config.json" -o config.json

LUA_URL=$(python -c "import json;print(json.load(open('config.json'))['Info']['Main']['Url'])")
LUA_VER=$(python -c "import json;print(json.load(open('config.json'))['Info']['Main']['Version'])")

PY_URL=$(python -c "import json;print(json.load(open('config.json'))['Info']['API']['Url'])")
PY_VER=$(python -c "import json;print(json.load(open('config.json'))['Info']['API']['Version'])")

[ ! -f state.json ] && echo '{"lua":"","py":""}' > state.json

LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua'])")
PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py'])")

if [ "$LUA_VER" != "$LUA_STATE" ]; then
  curl -s "$LUA_URL" -o /storage/emulated/0/Delta/Autoexecute/Main.lua
  python -c "import json;d=json.load(open('state.json'));d['lua']='$LUA_VER';json.dump(d,open('state.json','w'))"
fi

if [ "$PY_VER" != "$PY_STATE" ]; then
  curl -s "$PY_URL" -o /storage/emulated/0/Delta/Workspace/API.py
  python -c "import json;d=json.load(open('state.json'));d['py']='$PY_VER';json.dump(d,open('state.json','w'))"
fi

[ -f /storage/emulated/0/Delta/Workspace/API.py ] && python /storage/emulated/0/Delta/Workspace/API.py

sleep 180

done