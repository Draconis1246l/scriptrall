-- Carga de librerías Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Configuración inicial de Fluent
local Window = Fluent:CreateWindow({
    Title = "Server Manager",
    SubTitle = "By Joel",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Función para hacer rejoin correctamente
local function RejoinServer()
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    if not success then
        warn("Error al intentar rejoin:", err)
    end
end

-- Función para buscar y hacer ServerHop
local function ServerHop(morePlayers)
    local success, servers = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        return response.data
    end)

    if success and servers then
        for _, server in ipairs(servers) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                if morePlayers then
                    if server.playing >= 15 then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        return
                    end
                else
                    if server.playing <= 5 then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        return
                    end
                end
            end
        end
        Fluent:Notify({
            Title = "ServerHop",
            Content = "No se encontraron servidores adecuados.",
            Duration = 5
        })
    else
        warn("Error al buscar servidores.")
    end
end

-- Función Anti-AFK
local AntiAfkConnection
local function EnableAntiAfk()
    if AntiAfkConnection then AntiAfkConnection:Disconnect() end
    AntiAfkConnection = LocalPlayer.Idled:Connect(function()
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function DisableAntiAfk()
    if AntiAfkConnection then
        AntiAfkConnection:Disconnect()
        AntiAfkConnection = nil
    end
end

-- Función para auto reejecutar el script después de teleport
local function AutoExecuteScript()
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Started then
            syn.queue_on_teleport([[
                loadstring(game:HttpGet("AQUI_VA_TU_SCRIPT_URL"))()
            ]])
        end
    end)
end

-- Botones en la GUI Fluent
Tabs.Main:AddButton({
    Title = "Rejoin Server",
    Description = "Reconectarse al mismo juego.",
    Callback = function()
        RejoinServer()
    end
})

Tabs.Main:AddButton({
    Title = "ServerHop (Servidor Lleno)",
    Description = "Unirse a un servidor con mucha gente.",
    Callback = function()
        ServerHop(true)
    end
})

Tabs.Main:AddButton({
    Title = "ServerHop (Servidor Vacío)",
    Description = "Unirse a un servidor casi vacío.",
    Callback = function()
        ServerHop(false)
    end
})

local AntiAfkToggle = Tabs.Main:AddToggle("AntiAFK", {Title = "Anti AFK", Default = false})

AntiAfkToggle:OnChanged(function(Value)
    if Value then
        EnableAntiAfk()
        Fluent:Notify({
            Title = "Anti-AFK",
            Content = "Anti AFK Activado.",
            Duration = 4
        })
    else
        DisableAntiAfk()
        Fluent:Notify({
            Title = "Anti-AFK",
            Content = "Anti AFK Desactivado.",
            Duration = 4
        })
    end
end)

Tabs.Main:AddButton({
    Title = "Auto-Execute on ServerHop",
    Description = "Reejecuta el script automáticamente al cambiar de servidor.",
    Callback = function()
        AutoExecuteScript()
        Fluent:Notify({
            Title = "AutoExecute",
            Content = "Auto ejecución configurada.",
            Duration = 5
        })
    end
})

-- Configuración de SaveManager e InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "Script cargado correctamente.",
    Duration = 8
})
