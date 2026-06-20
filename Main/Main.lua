return function ()
    --// Main
    --// Services
    local RS = game:GetService("RunService")
    local TPS = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")

    --// Player
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local HRT = Character:WaitForChild("HumanoidRootPart")
    local UserId = Player.UserId

    --// Initialize Varaibles to check
    local TradingPlaza = game.Workspace:FindFirstChild("TradingPlaza")

    --// Decalaring Const Var
    local Const = {
        INSTANCE = {
            DIAMONDS = Player:WaitForChild("leaderstats"):WaitForChild("💎 Diamonds"),
            PLAYER_INVENTORY = Player:WaitForChild("PlayerGui"):WaitForChild("Inventory"),
            EQUIPPED_PETS = Player:WaitForChild("PlayerGui"):WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("Pets"):WaitForChild("EquippedPets"),
            CLAIMED_BOOTHS = game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"),
            CHECK_UNCLAIMED_BOOTHS =  TradingPlaza and TradingPlaza:FindFirstChild("BoothSpawns"),
        },
        DATA = {
            API = "https://raw.githubusercontent.com/AhmadQ777/PetSim99_API/refs/heads/main/ITEMS_DATA.json",
            PATH = {
                PLAYER_INV = "C:\\Users\\Amira\\AppData\\Local\\Xeno\\workspace\\PLAYER_INV.json",
                PETS_DATA = "C:\\Users\\Amira\\AppData\\Local\\Xeno\\workspace\\PETS_DATA.json"
            },
            MAX_ATTEMPTS = 20
        },
        GAME = {
            HUGE_SELLING_BASE_ADDED_AMOUNT = 1190000,
            MINIMUM_PLAYERS = 11,
            MINIMUM_HUGE = 2,
            START_LOBBY_PLACE_ID = 8737899170,
            TRADING_PLAZA_PLACE_ID = 15502339080,
        },
        TELEPORT = {
            INSTANCE = {
                INVENTORY_BUTTON = Player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("BottomButtons"):WaitForChild("BUTTONS"):WaitForChild("Inventory"),
                MESSAGE_GUI = Player:WaitForChild("PlayerGui"):WaitForChild("Message"),
                CAMERA = game.Workspace:WaitForChild("Camera")
            },
            POSITION = {
                HRT = CFrame.new(-918.189453, 284.012909, -2345.07007, 0.837983489, -1.24378534e-08, -0.545695603, 2.95825231e-08, 1, 2.26349854e-08, 0.545695603, -3.51107978e-08, 0.837983489),
                CAMERA = CFrame.new(-918.535828, 280.984528, -2344.35449, 0.900078893, -0.429107338, -0.0756634474, 0, 0.173648745, -0.98480773, 0.43572703, 0.886404634, 0.156297565),
                MESSAGE_GUI = UDim2.new(0.59, 0, 0.68, 0)
            },
            ACTION = {
                REHOP_SERVER = "RehopServer",
                TELEPORT_TO_OTHER_PLACE = "TeleportToOtherPlace"
            },
        },
        STATE = {
            GETTING_PLAYER_DATA = "GettingPlayerData",
            BUYING = "Buying",
            SELLING = "Selling",
            IDLE = "Idle"
        },
        WAIT = {
            SHORT = 0.5,
            NORMAL = 1,
            LONG = 5,
        },
    }


    if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
        Const.GAME.TRADING_PLAZA_ENTER_PORTAL_POSITION = game.Workspace:WaitForChild("Map"):WaitForChild("3 | Castle"):WaitForChild("INTERACT"):WaitForChild("TradingPlazaPortal"):WaitForChild("Enter").Position
    end


    --// Intialize Variables, Functions, Events
    local Data
    local PlayerData = {}


    --// Intialize Functions
    local function Teleport(TeleportToPerform)
        if TeleportToPerform == Const.TELEPORT.ACTION.REHOP_SERVER then
            TPS:TeleportAsync(game.PlaceId, {Player})
        elseif TeleportToPerform == Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE then
            if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
                HRT.Position = Const.GAME.TRADING_PLAZA_ENTER_PORTAL_POSITION
            else
                HRT:PivotTo(Const.TELEPORT.POSITION.HRT)
                Const.TELEPORT.INSTANCE.CAMERA.CFrame = Const.TELEPORT.POSITION.CAMERA
                Const.TELEPORT.INSTANCE.MESSAGE_GUI.Position = Const.TELEPORT.POSITION.MESSAGE_GUI
                Const.TELEPORT.INSTANCE.INVENTORY_BUTTON:Destroy()
                for _, GUI in pairs(Player.PlayerGui:GetChildren()) do
                    if GUI.ClassName == "ScreenGui" then
                        GUI.Enabled = false
                    end
                end
            end
        end
    end


    local function BuyItem(UserId, ItemId)
        game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer({
            UserId,	-- Buying from Player.UserId
            {
                [ItemId] = 1 -- ItemId, Amount
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
        })
        task.wait(Const.WAIT.SHORT)
    end


    local function ScanMarketplace()
        local ToBuy = {}
        local RunningThreads = 0
        for _, Booth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
            if not Booth.Parent then
                continue
            end
            local Pets = Booth:FindFirstChild("Pets")
            local BoothTop = Pets and Pets:FindFirstChild("BoothTop")
            local PetScroll = BoothTop and BoothTop:FindFirstChild("PetScroll")
            if not PetScroll then
                continue
            end
            RunningThreads += 1
            task.spawn(function()
                for _, Item in ipairs(PetScroll:GetChildren()) do
                    if Item.Parent and Item.ClassName == "Frame" and Data[Item.Holder.ItemSlot.Icon.Image] ~= nil then
                        table.insert(ToBuy, {
                            Owner = Booth:GetAttribute("Owner"),
                            Item = Item,
                            ItemId = Item.Name
                        })    
                    end
                end
                task.wait()
                RunningThreads -= 1
            end)
        end
        while RunningThreads > 0 do
            task.wait()
        end
        for _, ItemToBuy in ipairs(ToBuy) do
            if ItemToBuy.Item and ItemToBuy.Item.Parent then
                while ItemToBuy.Item:FindFirstChild("CircularBar") do
                    task.wait()
                end
                if ItemToBuy.Item.Parent then
                    BuyItem(ItemToBuy.Owner, ItemToBuy.ItemId)
                end
            end
        end
        task.wait(Const.WAIT.NORMAL)
        Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
    end


    local function IsServerViable()
        return #Players:GetChildren() >= Const.GAME.MINIMUM_PLAYERS
    end


    local function ClaimBooth()
        repeat
            local BoothId = Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()[1]:GetAttribute("ID")
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_ClaimBooth"):InvokeServer(tostring(BoothId))
        until (function()
            task.wait(Const.WAIT.NORMAL)
            for _, ClaimedBooth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
                if ClaimedBooth.Owner == tostring(Player.UserId) then
                    return true
                end
            end
            return false
        end)()
    end


    local function GetAPIData()
        local Attempts = 0
        repeat
            local Success, Result = pcall(function()
                return game:HttpGet(Const.DATA.API)
            end)
            if Success and Result ~= nil then
                Data = HttpService:JSONDecode(Result)
                Data.LAST_API_REQUEST = os.time()
                return
            else
                task.wait(Const.WAIT.SHORT)
            end
            Attempts += 1
        until Attempts >= Const.DATA.MAX_ATTEMPTS
        if Data == nil then
            Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
        end
    end


    local function GetPlayerData()
        if game.PlaceId == Const.GAME.TRADING_PLAZA_PLACE_ID then
            Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
        end
        while not Const.INSTANCE.PLAYER_INVENTORY.Enabled do
            task.wait()
        end
        for _, Pet in ipairs(Const.INSTANCE.EQUIPPED_PETS:GetChildren()) do
            if Pet.ClassName == "TextButton" and Pet.Strength.ContentText == "???" then
                if Data[Pet.Icon.Image] ~= nil then
                    PlayerData.Pets[tostring(Pet:GetAttribute("PetUID"))] = Data[Pet.Icon.Image]
                    PlayerData.HugeAmount += 1
                end
            end
        end
        PlayerData.PlayerState = Const.STATE.IDLE
        Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
    end


    local function CreateListing()
        local ListedItems
        for _, ClaimedBooth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
            if ClaimedBooth.Owner == tostring(Player.UserId) then
                ListedItems = ClaimedBooth:WaitForChild("Pets"):WaitForChild("BoothTop"):WaitForChild("PetScroll")
            end
        end
        for Hash, Value in pairs(PlayerData) do
            local args = {
                Hash,                                                   -- ItemId
                Value + Const.GAME.HUGE_SELLING_BASE_ADDED_AMOUNT,	    -- Price
                1									                    -- Amount	
            }
            workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):WaitForChild("Model"):WaitForChild("Pets"):WaitForChild("Booths_CreateListing"):InvokeServer(unpack(args))
            task.wait(Const.WAIT.SHORT)
        end
        if not (PlayerData.HugeAmount == #ListedItems:GetChildren()) then
            GetPlayerData()
        end
    end


    --// Initialize Events
    Players.PlayerRemoving:Connect(function(LeavingPlayer)
        if LeavingPlayer.UserId == UserId then
            local _, _ = pcall(function()
                writefile(Const.DATA.PATH.PLAYER_INV, HttpService:JSONEncode(PlayerData))
            end)
            local _, _ = pcall(function()
                writefile(Const.DATA.PATH.PETS_DATA, HttpService:JSONEncode(Data))
            end)
        end
    end)

    Player.CharacterAdded:Connect(function(NewCharacter)
        Character = NewCharacter
        HRT = Character:WaitForChild("HumanoidRootPart")
    end)


    --// Initialize Tasks
    local Tasks = {
        API = {
            Counter = 0,
            Interval = 180,
            Callback = GetAPIData,
        },
        SeverViable = {
            Counter = 0,
            Interval = 30,
            Callback = IsServerViable,
        }
    }


    --// Process
    local function Process()
        local LoopTime = Const.WAIT.SHORT
        while task.wait(LoopTime) do
            for _, Task in pairs(Tasks) do
                Task.Counter += LoopTime
                if Task.Counter >= Task.Interval then
                    Task.Counter = 0
                    Task.Callback()
                end
            end
        end
    end


    --// Starting Code
    local function OnCreate()
        --// Get Data
        local Success, Result = pcall(function()
            return readfile(Const.DATA.PATH.PETS_DATA)
        end)
        if Success and Result ~= nil then
            Data = HttpService:JSONDecode(Result)
            if os.time() - (Data.LAST_API_REQUEST or os.time()) >= Tasks.API.Interval then
                GetAPIData()
            end
        else
            GetAPIData()
        end
        --// Get Player Data
        local Success, Result = pcall(function()
            return readfile(Const.DATA.PATH.PLAYER_INV)
        end)
        if Success and Result ~= nil then
            PlayerData = HttpService:JSONDecode(Result)
            if PlayerData.PlayerState == nil or PlayerData.HugeAmount == nil or PlayerData.Pets == nil or PlayerData.PlayerState == Const.STATE.GETTING_PLAYER_DATA then
                PlayerData = {
                    HugeAmount = 0,
                    Pets = {},
                    PlayerState = Const.STATE.GETTING_PLAYER_DATA
                }
                GetPlayerData()
            end
        else
            PlayerData = {
                HugeAmount = 0,
                Pets = {},
                PlayerState = Const.STATE.GETTING_PLAYER_DATA
            }
            GetPlayerData()
        end
        --// Decide PlayerState
        if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
            Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
        end
        if PlayerData.HugeAmount >= Const.GAME.MINIMUM_HUGE then
            PlayerData.PlayerState = Const.STATE.SELLING
        else
            PlayerData.PlayerState = Const.STATE.BUYING
        end
        --// Perform Actions based on PlayerState
        if PlayerData.PlayerState == Const.STATE.BUYING then
            ScanMarketplace()
        elseif PlayerData.PlayerState == Const.STATE.SELLING then
            if IsServerViable() then
                ClaimBooth()
                CreateListing()
                Process()
            else
                Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
            end
            return
        end
    end
    OnCreate()
end
