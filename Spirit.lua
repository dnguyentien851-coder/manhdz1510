local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local FLY_SPEED = 350
local HEIGHT_OFFSET = Vector3.new(0, 3, 0)
local COLLECT_WAIT = 0.6
local RESCAN_WAIT = 2
local SLOW_RADIUS = 30
local ARRIVE_DIST = 1.5

local FLY_TEXT = "Bay tới rương (350)"
local STOP_TEXT = "Dừng"
local FLY_COLOR = Color3.fromRGB(230, 130, 40)
local STOP_COLOR = Color3.fromRGB(200, 60, 60)
local MENU_TITLE = "manhdz35ninhbinh"

local function getGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local ok2, cg = pcall(function()
		return CoreGui
	end)
	if ok2 and cg then
		return cg
	end
	return player:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()
local oldGui = guiParent:FindFirstChild("DarkwenChestGui")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkwenChestGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 260, 0, 142)
frame.Position = UDim2.new(0.5, -130, 0.5, -71)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Visible = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(255, 190, 60)
frameStroke.Thickness = 2
frameStroke.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = MENU_TITLE
title.TextColor3 = Color3.fromRGB(255, 190, 60)
title.TextScaled = true
title.Parent = frame

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -20, 0, 24)
status.Position = UDim2.new(0, 10, 0, 42)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Sẵn sàng"
status.TextColor3 = Color3.fromRGB(200, 200, 210)
status.TextScaled = true
status.Parent = frame

local function setStatus(text)
	status.Text = text
end

local flyBtn = Instance.new("TextButton")
flyBtn.Name = "Fly"
flyBtn.Size = UDim2.new(1, -30, 0, 52)
flyBtn.Position = UDim2.new(0, 15, 0, 76)
flyBtn.BackgroundColor3 = FLY_COLOR
flyBtn.BorderSizePixel = 0
flyBtn.AutoButtonColor = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Text = FLY_TEXT
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextScaled = true
flyBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = flyBtn

local btnPad = Instance.new("UIPadding")
btnPad.PaddingLeft = UDim.new(0, 10)
btnPad.PaddingRight = UDim.new(0, 10)
btnPad.Parent = flyBtn

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MenuToggle"
toggleBtn.Size = UDim2.new(0, 52, 0, 52)
toggleBtn.Position = UDim2.new(0, 10, 0.4, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "DW"
toggleBtn.TextColor3 = Color3.fromRGB(255, 190, 60)
toggleBtn.TextScaled = true
toggleBtn.Active = true
toggleBtn.Draggable = true
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(255, 190, 60)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

local running = false
local runId = 0
local collected = {}
local collectedCount = 0
local flyVel = nil
local noclipConn = nil
local noclipParts = {}

local function resetButton()
	flyBtn.Text = FLY_TEXT
	flyBtn.BackgroundColor3 = FLY_COLOR
end

local function stopAll()
	running = false
	resetButton()
end

local function isChestName(name)
	return string.find(string.lower(name), "chest") ~= nil
end

local function isInCharacter(obj)
	local current = obj
	while current and current ~= workspace do
		if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function getChestPart(obj)
	if obj:IsA("BasePart") then
		return obj
	end
	if obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart
		end
		return obj:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function containsChestModel(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Model") and isChestName(d.Name) then
			return true
		end
	end
	return false
end

local function scanChests()
	local list = {}
	local seen = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if (obj:IsA("Model") or obj:IsA("BasePart")) and isChestName(obj.Name) and not isInCharacter(obj) then
			local skip = false
			if obj:IsA("Model") and containsChestModel(obj) then
				skip = true
			end
			if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and isChestName(obj.Parent.Name) then
				skip = true
			end
			if not skip then
				local part = getChestPart(obj)
				if part and part:IsDescendantOf(workspace) and not seen[part] then
					seen[part] = true
					table.insert(list, part)
				end
			end
		end
	end
	return list
end

local function getHRP()
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function startNoclip(char)
	noclipParts = {}
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(noclipParts, {part = part, original = part.CanCollide})
			part.CanCollide = false
		end
	end
	if noclipConn then
		noclipConn:Disconnect()
	end
	noclipConn = RunService.Stepped:Connect(function()
		for _, entry in ipairs(noclipParts) do
			if entry.part.Parent then
				entry.part.CanCollide = false
			end
		end
	end)
end

local function stopNoclip()
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	for _, entry in ipairs(noclipParts) do
		if entry.part.Parent then
			entry.part.CanCollide = entry.original
		end
	end
	noclipParts = {}
end

local function cleanupFly()
	if flyVel then
		flyVel:Destroy()
		flyVel = nil
	end
	stopNoclip()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
	end
end

local function touchChest(hrp, part)
	if firetouchinterest then
		pcall(firetouchinterest, hrp, part, 0)
		pcall(firetouchinterest, hrp, part, 1)
	end
end

local function findNearestNew()
	local hrp = getHRP()
	if not hrp then
		return nil, 0
	end
	local best, bestDist = nil, math.huge
	local remaining = 0
	for _, part in ipairs(scanChests()) do
		if not collected[part] then
			remaining += 1
			local d = (part.Position - hrp.Position).Magnitude
			if d < bestDist then
				best = part
				bestDist = d
			end
		end
	end
	return best, remaining
end

local function flyToPart(part, myId)
	local char = player.Character
	local hrp = getHRP()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return false
	end

	hum.PlatformStand = true
	startNoclip(char)

	flyVel = Instance.new("BodyVelocity")
	flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyVel.P = 1e5
	flyVel.Velocity = Vector3.zero
	flyVel.Parent = hrp

	local arrived = false

	while running and runId == myId do
		RunService.Heartbeat:Wait()

		if not running or runId ~= myId then
			break
		end
		if not part.Parent or not part:IsDescendantOf(workspace) then
			break
		end

		char = player.Character
		hrp = getHRP()
		hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then
			break
		end

		local targetPos = part.Position + HEIGHT_OFFSET
		local diff = targetPos - hrp.Position
		local dist = diff.Magnitude

		if dist <= ARRIVE_DIST then
			arrived = true
			break
		end

		local speed = FLY_SPEED
		if dist < SLOW_RADIUS then
			speed = math.max(FLY_SPEED * (dist / SLOW_RADIUS), 40)
		end

		if flyVel and flyVel.Parent then
			flyVel.Velocity = diff.Unit * speed
		end
	end

	if flyVel then
		flyVel:Destroy()
		flyVel = nil
	end

	local char2 = player.Character
	local hrp2 = getHRP()
	if arrived and hrp2 and char2 then
		hrp2.AssemblyLinearVelocity = Vector3.zero
		hrp2.CFrame = CFrame.new(part.Position + HEIGHT_OFFSET)
	end

	cleanupFly()
	return arrived
end

local function runCollect()
	if running then
		return
	end
	runId += 1
	local myId = runId
	running = true
	flyBtn.Text = STOP_TEXT
	flyBtn.BackgroundColor3 = STOP_COLOR

	while running and runId == myId do
		local hrp = getHRP()
		if not hrp then
			setStatus("Chưa có nhân vật, đang chờ...")
			task.wait(1)
			continue
		end

		local target, remaining = findNearestNew()
		if not target then
			setStatus("Chưa có rương mới, đang quét lại... (đã nhặt " .. collectedCount .. ")")
			task.wait(RESCAN_WAIT)
			continue
		end

		setStatus("Còn " .. remaining .. " rương, đang bay tới... (đã nhặt " .. collectedCount .. ")")
		local arrived = flyToPart(target, myId)

		if not (running and runId == myId) then
			break
		end

		collected[target] = true

		if arrived then
			local hrpNow = getHRP()
			if hrpNow and target.Parent and target:IsDescendantOf(workspace) then
				touchChest(hrpNow, target)
			end
			task.wait(COLLECT_WAIT)
			collectedCount += 1
		end
	end

	cleanupFly()

	if runId == myId then
		stopAll()
		setStatus("Đã dừng (đã nhặt " .. collectedCount .. ")")
	end
end

flyBtn.MouseButton1Click:Connect(function()
	if running then
		running = false
		cleanupFly()
		stopAll()
		setStatus("Đã dừng (đã nhặt " .. collectedCount .. ")")
		return
	end
	task.spawn(runCollect)
end)
