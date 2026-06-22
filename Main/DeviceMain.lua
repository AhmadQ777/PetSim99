local URL = "https://raw.githubusercontent.com/AhmadQ777/PetSim99/refs/heads/main/Main/Main.lua"
local Attempts = 0
while true do
    Attempts += 1
    local Ok, Function = pcall(function()
        local source = game:HttpGet(URL)
        return loadstring(source)
    end)
    if Ok and Function then
        local Success = pcall(Function)
        if Success then
            break
        end
    end
    task.wait(2 ^ math.clamp(Attempts, 1, 5))
end