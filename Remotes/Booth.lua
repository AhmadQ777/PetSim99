--// Booth Remotes

local EmptyBooths = nil
local ClaimedBooths = nil



-- Claim Booth
local args = {
	"21" -- BoothId
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_ClaimBooth"):InvokeServer(unpack(args))

-- Close Booth
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_DiscardBooth"):InvokeServer()

-- Restore Booth
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_Restore"):InvokeServer()




-- Create Listing
local args = {
	"0dfd50f7d1de46e99156d2baf38c5c1b", -- ItemId
	100000000,							-- Price
	1									-- Amount	
}
workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):WaitForChild("Model"):WaitForChild("Pets"):WaitForChild("Booths_CreateListing"):InvokeServer(unpack(args))

-- Remove Listing
local args = {
	"f42a5363e54b41c2a5c13be7b9d1c876"	-- ItemId
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RemoveListing"):InvokeServer(unpack(args))




-- Buy Requests
local args = {
	8678791334,	-- Buying from Player.UserId
	{
		["7d6b8b5dc2a144a6962a255d25b7abc1"] = 1 -- ItemId , Amount
	},
	{
		Caller = {
			LineNumber = 527,
			ScriptClass = "ModuleScript",
			Variadic = false,
			Traceback = "ReplicatedStorage.Library.Client.BoothCmds:527 function PromptPurchase2\nReplicatedStorage.Library.Client.BoothCmds:654 function promptOtherPlayerBooth2\nReplicatedStorage.Library.Client.BoothCmds:157",
			ScriptPath = "ReplicatedStorage.Library.Client.BoothCmds",
			FunctionName = "PromptPurchase2",
			Handle = "function: 0xf91ad081f307b7ed",
			ScriptType = "Instance",
			ParameterCount = 2,
			SourceIdentifier = "ReplicatedStorage.Library.Client.BoothCmds"
		}
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer(unpack(args))