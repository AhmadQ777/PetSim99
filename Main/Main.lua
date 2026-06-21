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

    --// Decalaring Const Variables
    local Const = {
        INSTANCE = {
            DIAMONDS = Player:WaitForChild("leaderstats"):WaitForChild("💎 Diamonds"),
            PLAYER_INVENTORY = Player:WaitForChild("PlayerGui"):WaitForChild("Inventory"),
            EQUIPPED_PETS = Player:WaitForChild("PlayerGui"):WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("Pets"):WaitForChild("EquippedPets"),
            CLAIMED_BOOTHS = game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"),
            CHECK_UNCLAIMED_BOOTHS = TradingPlaza and TradingPlaza:FindFirstChild("BoothSpawns"),
        },
        DATA = {
            PATH = {
                PLAYER_INV = "/storage/emulated/0/Delta/Workspace/PLAYER_INV.json",
                PETS_DATA = "/storage/emulated/0/Delta/Workspace/PETS_DATA.json",
            },
            MAX_OLDEST_PETS_DATA = 600
        },
        GAME = {
            HUGE_SELLING_BASE_ADDED_AMOUNT = 1190000,
            MINIMUM_BUYING_HUGE_UNDER_PRICE = 500000,
            MINIMUM_HUGES_TO_SELL = 3,
            MAX_PRICE_BUYING_HUGE = 30000000,
            MINIMUM_PLAYERS = 11,
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
    local PlayerData


    --// Intialize Functions
    local function Teleport(TeleportToPerform)
        if TeleportToPerform == Const.TELEPORT.ACTION.REHOP_SERVER then
            --// Rehop Servers
            local Attempts = 0
            while Player and Player.Parent do
                pcall(function()
                    TPS:TeleportAsync(game.PlaceId, {Player})
                end)
                Attempts += 1
                task.wait(math.min(2^Attempts, 30))
            end
        elseif TeleportToPerform == Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE then
            --// Telport to other place
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


    local function GetPlayerData()
        if game.PlaceId == Const.GAME.TRADING_PLAZA_PLACE_ID then
            Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
            return
        end
        if not Const.INSTANCE.PLAYER_INVENTORY.Enabled then
            Const.INSTANCE.PLAYER_INVENTORY:GetPropertyChangedSignal("Enabled"):Wait()
        end
        for _, Item in ipairs(Const.INSTANCE.EQUIPPED_PETS:GetChildren()) do
            if Item.ClassName == "TextButton" then
                if Item:WaitForChild("Strength").ContentText == "???" then
                    PlayerData.Pets[tostring(Item:GetAttribute("PetUID"))] = Item:WaitForChild("Icon").Image
                    PlayerData.HugeAmount += 1
                end
            end
        end
        PlayerData.PlayerState = Const.STATE.IDLE
        Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
    end


    local function ConvertNumber(Text)
        Text = tostring(Text):upper()
        local Multipliers = {
            K = 1e3,
            M = 1e6,
            B = 1e9,
            T = 1e12,
        }
        local Number, Suffix = Text:match("([%d%.]+)(%a?)")
        Number = tonumber(Number)
        local Multiplier = Multipliers[Suffix] or 1
        return Number * Multiplier
    end


    local function IsServerViable()
        return #Players:GetChildren() >= Const.GAME.MINIMUM_PLAYERS
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


    local function ClaimBooth()
        repeat
            local BoothId = Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()[1]:GetAttribute("ID")
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_ClaimBooth"):InvokeServer(tostring(BoothId))
        until (function()
            task.wait(Const.WAIT.NORMAL)
            for _, ClaimedBooth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
                if ClaimedBooth:GetAttribute("Owner") == UserId then
                    return true
                end
            end
            return false
        end)()
    end


    local function CreateListing()
        local ListedItems
        for _, ClaimedBooth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
            if ClaimedBooth:GetAttribute("Owner") == UserId then
                ListedItems = ClaimedBooth:WaitForChild("Pets"):WaitForChild("BoothTop"):WaitForChild("PetScroll")
                break
            end
        end
        for Hash, Value in pairs(PlayerData.Pets) do
            local args = {
                Hash,                                                                       -- ItemId
                (Data[Value] or 35000000) + Const.GAME.HUGE_SELLING_BASE_ADDED_AMOUNT,	    -- Price
                1						                    			                    -- Amount	
            }
            workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):WaitForChild("Model"):WaitForChild("Pets"):WaitForChild("Booths_CreateListing"):InvokeServer(unpack(args))
            task.wait(Const.WAIT.SHORT)
        end
        if PlayerData.HugeAmount ~= #ListedItems:GetChildren() then
            GetPlayerData()
        end
    end


    local function ScanMarketplace()
        local ToBuy = {}
        for _, Booth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
            local Pets = Booth:FindFirstChild("Pets")
            local BoothTop = Pets and Pets:FindFirstChild("BoothTop")
            local PetScroll = BoothTop and BoothTop:FindFirstChild("PetScroll")
            if not PetScroll then
                continue
            end
            for _, Item in ipairs(PetScroll:GetChildren()) do
                if Item.Parent and Item.ClassName == "Frame" and Data[Item.Holder.ItemSlot.Icon.Image] ~= nil and Data[Item.Holder.ItemSlot.Icon.Image] <= Const.GAME.MAX_PRICE_BUYING_HUGE and Data[Item.Holder.ItemSlot.Icon.Image] - Const.GAME.MINIMUM_BUYING_HUGE_UNDER_PRICE >= ConvertNumber(Item.Buy.Cost.ContentText) then
                    table.insert(ToBuy, {
                        Owner = Booth:GetAttribute("Owner"),
                        Item = Item,
                    })
                end
            end
        end
        for _, ItemToBuy in ipairs(ToBuy) do
            if ItemToBuy.Item and ItemToBuy.Item.Parent then
                if Const.INSTANCE.DIAMONDS.Value < ConvertNumber(ItemToBuy.Item.Buy.Cost.ContentText) then
                    continue
                end
                while ItemToBuy.Item.Parent and ItemToBuy.Item:FindFirstChild("CircularBar") do
                    task.wait(0.1)
                end
                if ItemToBuy.Item.Parent then
                    BuyItem(ItemToBuy.Owner, ItemToBuy.Item.Name)
                    PlayerData.Pets[ItemToBuy.Item.Name] = ItemToBuy.Item.Holder.ItemSlot.Icon.Image
                    PlayerData.HugeAmount += 1
                end
                if PlayerData.HugeAmount >= Const.GAME.MINIMUM_HUGES_TO_SELL then
                    GetPlayerData()
                    return
                end
            end
        end
        task.wait(Const.WAIT.NORMAL)
        Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
    end

   



    --// Initialize Events
    Players.PlayerRemoving:Connect(function(LeavingPlayer)
        if LeavingPlayer.UserId == UserId then
            pcall(function()
                writefile(Const.DATA.PATH.PLAYER_INV, HttpService:JSONEncode(PlayerData))
            end)
        end
    end)

    Player.CharacterAdded:Connect(function(NewCharacter)
        Character = NewCharacter
        HRT = Character:WaitForChild("HumanoidRootPart")
    end)


    --// Process
    function Process()
        local ListedItems
        for _, ClaimedBooth in ipairs(Const.INSTANCE.CLAIMED_BOOTHS:GetChildren()) do
            if ClaimedBooth:GetAttribute("Owner") == UserId then
                ListedItems = ClaimedBooth:WaitForChild("Pets"):WaitForChild("BoothTop"):WaitForChild("PetScroll")
                break
            end
        end
        ListedItems.ChildRemoved:Connect(function(Obj)
            PlayerData.Pets[Obj.Name] = nil
            PlayerData.HugeAmount -= 1
            if PlayerData.HugeAmount <= 1 then
                ScanMarketplace()
            end
        end)
        while task.wait(30) do
            if not IsServerViable() then
                Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
            end
        end
    end


    --// Starting Code
    local function OnCreate()

        --// Get Data
        local Success, Result = pcall(readfile, Const.DATA.PATH.PETS_DATA)
        if Success and Result ~= nil then
            Data = HttpService:JSONDecode(Result)
            if os.time() - Data.LastSuccessfullAPIRequest >= Const.DATA.MAX_OLDEST_PETS_DATA then
                Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
                return
            end
        else
            Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
            return
        end

        --// Get Player Data
        local Success, Result = pcall(readfile, Const.DATA.PATH.PLAYER_INV)
        if Success and Result ~= nil then
            PlayerData = HttpService:JSONDecode(Result)
            if PlayerData.PlayerState == nil or PlayerData.HugeAmount == nil or PlayerData.Pets == nil or PlayerData.PlayerState == Const.STATE.GETTING_PLAYER_DATA then
                PlayerData = {
                    HugeAmount = 0,
                    Pets = {},
                    PlayerState = Const.STATE.GETTING_PLAYER_DATA
                }
                GetPlayerData()
                return
            end
        else
            PlayerData = {
                HugeAmount = 0,
                Pets = {},
                PlayerState = Const.STATE.GETTING_PLAYER_DATA
            }
            GetPlayerData()
            return
        end

        --// Decide PlayerState
        if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
            Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
        end
        if PlayerData.HugeAmount >= Const.GAME.MINIMUM_HUGES_TO_SELL then
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
        end
    end
    OnCreate()
end
