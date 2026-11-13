

-- XeroHub
-- Q: Aim | B: Head/Torso | N: Outline + Box ESP | M: Tracers
-- V: Show/hide FOV circle | RightShift: Menu
-- E/R: Increase/decrease targeting radius
--
-- Drawing.new and mousemoverel require your original execution
-- environment. They are not standard Roblox Studio APIs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

local settings = {
    TeamCheck = true,
    WallCheck = true,
    FOV = 120,
    ShowFOV = true,
    Smoothness = 0.2,
    Prediction = 0,
    Target = "Head",
    RainbowSpeed = 0.15,
}

local aimEnabled = false
local espEnabled = false
local tracersEnabled = false

local connections = {}
local outlines = {}
local tracers = {}
local boxes = {}

local rainbowHue = 0
local rainbowColor = Color3.fromHSV(0, 1, 1)

local themes = {
    {
        Name = "Red",
        Background = Color3.fromRGB(40, 12, 16),
        Button = Color3.fromRGB(65, 22, 28),
        Accent = Color3.fromRGB(230, 55, 65),
    },
    {
        Name = "Orange",
        Background = Color3.fromRGB(50, 30, 20),
        Button = Color3.fromRGB(70, 45, 30),
        Accent = Color3.fromRGB(255, 160, 60),
    },
    {
        Name = "Blue",
        Background = Color3.fromRGB(15, 20, 40),
        Button = Color3.fromRGB(25, 35, 70),
        Accent = Color3.fromRGB(80, 150, 255),
    },
}

local themeIndex = 1

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local gui = create("ScreenGui", {
    Name = "XeroHub",
    ResetOnSpawn = false,
}, player:WaitForChild("PlayerGui"))

local panel = create("Frame", {
    Size = UDim2.fromOffset(270, 470),
    Position = UDim2.new(0.5, -135, 0.5, -235),
    BorderSizePixel = 0,
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 12),
}, panel)

local border = create("UIStroke", {
    Thickness = 2,
}, panel)

local title = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "XeroHub",
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    Active = true,
}, panel)

local stats = create("TextLabel", {
    Position = UDim2.fromOffset(12, 42),
    Size = UDim2.new(1, -24, 0, 30),
    BackgroundTransparency = 1,
    Text = "FPS: ...",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.Gotham,
}, panel)

local buttons = {}

local function makeButton(y)
    local button = create("TextButton", {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 34),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
    }, panel)

    create("UICorner", {
        CornerRadius = UDim.new(0, 8),
    }, button)

    table.insert(buttons, button)
    return button
end

local aimButton = makeButton(80)
local targetButton = makeButton(120)
local fovButton = makeButton(160)
local wallButton = makeButton(200)
local teamButton = makeButton(240)
local espButton = makeButton(280)
local tracerButton = makeButton(320)
local themeButton = makeButton(360)

create("TextLabel", {
    Position = UDim2.fromOffset(12, 405),
    Size = UDim2.new(1, -24, 0, 50),
    BackgroundTransparency = 1,
    Text = "RightShift: menu\nE / R: increase / decrease radius",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.Gotham,
}, panel)

local menuButton = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 12),
    Size = UDim2.fromOffset(130, 34),
    Text = "Show / Hide",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 8),
}, menuButton)

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 100
circle.Filled = false
circle.Transparency = 0.75
circle.Visible = false
circle.Radius = settings.FOV
circle.Color = rainbowColor

local function status(enabled)
    return if enabled then "ON" else "OFF"
end

local function refreshUI()
    local theme = themes[themeIndex]

    panel.BackgroundColor3 = theme.Background
    border.Color = theme.Accent
    title.TextColor3 = theme.Accent
    menuButton.BackgroundColor3 = theme.Button

    circle.Radius = settings.FOV
    circle.Visible = aimEnabled and settings.ShowFOV

    for _, button in ipairs(buttons) do
        button.BackgroundColor3 = theme.Button
    end

    aimButton.Text = "Q - Aim: " .. status(aimEnabled)
    targetButton.Text = "B - Target: " .. settings.Target
    fovButton.Text = "V - FOV circle: " .. status(settings.ShowFOV)
    wallButton.Text = "Wall check: " .. status(settings.WallCheck)
    teamButton.Text = "Team check: " .. status(settings.TeamCheck)
    espButton.Text = "N - Outline + Box: " .. status(espEnabled)
    tracerButton.Text = "M - Tracers: " .. status(tracersEnabled)
    themeButton.Text = "Theme: " .. theme.Name

    for button, enabled in pairs({
        [aimButton] = aimEnabled,
        [fovButton] = settings.ShowFOV,
        [wallButton] = settings.WallCheck,
        [teamButton] = settings.TeamCheck,
        [espButton] = espEnabled,
        [tracerButton] = tracersEnabled,
    }) do
        button.BackgroundColor3 = if enabled
            then theme.Accent
            else theme.Button
    end
end

local function clearESP()
    for _, outline in pairs(outlines) do
        outline:Destroy()
    end

    for _, box in pairs(boxes) do
        box:Remove()
    end

    table.clear(outlines)
    table.clear(boxes)
end

local function clearTracers()
    for _, line in pairs(tracers) do
        line:Remove()
    end

    table.clear(tracers)
end

local function toggleAim()
    aimEnabled = not aimEnabled
    refreshUI()
end

local function toggleTarget()
    settings.Target = if settings.Target == "Head"
        then "Torso"
        else "Head"

    refreshUI()
end

local function toggleFOV()
    settings.ShowFOV = not settings.ShowFOV
    refreshUI()
end

local function toggleESP()
    espEnabled = not espEnabled

    if not espEnabled then
        clearESP()
    end

    refreshUI()
end

local function toggleTracers()
    tracersEnabled = not tracersEnabled

    if not tracersEnabled then
        clearTracers()
    end

    refreshUI()
end

connect(aimButton.Activated, toggleAim)
connect(targetButton.Activated, toggleTarget)
connect(fovButton.Activated, toggleFOV)
connect(espButton.Activated, toggleESP)
connect(tracerButton.Activated, toggleTracers)

connect(wallButton.Activated, function()
    settings.WallCheck = not settings.WallCheck
    refreshUI()
end)

connect(teamButton.Activated, function()
    settings.TeamCheck = not settings.TeamCheck
    refreshUI()
end)

connect(themeButton.Activated, function()
    themeIndex = themeIndex % #themes + 1
    refreshUI()
end)

connect(menuButton.Activated, function()
    panel.Visible = not panel.Visible
end)

-- Drag the menu using its title.
local dragInput
local dragStart
local panelStart

connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
        dragStart = input.Position
        panelStart = panel.Position
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not dragInput then
        return
    end

    local mouseDrag =
        dragInput.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement

    if mouseDrag or input == dragInput then
        local delta = input.Position - dragStart

        panel.Position = UDim2.new(
            panelStart.X.Scale,
            panelStart.X.Offset + delta.X,
            panelStart.Y.Scale,
            panelStart.Y.Offset + delta.Y
        )
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input == dragInput then
        dragInput = nil
    end
end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.Q then
        toggleAim()
    elseif input.KeyCode == Enum.KeyCode.B then
        toggleTarget()
    elseif input.KeyCode == Enum.KeyCode.V then
        toggleFOV()
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleESP()
    elseif input.KeyCode == Enum.KeyCode.M then
        toggleTracers()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        panel.Visible = not panel.Visible
    elseif input.KeyCode == Enum.KeyCode.E then
        settings.FOV = math.clamp(settings.FOV + 10, 50, 300)
        refreshUI()
    elseif input.KeyCode == Enum.KeyCode.R then
        settings.FOV = math.clamp(settings.FOV - 10, 50, 300)
        refreshUI()
    end
end)

local function getTargetPart(character)
    local part

    if settings.Target == "Head" then
        part = character:FindFirstChild("Head")
    else
        part = character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
    end

    return if part and part:IsA("BasePart") then part else nil
end

local function isTeammate(other)
    return settings.TeamCheck
        and not player.Neutral
        and not other.Neutral
        and player.Team ~= nil
        and player.Team == other.Team
end

local function makeRaycastParams(camera)
    local excluded = { camera }

    if player.Character then
        table.insert(excluded, player.Character)
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = true

    return params
end

local function hasLineOfSight(camera, character, part, params)
    if not settings.WallCheck then
        return true
    end

    local origin = camera.CFrame.Position
    local direction = part.Position - origin

    if direction.Magnitude <= 0.001 then
        return true
    end

    local hit = workspace:Raycast(origin, direction, params)

    return hit == nil
        or hit.Instance:IsDescendantOf(character)
end

local function getClosestTarget(camera, cursor)
    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return nil
    end

    local closestPosition
    local shortestDistance = settings.FOV
    local params = makeRaycastParams(camera)

    for _, other in ipairs(Players:GetPlayers()) do
        if other == player or isTeammate(other) then
            continue
        end

        local targetCharacter = other.Character
        local targetHumanoid = targetCharacter
            and targetCharacter:FindFirstChildOfClass("Humanoid")

        if not targetCharacter or not targetHumanoid
            or targetHumanoid.Health <= 0 then
            continue
        end

        local part = getTargetPart(targetCharacter)

        if not part then
            continue
        end

        local position = part.Position
        local root = targetCharacter:FindFirstChild("HumanoidRootPart")

        if settings.Prediction ~= 0 and root
            and root:IsA("BasePart") then
            position += root.AssemblyLinearVelocity * settings.Prediction
        end

        local projected, onScreen =
            camera:WorldToViewportPoint(position)

        if not onScreen or projected.Z <= 0 then
            continue
        end

        local distance = (
            Vector2.new(projected.X, projected.Y) - cursor
        ).Magnitude

        if distance < shortestDistance
            and hasLineOfSight(camera, targetCharacter, part, params) then
            shortestDistance = distance
            closestPosition = position
        end
    end

    return closestPosition
end

-- Build bounds from body parts, excluding accessories and tools.
local function getBodyBounds(character, camera)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local foundPart = false

    for _, part in ipairs(character:GetChildren()) do
        if not part:IsA("BasePart")
            or part.Name == "HumanoidRootPart" then
            continue
        end

        foundPart = true
        local halfSize = part.Size / 2

        -- Project each corner so the box follows the animated body.
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local corner = part.CFrame:PointToWorldSpace(
                        Vector3.new(
                            halfSize.X * x,
                            halfSize.Y * y,
                            halfSize.Z * z
                        )
                    )

                    local point = camera:WorldToViewportPoint(corner)

                    -- Avoid oversized boxes when crossing the camera.
                    if point.Z <= 0.05 then
                        return nil
                    end

                    minX = math.min(minX, point.X)
                    minY = math.min(minY, point.Y)
                    maxX = math.max(maxX, point.X)
                    maxY = math.max(maxY, point.Y)
                end
            end
        end
    end

    if not foundPart then
        return nil
    end

    local viewport = camera.ViewportSize

    if maxX < 0 or maxY < 0
        or minX > viewport.X or minY > viewport.Y then
        return nil
    end

    local padding = 3

    return Vector2.new(minX - padding, minY - padding),
        Vector2.new(
            maxX - minX + padding * 2,
            maxY - minY + padding * 2
        )
end

-- Outlines and boxes share the ESP toggle.
local function updateESP(camera)
    for _, other in ipairs(Players:GetPlayers()) do
        if other == player then
            continue
        end

        local character = other.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        local valid = character ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0

        local outline = outlines[other]
        local box = boxes[other]

        if box then
            box.Visible = false
        end

        if outline and (not valid or outline.Adornee ~= character) then
            outline:Destroy()
            outlines[other] = nil
            outline = nil
        end

        if not valid then
            if box then
                box:Remove()
                boxes[other] = nil
            end
            continue
        end

        if not outline then
            outline = create("Highlight", {
                Name = "XeroOutline",
                Adornee = character,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                FillTransparency = 1,
                OutlineTransparency = 0,
                OutlineColor = rainbowColor,
            }, gui)

            outlines[other] = outline
        end

        local position, size = getBodyBounds(character, camera)

        if position and size then
            if not box then
                box = Drawing.new("Square")
                box.Filled = false
                box.Thickness = 1.5
                box.Transparency = 1
                box.Color = rainbowColor
                boxes[other] = box
            end

            box.Position = position
            box.Size = size
            box.Visible = true
        end
    end
end

local function updateTracers(camera)
    local viewport = camera.ViewportSize
    local origin = Vector2.new(viewport.X / 2, viewport.Y - 2)

    for _, other in ipairs(Players:GetPlayers()) do
        if other == player then
            continue
        end

        local line = tracers[other]

        if line then
            line.Visible = false
        end

        local character = other.Character
        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")
        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not humanoid or humanoid.Health <= 0
            or not root or not root:IsA("BasePart") then
            continue
        end

        local projected, onScreen =
            camera:WorldToViewportPoint(root.Position)

        if not onScreen or projected.Z <= 0 then
            continue
        end

        if not line then
            line = Drawing.new("Line")
            line.Thickness = 1.5
            line.Transparency = 0.8
            line.Color = rainbowColor
            tracers[other] = line
        end

        line.From = origin
        line.To = Vector2.new(projected.X, projected.Y)
        line.Visible = true
    end
end

-- Keep all visual effects synchronized to the same rainbow.
local function updateRainbow(dt)
    rainbowHue = (rainbowHue + dt * settings.RainbowSpeed) % 1
    rainbowColor = Color3.fromHSV(rainbowHue, 1, 1)

    circle.Color = rainbowColor

    for _, outline in pairs(outlines) do
        outline.OutlineColor = rainbowColor
    end

    for _, line in pairs(tracers) do
        line.Color = rainbowColor
    end

    for _, box in pairs(boxes) do
        box.Color = rainbowColor
    end
end

connect(Players.PlayerRemoving, function(other)
    if outlines[other] then
        outlines[other]:Destroy()
        outlines[other] = nil
    end

    if tracers[other] then
        tracers[other]:Remove()
        tracers[other] = nil
    end

    if boxes[other] then
        boxes[other]:Remove()
        boxes[other] = nil
    end
end)

local elapsed = 0
local frameCount = 0

connect(RunService.RenderStepped, function(dt)
    updateRainbow(dt)

    local camera = workspace.CurrentCamera

    if not camera then
        circle.Visible = false

        for _, line in pairs(tracers) do
            line.Visible = false
        end

        for _, box in pairs(boxes) do
            box.Visible = false
        end

        return
    end

    local cursor = UserInputService:GetMouseLocation()

    circle.Position = cursor
    circle.Visible = aimEnabled and settings.ShowFOV

    if aimEnabled
        and not UserInputService:GetFocusedTextBox()
        and not GuiService.MenuIsOpen then

        local targetPosition = getClosestTarget(camera, cursor)

        if targetPosition then
            local projected =
                camera:WorldToViewportPoint(targetPosition)

            if projected.Z > 0 then
                local targetScreenPosition =
                    Vector2.new(projected.X, projected.Y)

                local movement = (targetScreenPosition - cursor)
                    * settings.Smoothness

                mousemoverel(movement.X, movement.Y)
            end
        end
    end

    if espEnabled then
        updateESP(camera)
    end

    if tracersEnabled then
        updateTracers(camera)
    end

    elapsed += dt
    frameCount += 1

    if elapsed >= 0.5 then
        stats.Text = string.format(
            "FPS: %d | Radius: %d",
            math.floor(frameCount / elapsed + 0.5),
            settings.FOV
        )

        elapsed = 0
        frameCount = 0
    end
end)

connect(gui.Destroying, function()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    table.clear(connections)
    clearESP()
    clearTracers()
    circle:Remove()
end)

refreshUI()
