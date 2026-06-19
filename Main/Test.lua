local TPS = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
TPS:TeleportAsync(game.PlaceId, Player)