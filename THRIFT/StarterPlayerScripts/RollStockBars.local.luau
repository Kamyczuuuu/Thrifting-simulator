-- RollStockBars: shows a live stock bar above every rollable clothing model.
-- The server tracks remaining rolls in model attributes (RollStock,
-- RollStockMax, RollRefillAt), which replicate automatically to clients.

local Workspace = game:GetService("Workspace")

local bars = {}

local function getAdornee(model)
	local anchor = model:FindFirstChild("InteractionPoint")
	if anchor and anchor:IsA("BasePart") then
		return anchor
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function createBar(model)
	local adornee = getAdornee(model)
	if not adornee then
		return false
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RollStockBar"
	billboard.Size = UDim2.fromOffset(160, 24)
	billboard.StudsOffset = Vector3.new(0, 6.2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 60
	billboard.Adornee = adornee
	billboard.Parent = adornee

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(10, 30, 50)
	back.BackgroundTransparency = 0.15
	back.BorderSizePixel = 0
	back.Parent = billboard

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 8)
	backCorner.Parent = back

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 48, 78)
	stroke.Thickness = 2
	stroke.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(120, 200, 100)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 13
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	label.Parent = back

	bars[model] = { Gui = billboard, Fill = fill, Label = label }
	return true
end

local function updateBar(model)
	local entry = bars[model]
	if not entry then return end

	local stock = model:GetAttribute("RollStock")
	local maxStock = model:GetAttribute("RollStockMax")
	local refillAt = model:GetAttribute("RollRefillAt")
	if type(stock) ~= "number" or type(maxStock) ~= "number" or maxStock <= 0 then
		return
	end

	if stock <= 0 then
		local secs = math.max(0, (tonumber(refillAt) or 0) - os.time())
		entry.Fill.Size = UDim2.fromScale(0, 1)
		entry.Fill.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		entry.Label.Text = string.format("REFILL %d:%02d", math.floor(secs / 60), secs % 60)
	else
		local frac = math.clamp(stock / maxStock, 0, 1)
		entry.Fill.Size = UDim2.fromScale(frac, 1)
		entry.Fill.BackgroundColor3 = Color3.fromRGB(120, 200, 100):Lerp(Color3.fromRGB(230, 160, 60), 1 - frac)
		entry.Label.Text = tostring(stock) .. "/" .. tostring(maxStock)
	end
end

local function trySetup(obj)
	if not obj:IsA("Model") then return end
	if obj.Parent ~= Workspace then return end
	if not obj:GetAttribute("RollStockMax") then return end
	if bars[obj] then return end
	createBar(obj)
end

for _, obj in ipairs(Workspace:GetDescendants()) do
	trySetup(obj)
end

Workspace.DescendantAdded:Connect(function(obj)
	task.defer(trySetup, obj)
end)

-- Periodic refresh: updates countdowns, retries models whose anchor was not
-- ready yet, and cleans up bars for removed models.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, obj in ipairs(Workspace:GetDescendants()) do
			trySetup(obj)
		end
		for model in pairs(bars) do
			if not model.Parent then
				local entry = bars[model]
				if entry.Gui then
					entry.Gui.Parent = nil
				end
				bars[model] = nil
			else
				updateBar(model)
			end
		end
	end
end)