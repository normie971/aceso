local RunService  = cloneref(game:GetService("RunService"))
local Players     = cloneref(game:GetService("Players"))
local UIS         = cloneref(game:GetService("UserInputService"))
local Workspace   = cloneref(game:GetService("Workspace"))

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local cfg = {
    enabled = true,

    camlock = {
        smoothX = 0.05,
        smoothY = 0.05,
        predX   = 0.08,
        predY   = 0.16,
    },

    silent = {
        prediction = 0.119,
    },

    rapidFire = {
        enabled = true,
        delay   = 0.05,
    },

    filter = {
        checkKO      = true,
        checkGrabbed = true,
    },

    keys = {
        lock       = Enum.KeyCode.C,
        killSwitch = Enum.KeyCode.Backquote,
    },
}

local state = {
    target  = nil,
    locked  = false,
    holding = false,
}

local function isAlive(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isKOorGrabbed(char)
    local be = char:FindFirstChild("BodyEffects")
    if not be then return false end
    local ko      = be:FindFirstChild("K.O")
    local grabbed = be:FindFirstChild("Grabbed")
    if cfg.filter.checkKO      and ko      and ko.Value      == true then return true end
    if cfg.filter.checkGrabbed and grabbed and grabbed.Value ~= nil  then return true end
    return false
end

local function getClosest()
    local bestDist  = math.huge
    local bestHead  = nil
    local viewport  = Camera.ViewportSize
    local crosshair = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)

    for _, v in ipairs(Players:GetPlayers()) do
        if v == LocalPlayer then continue end
        local char = v.Character
        if not char then continue end
        if not isAlive(char) then continue end
        if isKOorGrabbed(char) then continue end

        local head = char:FindFirstChild("Head")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - crosshair).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestHead = head
        end
    end

    return bestHead
end

local function fireOnce()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function()
            tool:Activate()
        end)
        return
    end

    if typeof(mouse1click) == "function" then
        pcall(mouse1click)
        return
    end

    local mouse = LocalPlayer:GetMouse()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
    end)
end

if typeof(hookmetamethod) == "function" then
    local oldIndex

    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if self:IsA("Mouse") and (key == "Hit" or key == "Target") then
            local t = state.target

            if cfg.enabled and t and t.Parent then
                if key == "Hit" then
                    local vel = t.AssemblyLinearVelocity or Vector3.zero
                    return t.CFrame + vel * cfg.silent.prediction
                end

                return t
            end
        end

        return oldIndex(self, key)
    end)
else
    warn("[silent] hookmetamethod unavailable")
end

RunService.RenderStepped:Connect(function()
    if not cfg.enabled then
        state.target = nil
        state.locked = false
        return
    end

    if state.locked then
        local head = state.target

        if head then
            local char = head.Parent
            if not char or not isAlive(char) or isKOorGrabbed(char) then
                state.target = nil
                state.locked = false
            end
        end

        if state.locked and not state.target then
            state.target = getClosest()
            if not state.target then
                state.locked = false
            end
        end
    else
        state.target = nil
    end

    local head = state.target
    if not head then return end

    local hrp = head.Parent and head.Parent:FindFirstChild("HumanoidRootPart")
    local vel = hrp and (hrp.AssemblyLinearVelocity or Vector3.zero) or Vector3.zero

    local predicted = head.Position + Vector3.new(
        vel.X * cfg.camlock.predX,
        vel.Y * cfg.camlock.predY,
        0
    )

    local cur = Camera.CFrame
    local cL  = cur.LookVector
    local tL  = CFrame.new(cur.Position, predicted).LookVector

    local sX = cL.X + (tL.X - cL.X) * cfg.camlock.smoothX
    local sY = cL.Y + (tL.Y - cL.Y) * cfg.camlock.smoothY
    local sZ = cL.Z + (tL.Z - cL.Z) * cfg.camlock.smoothX

    Camera.CFrame = CFrame.new(cur.Position, cur.Position + Vector3.new(sX, sY, sZ).Unit)
end)

UIS.InputBegan:Connect(function(inp, gp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if cfg.rapidFire.enabled and not state.holding then
            state.holding = true

            task.spawn(function()
                while state.holding
                    and cfg.enabled
                    and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                do
                    fireOnce()
                    task.wait(cfg.rapidFire.delay)
                end

                state.holding = false
            end)
        end

        return
    end

    if gp then return end

    if inp.KeyCode == cfg.keys.killSwitch then
        cfg.enabled = not cfg.enabled
        state.target = nil
        state.locked = false
        state.holding = false

    elseif inp.KeyCode == cfg.keys.lock then
        if state.locked then
            state.locked = false
            state.target = nil
        else
            state.locked = true
            state.target = nil
        end
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        state.holding = false
    end
end)
