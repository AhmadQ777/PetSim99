local Players = game:GetSer("Players")
local Player = Players.LocalPlayer
task.wait(5)
firesignal(Player.PlayerGui:WaitForChild("InventorySelect"):WaitForChild("Frame"):WaitForChild("Confirm").Activated)