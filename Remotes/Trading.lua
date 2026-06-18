--// Trade Remotes


-- Send/Accept Trade Request
local args = {
	game:GetService("Players"):WaitForChild("NAHCJKLJ") -- Player trading with
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Server: Trading: Request"):InvokeServer(unpack(args))

-- Decline Trade Request
local args = {
	game:GetService("Players"):WaitForChild("NAHCJKLJ") -- Player trading with
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Server: Trading: Reject"):InvokeServer(unpack(args))

-- Accepting Trade First Stage & Second Stage 
local args = {
	9,      -- Trade Amount
	true,
	1       -- Item Amount , starts counting at 1
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Server: Trading: Set Ready"):InvokeServer(unpack(args))

local args = {
	9,
	true,
	1
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Server: Trading: Set Confirmed"):InvokeServer(unpack(args))

-- Adding/Removing Item to Trade
local args = {
	14,     -- Trade Amount
	"Pet",  -- Type
	"da6b0203bb804a2f932f538635b75c91", -- ItemId
	21      -- Item Amount , set Amount to 0 to remove item from trade
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Server: Trading: Set Item"):InvokeServer(unpack(args))



