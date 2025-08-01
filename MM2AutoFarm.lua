local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Создаем интерфейс
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2FarmGui"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "Auto Farm MM2 Beach Balls"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Frame

local FarmButton = Instance.new("TextButton")
FarmButton.Text = "Farm"
FarmButton.Size = UDim2.new(0.8, 0, 0, 40)
FarmButton.Position = UDim2.new(0.1, 0, 0.4, 0)
FarmButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FarmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmButton.Font = Enum.Font.SourceSansBold
FarmButton.Parent = Frame

-- Переменные для фарма
local isFarming = false
local farmConnection = nil

-- Анти-АФК
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Функция для поиска текущей карты
local function findMap()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("MapID") then
            return obj
        end
    end
    return nil
end

-- Функция для поиска мячика BeachBall
local function findBeachBall(mapModel)
    if not mapModel then return nil end
    local coinContainer = mapModel:FindFirstChild("CoinContainer")
    if not coinContainer then return nil end
    
    for _, coin in ipairs(coinContainer:GetChildren()) do
        if coin:IsA("Part") and coin.Name == "Coin_Server" and coin:GetAttribute("CoinID") == "BeachBall" then
            local coinVisual = coin:FindFirstChild("CoinVisual")
            if coinVisual and coinVisual.Transparency ~= 1 then
                return coin
            end
        end
    end
    return nil
end

-- Настраиваем тело в вертикальное положение
local function setupVerticalPosition()
    if not Character:FindFirstChild("Humanoid") then return nil, nil end
    
    -- Отключаем анимации
    for _, track in ipairs(Character.Humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    
    -- Фиксируем положение
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FarmGyro"
    bodyGyro.P = 10000
    bodyGyro.D = 100
    bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
    bodyGyro.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + Vector3.new(0, 0, -1))
    bodyGyro.Parent = HumanoidRootPart
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FarmVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Parent = HumanoidRootPart
    
    return bodyGyro, bodyVelocity
end

-- Функция для очистки физических эффектов
local function cleanupPhysics()
    if HumanoidRootPart:FindFirstChild("FarmGyro") then
        HumanoidRootPart.FarmGyro:Destroy()
    end
    if HumanoidRootPart:FindFirstChild("FarmVelocity") then
        HumanoidRootPart.FarmVelocity:Destroy()
    end
end

-- Основная функция фарма
local function farmLoop()
    local bodyGyro, bodyVelocity = setupVerticalPosition()
    local lastPosition = HumanoidRootPart.Position
    
    while isFarming do
        task.wait(0.05) -- Скорость ~20
        
        -- Обновляем ссылки на случай смерти
        if not Character or not Character.Parent then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
            bodyGyro, bodyVelocity = setupVerticalPosition()
            lastPosition = HumanoidRootPart.Position
        end
        
        -- Ищем карту и мячик
        local map = findMap()
        local beachBall = findBeachBall(map)
        
        if beachBall then
            -- Телепортируемся к мячику
            HumanoidRootPart.CFrame = CFrame.new(beachBall.Position) * CFrame.new(0, 0, 0)
            task.wait(0.05)
            -- Возвращаемся на исходную позицию
            HumanoidRootPart.CFrame = CFrame.new(lastPosition)
        else
            -- Если мячика нет, стоим на месте
            HumanoidRootPart.CFrame = CFrame.new(lastPosition)
        end
    end
    
    cleanupPhysics()
end

-- Обработчик нажатия кнопки
FarmButton.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    
    if isFarming then
        FarmButton.Text = "Farming..."
        FarmButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        spawn(farmLoop)
    else
        FarmButton.Text = "Farm"
        FarmButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

-- Обработчик изменения персонажа
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    if isFarming then
        -- Если фарм активен, перезапускаем его для нового персонажа
        spawn(farmLoop)
    end
end)
