pkg update -y && pkg upgrade -y

pkg install python git curl -y

pip install requests -q

# Storage Zugriff aktivieren
termux-setup-storage

termux-wake-lock

mkdir -p ~/ps99
cd ~/ps99

# initial download
curl -s "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Server/builder.py" -o builder.py

# main loop
while true; do
    curl -s "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Server/builder.py" -o builder.py
    python builder.py
    sleep 180
done