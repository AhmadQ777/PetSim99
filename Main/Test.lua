local args = {
	8678791334,	
	{
		["7d6b8b5dc2a144a6962a255d25b7abc1"] = 1 
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

