return function ()
    --// Main
    --// Services
    print("-----------")
    print("Services")

    local RS = game:GetService("RunService")
    local TPS = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")

    --// Player
    print("Player")
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local HRT = Character:WaitForChild("HumanoidRootPart")
    local UserId = Player.UserId


    --// Initialize Varaibles to check
    local TradingPlaza = game.Workspace:FindFirstChild("TradingPlaza")

    --// Const Variables
    print("Const")
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
                PLAYER_INV = "C:\\Users\\Amira\\AppData\\Local\\Xeno\\workspace\\PLAYER_INV.json";
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
            GETTING_PLAYER_INVENTORY = "GettingPlayerInventory",
            SEARCHING_IDEAL_SERVER_TO_SELL = "SearchIdealServerToSell",
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
    --// API Request/Data Handle Variables
    print("Variables")
    local Data
    local PlayerInv = {}
    local PlayerInventoryDataSaved = false
    local PlayerState = Const.STATE.IDLE


    --// Intialize Functions
    print("Functions")
    local function Teleport(TeleportToPerform)
        if TeleportToPerform == Const.TELEPORT.ACTION.REHOP_SERVER then
            TPS:TeleportAsync(game.PlaceId, {Player})
        elseif TeleportToPerform == Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE then
            if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
                HRT.Position = Const.GAME.TRADING_PLAZA_ENTER_PORTAL_POSITION
            elseif game.PlaceId == Const.GAME.TRADING_PLAZA_PLACE_ID then
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
    end


    local function ScanMarketplace()
        for _, Booth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
            for _, Item in ipairs(Booth.Pets.BoothTop.PetScroll:GetChildren()) do
                if Item.Holder.ItemSlot.Strength.ContentText == "???" and Item.ClassName == "Frame" and Data[Item.Holder.ItemSlot.Icon.Image] ~= nil then
                    BuyItem(Booth:GetAttribute("Owner"), Item.Name)
                    task.wait(Const.WAIT.SHORT)
                end
            end
        end
        Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
    end


    local function IsServerViable()
        return #Players:GetChildren() >= Const.GAME.MINIMUM_PLAYERS
    end


    local function CreateListing()
        for Hash, Value in pairs(PlayerInv) do
            local args = {
                Hash,                                                   -- ItemId
                Value + Const.GAME.HUGE_SELLING_BASE_ADDED_AMOUNT,	    -- Price
                1									                    -- Amount	
            }
            workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):WaitForChild("Model"):WaitForChild("Pets"):WaitForChild("Booths_CreateListing"):InvokeServer(unpack(args))
            task.wait(Const.WAIT.SHORT)
        end
    end


    local function ClaimBooth()
        repeat
            local BoothId = game.Workspace:FindFirstChild("TradingPlaza"):WaitForChild("BoothSpawns"):GetChildren()[1]:GetAttribute("ID")
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_ClaimBooth"):InvokeServer(tostring(BoothId))
        until (function()
            task.wait(Const.WAIT.SHORT)
            for _, ClaimedBooth in ipairs(game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):GetChildren()) do
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
            print("Starting API Request")
            local Success, Result = pcall(function()
                return game:HttpGet(Const.DATA.API)
            end)
            if Success and Result ~= nil then
                print("Success == true, Result ~= nil")
                Data = HttpService:JSONDecode(Result)
                Data.LAST_API_REQUEST = os.time()
                local _, _ = pcall(function()
                    writefile(Const.DATA.PATH.PETS_DATA, HttpService:JSONEncode(Data))
                end)
                print("Successfully Received Data")
                return
            else
                print("Success == false, Result == nil")
                task.wait(Const.WAIT.NORMAL)
            end
            Attempts += 1
        until Attempts >= Const.DATA.MAX_ATTEMPTS
        if Data == nil then
            print("Failed to Received Data")
            Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
        end
    end


    local function GetPlayerInventory()
        if game.PlaceId == Const.GAME.TRADING_PLAZA_PLACE_ID then
            print("Teleporting to other place because Player is in Trading Plaza")
            task.wait(15)
            Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
            return
        end
        print("Checking if Inv is enabled")
        while not Const.INSTANCE.PLAYER_INVENTORY.Enabled do
            task.wait(Const.WAIT.SHORT)
        end
        print("Getting all Huges")
        local HugeAmount = 0
        for _, Pet in ipairs(Const.INSTANCE.EQUIPPED_PETS:GetChildren()) do
            if Pet.ClassName == "TextButton" and Pet.Strength.ContentText == "???" then
                if Data[Pet.Icon.Image] ~= nil then
                    print(Data)
                    PlayerInv.Pets.[Pet:GetAttribute("PetUID")] = Data[Pet.Icon.Image]
                    HugeAmount += 1
                end
            end
        end
        PlayerInv.HugeAmount = HugeAmount
        PlayerInv.PlayerState = Const.STATE.IDLE
        print("Saving PlayerInv Data")
        local Success, _ = pcall(function()
            writefile(Const.DATA.PATH.PLAYER_INV, HttpService:JSONEncode(PlayerInv))
        end)
        if Success then PlayerInventoryDataSaved = true end
        print("Teleporting to other place because finished Getting Player Inv")
        task.wait(15)
        Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
    end



    --// Events
    print("EVENTS")
    Players.PlayerRemoving:Connect(function(LeavingPlayer)
        print("PlayerLeaving")
        if LeavingPlayer.UserId == UserId and not PlayerInventoryDataSaved then
            local _, _ = pcall(function()
                writefile(Const.DATA.PATH.PLAYER_INV, HttpService:JSONEncode(PlayerInv))
            end)
        end
    end)

    Player.CharacterAdded:Connect(function(NewCharacter)
        Character = NewCharacter
        HRT = Character:WaitForChild("HumanoidRootPart")
    end)


    --// Initialize Tasks
    print("Task")
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
    print("Process")
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
        print("------------")
        print("Get Data")
        local Success, Result = pcall(function()
            return readfile(Const.DATA.PATH.PETS_DATA)
        end)
        if Success and Result ~= nil then
            print("Get Data, Success == true")
            Data = HttpService:JSONDecode(Result)
            if os.time() - (Data.LAST_API_REQUEST or os.time()) >= Tasks.API.Interval then
                print("Have to get Data")
                GetAPIData()
            end
        else
            print("Get Data, Success == false")
            print("------------")
            GetAPIData()
            print("------------")
        end
        print("------------")
        print("------------")
        print("Get Player Inv")
        --// Get PlayerInventory
        local Success, Result = pcall(function()
            return readfile(Const.DATA.PATH.PLAYER_INV)
        end)
        if Success and Result ~= nil then
            print("Get Playeyer Inv, Success == true, Result ~= nil")
            PlayerInv = HttpService:JSONDecode(Result) 
            PlayerState = (PlayerInv.PlayerState or Const.STATE.IDLE)
        else
            print("Get Playeyer Inv, Success == false, Result == nil")
            PlayerInv.PlayerState = Const.STATE.GETTING_PLAYER_INVENTORY
            print("------------")
            GetPlayerInventory()
            print("------------")
            return
        end
        print("------------")

        print("------------")
        print("Decide over PlayerState")
        --// Decide PlayerState
        task.wait(15)
        if PlayerState ~= Const.STATE.GETTING_PLAYER_INVENTORY then
            if PlayerInv.HugeAmount >= Const.GAME.MINIMUM_HUGE then
                local Result = IsServerViable()
                if Result then
                    PlayerInv.PlayerState = Const.STATE.SELLING
                else
                    PlayerInv.PlayerState = Const.STATE.SEARCHING_IDEAL_SERVER_TO_SELL
                end
            else
                PlayerInv.PlayerState = Const.STATE.BUYING
            end
        end
        print("------------")

        --// Handle PlayerState and Assign Tasks
        if PlayerState == Const.STATE.BUYING then
            if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
                Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
                return
            end
            ScanMarketplace()
        elseif PlayerState == Const.STATE.SELLING then
            if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
                Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
                return
            end
            ClaimBooth()
            CreateListing()
        elseif PlayerState == Const.STATE.GETTING_PLAYER_INVENTORY then
            if game.PlaceId == Const.GAME.TRADING_PLAZA_PLACE_ID then
                Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
                return
            else
                GetPlayerInventory()
                return
            end
        elseif PlayerState == Const.STATE.SEARCHING_IDEAL_SERVER_TO_SELL then
            if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
                Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
                return
            end
            Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
            return
        end
        if PlayerState == Const.STATE.SELLING then
            print("Activating Process")
            Process()
        end
        print("Finished Create")
    end
    print("Create")
    OnCreate()

    task.wait(Const.WAIT.SHORT)
    print("PlayerState" .. PlayerState)
end
