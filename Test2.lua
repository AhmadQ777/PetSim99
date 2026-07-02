local button = game.Players.LocalPlayer.PlayerGui:WaitForChild("InventorySelect"):WaitForChild("Frame"):WaitForChild("Main"):WaitForChild("FilteredItems"):WaitForChild("Filters"):WaitForChild("Pet"):WaitForChild("Holder"):GetChildren()[2]
local Input = {
    UserInputType = Enum.UserInputType.MouseButton1,
    UserInputState = Enum.UserInputState.Begin,
}
firesignal(button.InputBegan, Input)
task.wait(0.1)
firesignal(button.InputEnded, Input)