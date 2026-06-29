--// Main
--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--// Player
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HRT = Character:WaitForChild("HumanoidRootPart")
local UserId = Player.UserId

--// Decalaring Const Variables
local Const = {
    GAME = {
        HUGE_SELLING_BASE_ADDED_AMOUNT = 1190000,
        MINIMUM_BUYING_HUGE_UNDER_PRICE = 500000,
        MINIMUM_HUGES_TO_SELL = 3,
        MAX_PRICE_BUYING_HUGE = 30000000,
        MINIMUM_PLAYERS = 12,
        START_LOBBY_PLACE_ID = 8737899170,
        TRADING_PLAZA_PLACE_ID = 15502339080,
    },
    TELEPORT = {
        POSITION = {
            HRT = CFrame.new(-918.189453, 284.012909, -2345.07007, 0.837983489, -1.24378534e-08, -0.545695603, 2.95825231e-08, 1, 2.26349854e-08, 0.545695603, -3.51107978e-08, 0.837983489),
        },
        ACTION = {
            REHOP_SERVER = "RehopServer",
            TELEPORT_TO_OTHER_PLACE = "TeleportToOtherPlace"
        },
    },
    WAIT = {
        SUPER_SHORT = 0.1,
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
local HugeAmount = 0


--// Intialize Functions
local function Teleport(TeleportToPerform)
    print("[Teleport] Called:", TeleportToPerform)

    if TeleportToPerform == Const.TELEPORT.ACTION.REHOP_SERVER then
        print("[Teleport] REHOP_SERVER")
        if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
        else    
            HRT:PivotTo(game.Workspace:WaitForChild("TradingPlaza"):WaitForChild("INTERACT"):WaitForChild("Machines"):WaitForChild("TradingTerminal_Machine"):WaitForChild("PadDecor").CFrame)
        end

    elseif TeleportToPerform == Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE then
        task.wait(Const.WAIT.NORMAL)
        print("[Teleport] TELEPORT_TO_OTHER_PLACE")
        --// Telport to other place
        if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
            print("[Teleport] START_LOBBY_PLACE_ID")
            HRT.Position = Const.GAME.TRADING_PLAZA_ENTER_PORTAL_POSITION
        else
            print("[Teleport] TRADING_PLAZA_PLACE_ID")
            repeat
                HRT:PivotTo(Const.TELEPORT.POSITION.HRT)
                task.wait(Const.WAIT.SHORT)    
            until (HRT.Position - Const.TELEPORT.POSITION.HRT).Magnitude < 5
            firesignal(Player.PlayerGui:WaitForChild("Interact"):WaitForChild("Button").Activated)
            local Message = Player.PlayerGui:WaitForChild("Message")
            while not Message.Enabled do
                Message:GetPropertyChangedSignal("Enabled"):Wait()
            end
            firesignal(Message:WaitForChild("Frame"):WaitForChild("Contents"):WaitForChild("Yes").Activated)
        end
    end
end


local function ConvertNumber(Text)
    print("[ConvertNumber] Input:", Text)
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
    local Result = Number * Multiplier
    print("[ConvertNumber] Output:", Result)
    return Result
end


local function IsServerViable()
    local PlayerCount = #Players:GetChildren()
    print("[IsServerViable] Players:", PlayerCount, "Required:", Const.GAME.MINIMUM_PLAYERS)
    return PlayerCount >= Const.GAME.MINIMUM_PLAYERS
end


local function BuyItem(UserId, ItemId)
    print("[BuyItem] UserId:", UserId, "ItemId:", ItemId)
    game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_RequestPurchase"):InvokeServer({
        UserId,
        {
            [ItemId] = 1
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
    print("[BuyItem] Request Sent")
    task.wait(Const.WAIT.SHORT)
end


local function ClaimBooth()
    print("[ClaimBooth] Started")
    repeat
        local BoothId
        repeat
            BoothId = game.Workspace:WaitForChild("TradingPlaza"):WaitForChild("BoothSpawns"):GetChildren()[1]:GetAttribute("ID")
            if BoothId == nil then
                task.wait(Const.WAIT.SHORT)
            end
        until BoothId ~= nil
        print("[ClaimBooth] Trying Booth:", BoothId)
        game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Booths_ClaimBooth"):InvokeServer(tostring(BoothId))
    until (function()
        task.wait(Const.WAIT.NORMAL)
        for _, ClaimedBooth in ipairs(game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):GetChildren()) do
            if ClaimedBooth:GetAttribute("Owner") == UserId then
                print("[ClaimBooth] Success")
                return true
            end
        end
        print("[ClaimBooth] Retry")
        return false
    end)()
end


local function FireUntilProperty(Signal, Object, Property, Value)
    firesignal(Signal)
    if Object[Property] == Value then
        return
    end
    local WaitedTime = 0
    while task.wait(Const.WAIT.SUPER_SHORT) do
        if Object[Property] == Value then
            break
        end
        WaitedTime += Const.WAIT.SUPER_SHORT
        if WaitedTime >= Const.WAIT.NORMAL then
            WaitedTime = 0
            firesignal(Signal)
        end
    end
end


local function CreateListing()
    print("[CreateListing] Started")
    local ListedItems
    local OwnedBooth 
    for _, ClaimedBooth in ipairs(game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):GetChildren()) do
        if ClaimedBooth:GetAttribute("Owner") == UserId then
            print("[CreateListing] Found Owned Booth")
            OwnedBooth = ClaimedBooth
            ListedItems = ClaimedBooth:WaitForChild("Pets"):WaitForChild("BoothTop"):WaitForChild("PetScroll")
            break
        end
    end
    print("[CreateListing] GETTING ALL VARIABLES NEEDED")
    local BoothPrompt = Player.PlayerGui:WaitForChild("BoothPrompt")
    local PostButton = BoothPrompt:WaitForChild("Frame"):WaitForChild("Slots"):WaitForChild("Items"):WaitForChild("SlotsSection"):WaitForChild("Slots"):WaitForChild("Post"):WaitForChild("Post")
    local TextInput = Player.PlayerGui:WaitForChild("_MISC"):WaitForChild("TextInput")
    local PriceInput = TextInput:WaitForChild("Frame"):WaitForChild("Contents"):WaitForChild("CURRENCY"):WaitForChild("Input"):WaitForChild("Input")
    local SubmitButton = TextInput:WaitForChild("Frame"):WaitForChild("Contents"):WaitForChild("CURRENCY"):WaitForChild("Ok")
    local Message = Player.PlayerGui:WaitForChild("Message")
    local AcceptButton = Message:WaitForChild("Frame"):WaitForChild("Contents"):WaitForChild("Yes")
    print("[CreateListing] Opening Booth Menu")
    HRT.Position = OwnedBooth.Interact.Position
    FireUntilProperty(
        Player.PlayerGui:WaitForChild("Interact"):WaitForChild("Button").Activated,
        BoothPrompt,
        "Enabled",
        true
    )
    for _ = 1,HugeAmount do
        print("[CreateListing] 1")
        task.wait(Const.WAIT.NORMAL)
        firesignal(PostButton.Activated)
        local Pets = Player.PlayerGui:WaitForChild("InventorySelect"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("FilteredItems"):WaitForChild("Filters"):WaitForChild("Pet"):WaitForChild("Holder")
        while Pets:GetChildren() == nil or #Pets:GetChildren() - 1 == 0 do
            task.wait()
        end
        for _, Pet in ipairs(Pets:GetChildren()) do
            if Pet.ClassName == "TextButton" and Pet.Strength.Text == "???" then
                local Image = Pet.Icon.Image
                print("[CreateListing] 2")
                FireUntilProperty(
                    Pet.Activated,
                    Player.PlayerGui:WaitForChild("InventorySelect"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("Confirm"),
                    "Visible",
                    true
                )
                print("[CreateListing] 3")
                FireUntilProperty(
                    Player.PlayerGui:WaitForChild("InventorySelect"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("Confirm").Activated,
                    TextInput,
                    "Enabled",
                    true
                )
                print("[CreateListing] 4")
                PriceInput.Text = tostring((Data[Image] or 35000000) + Const.GAME.HUGE_SELLING_BASE_ADDED_AMOUNT)
                FireUntilProperty(
                    SubmitButton.Activated,
                    Message,
                    "Enabled",
                    true
                )
                break
            end
        end
    end
    print("[CreateListing] HugeAmount:", HugeAmount)
    print("[CreateListing] Listed Children:", #ListedItems:GetChildren() - 2)
    if HugeAmount ~= #ListedItems:GetChildren() - 2 then
        Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
        print("[CreateListing] Amount Mismatch -> Rehop")
        print("[CreateListing] Finished")
        return
    end
    print("[CreateListing] Finished")
end


local function ScanMarketplace()
    print("[ScanMarketplace] Started")
    local ToBuy = {}
    for _, Booth in ipairs(game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):GetChildren()) do
        local Pets = Booth:FindFirstChild("Pets")
        local BoothTop = Pets and Pets:FindFirstChild("BoothTop")
        local PetScroll = BoothTop and BoothTop:FindFirstChild("PetScroll")
        if not PetScroll then
            continue
        end
        for _, Item in ipairs(PetScroll:GetChildren()) do
            if Item.Parent and Item.ClassName == "Frame" and Data[Item.Holder.ItemSlot.Icon.Image] ~= nil and Data[Item.Holder.ItemSlot.Icon.Image] <= Const.GAME.MAX_PRICE_BUYING_HUGE and Data[Item.Holder.ItemSlot.Icon.Image] - Const.GAME.MINIMUM_BUYING_HUGE_UNDER_PRICE >= ConvertNumber(Item.Buy.Cost.ContentText) then
                print(
                    "[ScanMarketplace] Found Candidate:",
                    Item.Name,
                    "Value:",
                    Data[Item.Holder.ItemSlot.Icon.Image],
                    "Price:",
                    ConvertNumber(Item.Buy.Cost.ContentText)
                )
                table.insert(ToBuy, {
                    Owner = Booth:GetAttribute("Owner"),
                    Item = Item,
                })
            end
        end
    end
    print("[ScanMarketplace] Candidates:", #ToBuy)
    for _, ItemToBuy in ipairs(ToBuy) do
        if ItemToBuy.Item and ItemToBuy.Item.Parent then
            print("[ScanMarketplace] Checking:", ItemToBuy.Item.Name)
            if Player:WaitForChild("leaderstats"):WaitForChild("💎 Diamonds").Value < ConvertNumber(ItemToBuy.Item.Buy.Cost.ContentText) then
                print("[ScanMarketplace] Not Enough Diamonds")
                continue
            end
            while ItemToBuy.Item.Parent and ItemToBuy.Item:FindFirstChild("CircularBar") do
                print("[ScanMarketplace] Waiting CircularBar:", ItemToBuy.Item.Name)
                task.wait()
            end
            if ItemToBuy.Item.Parent then
                print("[ScanMarketplace] Buying:", ItemToBuy.Item.Name)
                BuyItem(ItemToBuy.Owner, ItemToBuy.Item.Name)
                HugeAmount += 1
                print("[ScanMarketplace] HugeAmount:", HugeAmount)
            end
            if HugeAmount >= Const.GAME.MINIMUM_HUGES_TO_SELL then
                print("[ScanMarketplace] Enough Huges Sell Huges")
                if IsServerViable() then
                    ClaimBooth()
                    CreateListing()
                    Process()
                    return
                else
                    break
                end
            end
        end
    end
    print("[ScanMarketplace] Finished -> Rehop")
    task.wait(Const.WAIT.NORMAL)
    Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
end


--// Process
function Process()
    print("[Process] Started")
    local ListedItems
    for _, ClaimedBooth in ipairs(game.Workspace:WaitForChild("__THINGS"):WaitForChild("Booths"):GetChildren()) do
        if ClaimedBooth:GetAttribute("Owner") == UserId then
            print("[Process] Found Owned Booth")
            ListedItems = ClaimedBooth:WaitForChild("Pets"):WaitForChild("BoothTop"):WaitForChild("PetScroll")
            break
        end
    end
    ListedItems.ChildRemoved:Connect(function(Obj)
        if Obj.ClassName == "Frame" then
            HugeAmount -= 1
        end
        if HugeAmount <= 1 then
            print("[Process] HugeAmount <= 1 -> ScanMarketplace()")
            ScanMarketplace()
        end
    end)
    while task.wait(30) do
        print("[Process] Server Check")
        if not IsServerViable() then
            print("[Process] Server Not Viable -> Rehop")
            Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
        end
    end
end


--// Starting Code
local function OnCreate()
    task.wait(Const.WAIT.LONG)
    print("[OnCreate] Started")
    print("[OnCreate] PlaceId:", game.PlaceId)
    

    --// if not Trading Plaza then teleport there
    if game.PlaceId == Const.GAME.START_LOBBY_PLACE_ID then
        print("[OnCreate] In Start Lobby")
        Teleport(Const.TELEPORT.ACTION.TELEPORT_TO_OTHER_PLACE)
        return
    end


    --// Remove Changelog
    print("[Changelog] Setting up GetPropertyChangedSignal")
    local Changelog = Player.PlayerGui:WaitForChild("Changelog")
    Changelog:GetPropertyChangedSignal("Enabled"):Connect(function()
        if Changelog.Enabled then
            firesignal(Changelog:WaitForChild("Frame"):WaitForChild("ContentFrame"):WaitForChild("Ok").Activated)
        end
    end)


    --// Remove Loginstreak
    print("[LoginStreak] Setting up GetPropertyChangedSignal")
    local LoginStreak = Player.PlayerGui:WaitForChild("LoginStreak")
    LoginStreak:GetPropertyChangedSignal("Enabled"):Connect(function()
        if LoginStreak.Enabled then
            firesignal(LoginStreak:WaitForChild("Frame"):WaitForChild("ItemsFrame"):WaitForChild("Free"):WaitForChild("Button").Activated)
        end
    end)


    --// Get Data
    print("[GetData] Trying to load Data")
    local MAX_OLDEST_DATA = 600
    repeat
        local Success, Result = pcall(readfile, "/storage/emulated/0/Delta/Workspace/PETS_DATA.json")
        if Success or Result ~= nil then
            Data = HttpService:JSONDecode(Result)
            if Data.LastSuccessfulAPIRequest ~= nil and os.time() - Data.LastSuccessfulAPIRequest < MAX_OLDEST_DATA then
                break
            end
            task.wait(Const.WAIT.LONG)
        end
    until false
    print("[GetData] PETS_DATA Loaded")


    --// Get HugeAmount
    print("[HugeAmount] Started")
    firesignal(Player.PlayerGui:WaitForChild("Main"):WaitForChild("BottomButtons"):WaitForChild("BUTTONS"):WaitForChild("Inventory").Activated)
    local Pets = Player.PlayerGui:WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("Pets"):WaitForChild("Pets")
    while Pets:GetChildren() == nil or #Pets:GetChildren() - 1 == 0 do
        task.wait()
    end
    for _, Item in ipairs(Pets:GetChildren()) do
        if Item.ClassName == "TextButton" and Item:WaitForChild("Strength").Text == "???" then
            HugeAmount += 1
        end
    end
    task.wait(Const.WAIT.NORMAL)
    firesignal(Player.PlayerGui:WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Close").Activated)
    Player.PlayerGui:WaitForChild("Inventory").Enabled = false
    task.wait()
    print("[HugeAmount] " , HugeAmount)
    print("[HugeAmount] Finished")


    --// Perform Actions based on HugeAmount
    print("[OnCreate] Perform Actions based on")  
    if HugeAmount < Const.GAME.MINIMUM_HUGES_TO_SELL then
        print("[OnCreate] Execute BUYING")
        ScanMarketplace()
    else
        print("[OnCreate] Execute SELLING")
        if IsServerViable() then
            print("[OnCreate] Server Viable")
            ClaimBooth()
            CreateListing()
            Process()
        else
            print("[OnCreate] Server Not Viable")
            Teleport(Const.TELEPORT.ACTION.REHOP_SERVER)
        end
    end
end

OnCreate()

