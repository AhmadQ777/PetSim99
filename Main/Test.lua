local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local OwnedBooth
for _, ClaimedBooth in ipairs(game.Workspace.__THINGS.Booths:GetChildren()) do
	if ClaimedBooth:GetAttribute("Owner") == Player.UserId then
		OwnedBooth = ClaimedBooth
	end
end
while task.wait() do
	local WaitedTime = 0
	for _, Child in ipairs(OwnedBooth:GetChildren()) do
		while Child:FindFirstChild("CircularBar") do
			WaitedTime += 0.1
			task.wait(0.1)
		end
		if WaitedTime ~= 0 then
			print(WaitedTime)			
		end
		WaitedTime = 0
	end
end