repeat
    local Success, Error = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadQ777/PetSim99/refs/heads/main/Main/Main.lua"))()()
    end)
    if not Success then
        warn(Error)
    end
    print(Success)
    task.wait(1)
until Success