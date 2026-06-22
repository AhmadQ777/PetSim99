pkg update -y && pkg upgrade -y

pkg install python git curl -y
pip install requests -q

termux-setup-storage
termux-wake-lock

mkdir -p ~/ps99
cd ~/ps99

while true; do
    curl -s "https://raw.githubusercontent.com/AhmadQ777/PetSim99/refs/heads/main/Data/Config.json" -o Config.json
    python builder.py
    sleep 180
done