local button = game.Players.LocalPlayer.PlayerGui:WaitForChild("InventorySelect"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("FilteredItems"):WaitForChild("Filters"):WaitForChild("Pet"):WaitForChild("Holder"):GetChildren()[2]
local events = {
    Activated = button.Activated,

    MouseButton1Click = button.MouseButton1Click,
    MouseButton1Down = button.MouseButton1Down,
    MouseButton1Up = button.MouseButton1Up,

    MouseButton2Click = button.MouseButton2Click,
    MouseButton2Down = button.MouseButton2Down,
    MouseButton2Up = button.MouseButton2Up,

    MouseEnter = button.MouseEnter,
    MouseLeave = button.MouseLeave,
    MouseMoved = button.MouseMoved,

    SelectionGained = button.SelectionGained,
    SelectionLost = button.SelectionLost,

    TouchLongPress = button.TouchLongPress,

    InputBegan = button.InputBegan,
    InputChanged = button.InputChanged,
    InputEnded = button.InputEnded,
}

for name, signal in pairs(events) do
    local ok, connections = pcall(function()
        return signal:GetConnections()
    end)

    if ok then
        print(name, "Connections:", #connections)

        for i, conn in ipairs(connections) do
            print("  -> Connected:", conn.Connected, conn)
        end
    else
        print(name, "GetConnections not supported")
    end
end