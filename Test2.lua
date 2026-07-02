local button = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("Interact"):WaitForChild("Button")
local input = {
    UserInputType = Enum.UserInputType.MouseButton1,
    UserInputState = Enum.UserInputState.Begin,
}
firesignal(button.InputBegan, input)
print("1")
task.wait(15)
input.UserInputState = Enum.UserInputState.End
firesignal(button.InputEnded, input)
print("2")