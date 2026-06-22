pkg update -y && pkg upgrade -y && pkg install python curl -y && pip install requests && termux-setup-storage && termux-wake-lock && mkdir -p ~/autoexec && cd ~/autoexec && while true; do
curl -s "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/config.json" -o config.json

LUA_URL=$(python -c "import json;print(json.load(open('config.json'))['Info']['Main']['Url'])")
LUA_VER=$(python -c "import json;print(json.load(open('config.json'))['Info']['Main']['Version'])")

PY_URL=$(python -c "import json;print(json.load(open('config.json'))['Info']['API']['Url'])")
PY_VER=$(python -c "import json;print(json.load(open('config.json'))['Info']['API']['Version'])")

# STATE FILE INIT
[ ! -f state.json ] && echo '{"lua":"","py":""}' > state.json

LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua'])")
PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py'])")

# LUA UPDATE
if [ "$LUA_VER" != "$LUA_STATE" ]; then
curl -s "$LUA_URL" -o /storage/emulated/0/Delta/autoexecute/Main.lua
python -c "import json;d=json.load(open('state.json'));d['lua']='$LUA_VER';json.dump(d,open('state.json','w'))"
echo "Lua updated"
fi

# PY UPDATE
if [ "$PY_VER" != "$PY_STATE" ]; then
curl -s "$PY_URL" -o ~/autoexec/api.py
python -c "import json;d=json.load(open('state.json'));d['py']='$PY_VER';json.dump(d,open('state.json','w'))"
echo "Python updated"
fi

# RUN PY EVERY LOOP
python ~/autoexec/api.py

sleep 180
done