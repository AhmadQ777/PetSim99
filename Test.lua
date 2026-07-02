local button = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("Interact"):WaitForChild("Button")
print("=== MOBILE BUTTON EVENTS")
local events = {
    Activated = button.Activated,
    MouseButton1Click = button.MouseButton1Click,
    MouseButton1Down = button.MouseButton1Down,
    MouseButton1Up = button.MouseButton1Up,
}
for eventName, signal in pairs(events) do
    local ok, connections = pcall(getconnections, signal)
    if ok then
        print(eventName .. " -> " .. #connections)
    else
        print(eventName .. " -> no access / unsupported")
    end
end