pkg update -y && pkg upgrade -y
pkg install python git curl -y
pip install requests -q
termux-setup-storage
termux-wake-lock
mkdir -p ~/ps99
cd ~/ps99
while true; do
    curl -s "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/builder.py" -o builder.py
    python builder.py
    sleep 120
done