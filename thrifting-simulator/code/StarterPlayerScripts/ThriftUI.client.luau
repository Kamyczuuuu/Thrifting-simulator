--!strict
-- Thrifting Simulator - clickable GUI prototype
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts when working directly in Roblox Studio.
-- It uses local mock data for now; the real inventory and economy will be connected later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[ThriftUI] Client interface is starting.")

local existingGui = playerGui:FindFirstChild("ThriftUI")
if existingGui then
	existingGui:Destroy()
end

local Theme = {
	Background = Color3.fromRGB(237, 246, 255),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceLight = Color3.fromRGB(216, 232, 251),
	Paper = Color3.fromRGB(16, 48, 100),
	Muted = Color3.fromRGB(91, 119, 161),
	Lime = Color3.fromRGB(47, 124, 246),
	LimeDark = Color3.fromRGB(24, 72, 167),
	Danger = Color3.fromRGB(231, 82, 92),
	Common = Color3.fromRGB(117, 142, 179),
	Uncommon = Color3.fromRGB(38, 164, 135),
	Rare = Color3.fromRGB(47, 124, 246),
	Grail = Color3.fromRGB(122, 87, 210),
	Limited = Color3.fromRGB(245, 158, 37),
	White = Color3.fromRGB(255, 255, 255),
}

local InterfaceFont = Font.fromName("Nunito", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
local FontSizeBoost = 4

local CategoryOrder = { "Top", "Bottom", "Shoes", "Head", "Accessory" }
local CategoryShort = {
	Top = "TOPS",
	Bottom = "BOTTOMS",
	Shoes = "SHOES",
	Head = "HEAD",
	Accessory = "EXTRAS",
}

type ClothingItem = {
	Id: string,
	Name: string,
	Brand: string,
	Category: string,
	Style: string,
	Rarity: string,
	Value: number,
	Visual: string,
	Limited: string?,
	State: string,
}

type Shipment = {
	Item: ClothingItem,
	FinishAt: number,
}

local inventory: { ClothingItem } = {
	{ Id = "heavy_blank_tee", Name = "Heavy Blank Tee", Brand = "Basefile", Category = "Top", Style = "Street", Rarity = "Common", Value = 45, Visual = "TEE", State = "Owned" },
	{ Id = "dead_signal_zip", Name = "Dead Signal Zip Hoodie", Brand = "Last Call", Category = "Top", Style = "Y2K", Rarity = "Uncommon", Value = 240, Visual = "ZIP HOODIE", State = "Owned" },
	{ Id = "transit_leather", Name = "Transit Leather Jacket", Brand = "Morrow", Category = "Top", Style = "Archive", Rarity = "Grail", Value = 3800, Visual = "LEATHER JACKET", State = "Owned" },
	{ Id = "washed_straight", Name = "Washed Straight Denim", Brand = "Rivet", Category = "Bottom", Style = "Vintage", Rarity = "Common", Value = 70, Visual = "STRAIGHT DENIM", State = "Owned" },
	{ Id = "widefade_denim", Name = "Widefade Denim", Brand = "Nox Denim", Category = "Bottom", Style = "Archive", Rarity = "Uncommon", Value = 210, Visual = "WIDE DENIM", State = "Owned" },
	{ Id = "canvas_90", Name = "Canvas 90", Brand = "Nice", Category = "Shoes", Style = "Skate", Rarity = "Common", Value = 85, Visual = "LOW-TOP", State = "Owned" },
	{ Id = "fourline_runner", Name = "Fourline Runner", Brand = "Abibas", Category = "Shoes", Style = "Sport", Rarity = "Uncommon", Value = 290, Visual = "RUNNER", State = "Owned" },
	{ Id = "obsidian_stack", Name = "Obsidian Stack Boots", Brand = "Bick Bowens", Category = "Shoes", Style = "Archive", Rarity = "Grail", Value = 5500, Visual = "STACK BOOT", State = "Owned" },
	{ Id = "faded_cap", Name = "Faded Logo Cap", Brand = "Kabel 04", Category = "Head", Style = "Street", Rarity = "Common", Value = 55, Visual = "CAP", State = "Owned" },
	{ Id = "shield_visor", Name = "Shield Visor", Brand = "Suture", Category = "Head", Style = "Y2K", Rarity = "Rare", Value = 650, Visual = "VISOR", State = "Owned" },
	{ Id = "chrome_link", Name = "Chrome Link Belt", Brand = "Chrome Souls", Category = "Accessory", Style = "Archive", Rarity = "Rare", Value = 900, Visual = "CHAIN BELT", State = "Owned" },
	{ Id = "moonwire", Name = "Moonwire Glasses", Brand = "Lumen 03", Category = "Accessory", Style = "Y2K", Rarity = "Limited", Value = 12000, Visual = "WIRE GLASSES", Limited = "#042 / 500", State = "Owned" },
}

local coins = 1240
local bagLimit = 12
local currentCategory = "Top"
local selectedItem: ClothingItem = inventory[1]
local equipped: { [string]: ClothingItem? } = {
	Top = inventory[1],
	Bottom = inventory[4],
	Shoes = inventory[6],
	Head = inventory[9],
	Accessory = nil,
}
local shipments: { Shipment } = {}
local currentPhoneTab = "LISTINGS"
local toastVersion = 0
local refreshInventory: () -> ()
local refreshFit: () -> ()

local function create(className: string, properties: { [string]: any }?): Instance
	local instance = Instance.new(className)
	if properties then
		for property, value in pairs(properties) do
			(instance :: any)[property] = value
		end
	end
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		instance.FontFace = InterfaceFont
		if properties and type(properties.TextSize) == "number" then
			instance.TextSize = properties.TextSize + FontSizeBoost
		end
	end
	return instance
end

local function addCorner(parent: Instance, radius: number)
	create("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	})
end

local function addStroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function addPadding(parent: Instance, left: number, right: number, top: number, bottom: number)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom),
		Parent = parent,
	})
end

local function formatCoins(amount: number): string
	local reversed = tostring(math.floor(amount)):reverse()
	local grouped = reversed:gsub("(%d%d%d)", "%1,")
	local result = grouped:reverse():gsub("^,", "")
	return result
end

local function rarityColor(item: ClothingItem): Color3
	if item.Limited then
		return Theme.Limited
	end
	return (Theme :: any)[item.Rarity] or Theme.Common
end

local function ownedCount(): number
	local count = 0
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			count += 1
		end
	end
	return count
end

local screenGui = create("ScreenGui", {
	Name = "ThriftUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
}) :: ScreenGui

local hud = create("Frame", {
	Name = "HUD",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = screenGui,
}) :: Frame

local titleBlock = create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.fromOffset(218, 74),
	Position = UDim2.fromOffset(22, 22),
	Parent = hud,
}) :: Frame
titleBlock.Visible = false
addCorner(titleBlock, 14)
addStroke(titleBlock, Theme.SurfaceLight, 1)
addPadding(titleBlock, 15, 15, 11, 10)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 24),
	Font = Enum.Font.GothamBlack,
	Text = "THRIFT//RUN",
	TextColor3 = Theme.White,
	TextSize = 23,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBlock,
})

local cashChip = create("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.fromOffset(152, 58),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 22),
	Parent = hud,
}) :: Frame
addCorner(cashChip, 16)
addStroke(cashChip, Theme.SurfaceLight, 1)
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(58, 58),
	Position = UDim2.fromOffset(14, 0),
	Font = Enum.Font.GothamBold,
	Text = "$ CASH",
	TextColor3 = Theme.Muted,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = cashChip,
})
local cashLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -76, 1, 0),
	Position = UDim2.fromOffset(62, 0),
	Font = Enum.Font.GothamBlack,
	Text = "$1,240",
	TextColor3 = Theme.LimeDark,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = cashChip,
}) :: TextLabel
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.fromOffset(0, 30),
	Font = Enum.Font.GothamMedium,
	Text = "RANK 01  ·  BARGAIN BASEMENT",
	TextColor3 = Theme.SurfaceLight,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBlock,
})

local hudButtons = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(284, 58),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -184, 0, 22),
	Parent = hud,
}) :: Frame
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	Parent = hudButtons,
})

local function makeButton(parent: Instance, text: string, size: UDim2, accent: boolean?): TextButton
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if accent then Theme.Lime else Theme.Surface,
		Size = size,
		Font = Enum.Font.GothamBold,
	Text = text,
	TextColor3 = if accent then Theme.Background else Theme.Paper,
	TextSize = 14,
		Parent = parent,
	}) :: TextButton
	addCorner(button, 12)
	addStroke(button, if accent then Theme.Lime else Theme.SurfaceLight, 1)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = if accent then Color3.fromRGB(92, 157, 255) else Theme.SurfaceLight,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = if accent then Theme.Lime else Theme.Surface,
		}):Play()
	end)
	return button
end

local inventoryButton = makeButton(hudButtons, "▣  WARDROBE", UDim2.fromOffset(138, 58), false)
local fitButton = makeButton(hudButtons, "✦  FIT BUILDER", UDim2.fromOffset(138, 58), true)

local phoneDock = create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.fromOffset(176, 48),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	ZIndex = 4,
	Parent = hud,
}) :: Frame
addCorner(phoneDock, 18)
addStroke(phoneDock, Theme.White, 1, 0.25)
local phoneDockButton = makeButton(phoneDock, "▲  FLIPTAG", UDim2.fromScale(1, 1), true)
phoneDockButton.BackgroundColor3 = Theme.LimeDark
phoneDockButton.TextColor3 = Theme.White
phoneDockButton.ZIndex = 5

local backdrop = create("TextButton", {
	Name = "Backdrop",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Text = "",
	Visible = false,
	ZIndex = 5,
	Parent = screenGui,
}) :: TextButton

local toast = create("Frame", {
	BackgroundColor3 = Theme.Paper,
	Size = UDim2.fromOffset(360, 52),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -70),
	ZIndex = 30,
	Parent = screenGui,
}) :: Frame
addCorner(toast, 13)
local toastLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextColor3 = Theme.Background,
	TextSize = 13,
	ZIndex = 31,
	Parent = toast,
}) :: TextLabel

local function showToast(message: string, accent: Color3?)
	toastVersion += 1
	local thisToast = toastVersion
	toastLabel.Text = message
	toast.BackgroundColor3 = accent or Theme.Paper
	toastLabel.TextColor3 = if accent then Theme.Background else Theme.Background
	TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 20),
	}):Play()
	task.delay(2.4, function()
		if toastVersion == thisToast then
			TweenService:Create(toast, TweenInfo.new(0.18), {
				Position = UDim2.new(0.5, 0, 0, -70),
			}):Play()
		end
	end)
end

local function animateClothingRoll(rawItem: { [string]: any })
	--==================================================
	-- HORIZONTAL CLOTHING ROULETTE
	--==================================================

	local rollWindow = create("Frame", {
		Name = "ClothingRoll",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(680, 185),
		ZIndex = 40,
		Parent = screenGui,
	}) :: Frame
	addCorner(rollWindow, 18)
	addStroke(rollWindow, Color3.fromRGB(245, 158, 37), 4)

	-- Inner viewport, matching the reference style.
	local viewport = create("Frame", {
		Name = "RollViewport",
		BackgroundColor3 = Color3.fromRGB(48, 48, 48),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 1, -20),
		ZIndex = 41,
		Parent = rollWindow,
	}) :: Frame
	addCorner(viewport, 13)

	--==================================================
	-- CENTER MARKER
	--==================================================

	local marker = create("Frame", {
		Name = "CenterMarker",
		BackgroundColor3 = Color3.fromRGB(245, 158, 37),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(4, 165),
		ZIndex = 60,
		Parent = viewport,
	}) :: Frame
	addCorner(marker, 3)

	local markerTop = create("Frame", {
		Name = "CenterMarkerTop",
		BackgroundColor3 = Color3.fromRGB(245, 158, 37),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -4),
		Size = UDim2.fromOffset(14, 10),
		Rotation = 45,
		ZIndex = 61,
		Parent = viewport,
	}) :: Frame

	--==================================================
	-- BUILD ROLL DATA
	--==================================================

	local choices: { ClothingItem } = {}

	-- Keep the roll long enough to feel like a real roulette.
	for _ = 1, 12 do
		table.insert(
			choices,
			inventory[math.random(1, #inventory)]
		)
	end

	local winnerIndex = #choices + 1

	local winner: ClothingItem = {
		Id = tostring(rawItem.Id),
		Name = tostring(rawItem.Name),
		Brand = tostring(rawItem.Brand),
		Category = tostring(rawItem.Category),
		Style = tostring(rawItem.Style),
		Rarity = tostring(rawItem.Rarity),
		Value = tonumber(rawItem.Value) or 0,
		Visual = tostring(rawItem.Visual),
		Limited = if rawItem.Limited ~= nil then tostring(rawItem.Limited) else nil,
		State = "Owned",
	}

	table.insert(choices, winner)

	for _ = 1, 5 do
		table.insert(
			choices,
			inventory[math.random(1, #inventory)]
		)
	end

	--==================================================
	-- HORIZONTAL LIST
	--==================================================

	local CARD_WIDTH = 112
	local CARD_HEIGHT = 125
	local GAP = 8
	local SIDE_PADDING = 4

	local totalWidth =
		SIDE_PADDING * 2
		+ (#choices * CARD_WIDTH)
		+ ((#choices - 1) * GAP)

	local rollList = create("Frame", {
		Name = "RollList",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(totalWidth, CARD_HEIGHT),
		ZIndex = 45,
		Parent = viewport,
	}) :: Frame

	--==================================================
	-- CREATE ITEM CARD
	--==================================================

	local winnerCard: Frame? = nil

	local function createRollCard(item: ClothingItem, index: number): Frame
		local card = create("Frame", {
			Name = "Item" .. index,
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(
				SIDE_PADDING + (index - 1) * (CARD_WIDTH + GAP),
				20
			),
			Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT),
			ZIndex = 46,
			Parent = rollList,
		}) :: Frame
		addCorner(card, 9)

		local rarityStripe = create("Frame", {
			BackgroundColor3 = rarityColor(item),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 5),
			ZIndex = 47,
			Parent = card,
		}) :: Frame
		addCorner(rarityStripe, 6)

		local imageBox = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(225, 225, 225),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(88, 66),
			ZIndex = 47,
			Parent = card,
		}) :: Frame
		addCorner(imageBox, 5)

		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBlack,
			Text = string.upper(tostring(item.Visual or "ITEM")),
			TextColor3 = rarityColor(item),
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 48,
			Parent = imageBox,
		})

		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, 28),
			Position = UDim2.fromOffset(5, 83),
			Font = Enum.Font.GothamBold,
			Text = string.upper(tostring(item.Name or "ITEM")),
			TextColor3 = Theme.White,
			TextSize = 10,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 48,
			Parent = card,
		})

		local valueLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, 14),
			Position = UDim2.fromOffset(5, 108),
			Font = Enum.Font.GothamBold,
			Text = "$" .. formatCoins(item.Value),
			TextColor3 = rarityColor(item),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 48,
			Parent = card,
		}) :: TextLabel

		local rarityDot = create("Frame", {
			BackgroundColor3 = rarityColor(item),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 10),
			Size = UDim2.fromOffset(7, 7),
			ZIndex = 49,
			Parent = card,
		}) :: Frame
		addCorner(rarityDot, 8)

		if index == winnerIndex then
			winnerCard = card
		end

		return card
	end

	for index, item in ipairs(choices) do
		createRollCard(item, index)
	end

	--==================================================
	-- ANIMATION POSITION
	--==================================================

	local viewportWidth = 660
	local viewportCenterX = viewportWidth / 2

	local winnerCenter =
		SIDE_PADDING
		+ (winnerIndex - 1) * (CARD_WIDTH + GAP)
		+ CARD_WIDTH / 2

	local targetX = viewportCenterX - winnerCenter
	targetX += math.random(-8, 8)

	-- Start with the row partially outside the left edge.
	rollList.Position = UDim2.fromOffset(viewportCenterX + 85, 0)

	local tween = TweenService:Create(
		rollList,
		TweenInfo.new(
			3.25,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		{
			Position = UDim2.fromOffset(targetX, 0),
		}
	)

	--==================================================
	-- START ROLL
	--==================================================

	tween:Play()

	tween.Completed:Wait()

	--==================================================
	-- WINNER EFFECT
	--==================================================

	if winnerCard and winnerCard.Parent then
		addStroke(winnerCard, Color3.fromRGB(245, 158, 37), 3)

		local scale = create("UIScale", {
			Scale = 1,
			Parent = winnerCard,
		}) :: UIScale

		local pulseUp = TweenService:Create(
			scale,
			TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1.06 }
		)

		local pulseDown = TweenService:Create(
			scale,
			TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Scale = 1 }
		)

		pulseUp:Play()
		pulseUp.Completed:Wait()
		pulseDown:Play()
	end

	task.wait(0.65)
	rollWindow:Destroy()

	--==================================================
	-- ADD WON ITEM TO INVENTORY
	--==================================================

	table.insert(inventory, winner)
	selectedItem = winner
	currentCategory = winner.Category
	refreshInventory()
	refreshFit()
	showToast("FOUND: " .. string.upper(winner.Name), Theme.Lime)
end

-- Product cards use simple garment silhouettes for now. These are intentionally
-- made from UI shapes so every item can be recognised before 3D clothing models exist.
local function createGarmentPreview(parent: Instance, item: ClothingItem, position: UDim2, size: UDim2, zIndex: number)
	local preview = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(224, 238, 255),
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		ZIndex = zIndex,
		Parent = parent,
	}) :: Frame
	addCorner(preview, 11)

	local tint = rarityColor(item)
	local function part(partSize: UDim2, partPosition: UDim2, rotation: number?)
		local visualPart = create("Frame", {
			BackgroundColor3 = tint,
			BorderSizePixel = 0,
			Size = partSize,
			Position = partPosition,
			Rotation = rotation or 0,
			ZIndex = zIndex + 1,
			Parent = preview,
		}) :: Frame
		addCorner(visualPart, 5)
		return visualPart
	end

	if item.Category == "Top" then
		part(UDim2.fromScale(0.34, 0.5), UDim2.fromScale(0.33, 0.25))
		part(UDim2.fromScale(0.2, 0.25), UDim2.fromScale(0.13, 0.34), -12)
		part(UDim2.fromScale(0.2, 0.25), UDim2.fromScale(0.67, 0.34), 12)
		if item.Visual == "ZIP HOODIE" or item.Visual == "LEATHER JACKET" then
			local zip = create("Frame", {
				BackgroundColor3 = Theme.White,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.018, 0.43),
				Position = UDim2.fromScale(0.491, 0.29),
				ZIndex = zIndex + 2,
				Parent = preview,
			})
			addCorner(zip, 2)
		end
	elseif item.Category == "Bottom" then
		part(UDim2.fromScale(0.38, 0.13), UDim2.fromScale(0.31, 0.2))
		part(UDim2.fromScale(0.15, 0.48), UDim2.fromScale(0.34, 0.31), 2)
		part(UDim2.fromScale(0.15, 0.48), UDim2.fromScale(0.51, 0.31), -2)
	elseif item.Category == "Shoes" then
		part(UDim2.fromScale(0.35, 0.18), UDim2.fromScale(0.12, 0.51), -6)
		part(UDim2.fromScale(0.35, 0.18), UDim2.fromScale(0.53, 0.51), 6)
		part(UDim2.fromScale(0.39, 0.06), UDim2.fromScale(0.1, 0.68))
		part(UDim2.fromScale(0.39, 0.06), UDim2.fromScale(0.51, 0.68))
	elseif item.Category == "Head" then
		part(UDim2.fromScale(0.42, 0.28), UDim2.fromScale(0.29, 0.3))
		part(UDim2.fromScale(0.32, 0.08), UDim2.fromScale(0.48, 0.53), -4)
		if item.Visual == "VISOR" then
			part(UDim2.fromScale(0.47, 0.13), UDim2.fromScale(0.26, 0.47))
		end
	else
		local ring = part(UDim2.fromScale(0.34, 0.34), UDim2.fromScale(0.33, 0.28), 45)
		ring.BackgroundTransparency = 0.15
		create("UIStroke", {
			Color = Theme.White,
			Thickness = 3,
			Parent = ring,
		})
		if item.Visual == "WIRE GLASSES" then
			part(UDim2.fromScale(0.16, 0.18), UDim2.fromScale(0.3, 0.4))
			part(UDim2.fromScale(0.16, 0.18), UDim2.fromScale(0.54, 0.4))
		end
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 16),
		Position = UDim2.new(0, 6, 1, -20),
		Font = Enum.Font.GothamBold,
		Text = item.Visual,
		TextColor3 = Theme.Paper,
		TextSize = 9,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = zIndex + 3,
		Parent = preview,
	})
end

local function makeWindow(name: string, size: UDim2): Frame
	local window = create("Frame", {
		Name = name,
		BackgroundColor3 = Theme.Background,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.52, 0),
		Visible = false,
		ZIndex = 10,
		Parent = screenGui,
	}) :: Frame
	addCorner(window, 20)
	addStroke(window, Theme.SurfaceLight, 1)
	return window
end

local inventoryWindow = makeWindow("InventoryWindow", UDim2.fromScale(0.84, 0.77))
local fitWindow = makeWindow("FitWindow", UDim2.fromScale(0.84, 0.77))
local phoneWindow = create("Frame", {
	Name = "PhoneWindow",
	BackgroundColor3 = Color3.fromRGB(10, 18, 32),
	Size = UDim2.fromOffset(414, 710),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 740),
	ClipsDescendants = false,
	Visible = false,
	ZIndex = 10,
	Parent = screenGui,
}) :: Frame
addCorner(phoneWindow, 38)
addStroke(phoneWindow, Color3.fromRGB(53, 76, 112), 2)

local phoneScreen = create("Frame", {
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -16, 1, -16),
	Position = UDim2.fromOffset(8, 8),
	ClipsDescendants = true,
	ZIndex = 11,
	Parent = phoneWindow,
}) :: Frame
addCorner(phoneScreen, 31)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(58, 22),
	Position = UDim2.fromOffset(23, 9),
	Font = Enum.Font.GothamBold,
	Text = "9:41",
	TextColor3 = Theme.Paper,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 20,
	Parent = phoneScreen,
})
local dynamicIsland = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(8, 14, 24),
	Size = UDim2.fromOffset(106, 27),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	ZIndex = 20,
	Parent = phoneScreen,
}) :: Frame
addCorner(dynamicIsland, 15)
create("Frame", {
	BackgroundColor3 = Color3.fromRGB(36, 51, 75),
	Size = UDim2.fromOffset(8, 8),
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	ZIndex = 21,
	Parent = dynamicIsland,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(46, 22),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -72, 0, 9),
	Font = Enum.Font.GothamBold,
	Text = "▮▮▮  ◌",
	TextColor3 = Theme.Paper,
	TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 20,
	Parent = phoneScreen,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(32, 22),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -37, 0, 9),
	Font = Enum.Font.GothamBold,
	Text = "100%",
	TextColor3 = Theme.Paper,
	TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 20,
	Parent = phoneScreen,
})
local battery = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(18, 9),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 15),
	ZIndex = 21,
	Parent = phoneScreen,
}) :: Frame
addCorner(battery, 3)
addStroke(battery, Theme.Paper, 1)

local function makePhoneSideButton(position: UDim2, size: UDim2)
	local sideButton = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(41, 63, 95),
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		ZIndex = 9,
		Parent = phoneWindow,
	})
	addCorner(sideButton, 3)
	return sideButton
end
makePhoneSideButton(UDim2.fromOffset(-4, 128), UDim2.fromOffset(5, 30))
makePhoneSideButton(UDim2.fromOffset(-4, 187), UDim2.fromOffset(5, 48))
makePhoneSideButton(UDim2.fromOffset(-4, 243), UDim2.fromOffset(5, 48))
makePhoneSideButton(UDim2.new(1, -1, 0, 172), UDim2.fromOffset(5, 72))
local homeBar = create("Frame", {
	BackgroundColor3 = Theme.Paper,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(132, 5),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	ZIndex = 24,
	Parent = phoneScreen,
})
addCorner(homeBar, 5)

local activeWindow: Frame? = nil
local function closeWindows()
	local windowToClose = activeWindow
	activeWindow = nil
	if windowToClose == phoneWindow then
		TweenService:Create(phoneWindow, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1, 740),
		}):Play()
		task.delay(0.23, function()
			if activeWindow ~= phoneWindow then
				phoneWindow.Visible = false
			end
		end)
	elseif windowToClose then
		windowToClose.Visible = false
	end
	backdrop.Visible = false
end

local function openWindow(window: Frame)
	if activeWindow and activeWindow ~= window then
		activeWindow.Visible = false
	end
	activeWindow = window
	backdrop.Visible = true
	window.Visible = true
	if window == phoneWindow then
		window.Position = UDim2.new(0.5, 0, 1, 740)
		TweenService:Create(window, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 1, -8),
		}):Play()
	else
		window.Position = UDim2.new(0.5, 0, 0.54, 0)
		TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}):Play()
	end
end

backdrop.MouseButton1Click:Connect(closeWindows)

-- Inventory window ---------------------------------------------------------
local inventoryHeader = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 88),
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: Frame
addPadding(inventoryHeader, 28, 28, 22, 14)
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0.6, 0, 0, 31),
	Font = Enum.Font.GothamBlack,
	Text = "YOUR WARDROBE",
	TextColor3 = Theme.Paper,
	TextSize = 23,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
	Parent = inventoryHeader,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0.6, 0, 0, 20),
	Position = UDim2.fromOffset(0, 34),
	Font = Enum.Font.GothamMedium,
	Text = "BUILD A FIT · KEEP THE GRAILS",
	TextColor3 = Theme.Muted,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 11,
	Parent = inventoryHeader,
})
local inventoryClose = makeButton(inventoryHeader, "×", UDim2.fromOffset(42, 42), false)
inventoryClose.AnchorPoint = Vector2.new(1, 0.5)
inventoryClose.Position = UDim2.new(1, 0, 0.5, 0)
inventoryClose.ZIndex = 12
inventoryClose.MouseButton1Click:Connect(closeWindows)

local categoryRail = create("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(0, 140, 1, -112),
	Position = UDim2.fromOffset(24, 88),
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: Frame
addCorner(categoryRail, 15)
addPadding(categoryRail, 11, 11, 12, 12)
local categoryLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	Parent = categoryRail,
})

local inventoryGrid = create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -510, 1, -132),
	Position = UDim2.fromOffset(182, 106),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Theme.Lime,
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: ScrollingFrame
local gridLayout = create("UIGridLayout", {
	CellSize = UDim2.fromOffset(174, 242),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = inventoryGrid,
})

local inspector = create("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.fromOffset(292, 0),
	Position = UDim2.new(1, -316, 0, 106),
	AnchorPoint = Vector2.new(0, 0),
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: Frame
inspector.Size = UDim2.new(0, 292, 1, -132)
addCorner(inspector, 15)
addPadding(inspector, 17, 17, 17, 17)

local inspectorBrand = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 20),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextColor3 = Theme.Lime,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = inspector,
}) :: TextLabel
local inspectorName = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 64),
	Position = UDim2.fromOffset(0, 26),
	Font = Enum.Font.GothamBlack,
	Text = "",
	TextColor3 = Theme.Paper,
	TextSize = 21,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 12,
	Parent = inspector,
}) :: TextLabel
local inspectorMeta = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.fromOffset(0, 98),
	Font = Enum.Font.GothamMedium,
	Text = "",
	TextColor3 = Theme.Muted,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 12,
	Parent = inspector,
}) :: TextLabel

local equippedPanel = create("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.new(1, 0, 0, 180),
	Position = UDim2.fromOffset(0, 165),
	ZIndex = 12,
	Parent = inspector,
}) :: Frame
addCorner(equippedPanel, 12)
addPadding(equippedPanel, 11, 11, 10, 10)
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 18),
	Font = Enum.Font.GothamBold,
	Text = "CURRENT FIT",
	TextColor3 = Theme.Muted,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 13,
	Parent = equippedPanel,
})
local equippedList = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -26),
	Position = UDim2.fromOffset(0, 26),
	ZIndex = 13,
	Parent = equippedPanel,
}) :: Frame
create("UIListLayout", {
	Padding = UDim.new(0, 4),
	Parent = equippedList,
})

local equipButton = makeButton(inspector, "EQUIP TO FIT", UDim2.new(1, 0, 0, 45), true)
equipButton.Position = UDim2.new(0, 0, 1, -101)
equipButton.ZIndex = 13
local listButton = makeButton(inspector, "LIST ON FLIPTAG", UDim2.new(1, 0, 0, 43), false)
listButton.Position = UDim2.new(0, 0, 1, -50)
listButton.ZIndex = 13

local categoryButtons: { [string]: TextButton } = {}
for _, category in ipairs(CategoryOrder) do
	local button = makeButton(categoryRail, CategoryShort[category], UDim2.new(1, 0, 0, 48), false)
	button.ZIndex = 12
	categoryButtons[category] = button
end

local function clearChildrenExceptLayout(parent: Instance)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end

local refreshPhone: () -> ()

local function refreshEquipped()
	clearChildrenExceptLayout(equippedList)
	for _, category in ipairs(CategoryOrder) do
		local item = equipped[category]
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 23),
			Font = Enum.Font.GothamMedium,
			Text = string.format("%s  %s", CategoryShort[category], if item then item.Name else "—"),
			TextColor3 = if item then Theme.Paper else Theme.Muted,
			TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 14,
			Parent = equippedList,
		})
	end
end

local function refreshInspector()
	inspectorBrand.Text = string.upper(selectedItem.Brand)
	inspectorBrand.TextColor3 = rarityColor(selectedItem)
	inspectorName.Text = selectedItem.Name
	local status = if selectedItem.State == "Owned" then "IN WARDROBE" elseif selectedItem.State == "Listed" then "ON DELIVERY" else "SOLD"
	inspectorMeta.Text = string.format("%s · %s\n%s · $%s", selectedItem.Style, selectedItem.Rarity, status, formatCoins(selectedItem.Value))
	if selectedItem.Limited then
		inspectorMeta.Text ..= "\nLIMITED " .. selectedItem.Limited
	end

	local available = selectedItem.State == "Owned"
	equipButton.Text = if equipped[selectedItem.Category] == selectedItem then "EQUIPPED" else "EQUIP TO FIT"
	equipButton.BackgroundColor3 = if available then Theme.Lime else Theme.SurfaceLight
	equipButton.TextColor3 = if available then Theme.Background else Theme.Muted
	listButton.Text = if selectedItem.State == "Owned" then "LIST ON FLIPTAG" elseif selectedItem.State == "Listed" then "DELIVERY IN PROGRESS" else "ALREADY SOLD"
	listButton.TextColor3 = if selectedItem.State == "Owned" then Theme.Paper else Theme.Muted
	refreshEquipped()
end

local function makeItemCard(item: ClothingItem, order: number)
	local card = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if selectedItem == item then Theme.SurfaceLight else Theme.Surface,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Text = "",
		ZIndex = 12,
		Parent = inventoryGrid,
	}) :: TextButton
	addCorner(card, 13)
	addStroke(card, if selectedItem == item then Theme.Lime else Theme.SurfaceLight, if selectedItem == item then 2 else 1)
	addPadding(card, 12, 12, 11, 11)

	createGarmentPreview(card, item, UDim2.fromOffset(12, 11), UDim2.new(1, -24, 0, 92), 13)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 113),
		Font = Enum.Font.GothamBold,
		Text = string.upper(item.Brand),
		TextColor3 = rarityColor(item),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 41),
		Position = UDim2.fromOffset(0, 133),
		Font = Enum.Font.GothamBold,
		Text = item.Name,
		TextColor3 = Theme.Paper,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 178),
		Font = Enum.Font.GothamMedium,
		Text = item.Style .. " · " .. item.Rarity,
		TextColor3 = Theme.Muted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -27),
		Font = Enum.Font.GothamBlack,
		Text = "$" .. formatCoins(item.Value),
		TextColor3 = Theme.Paper,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	if item.Limited then
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 1, -47),
			Font = Enum.Font.GothamBold,
			Text = item.Limited,
			TextColor3 = Theme.Limited,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 13,
			Parent = card,
		})
	end
	if item.State ~= "Owned" then
		create("TextLabel", {
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.14,
			Size = UDim2.new(1, 0, 0, 26),
			Position = UDim2.new(0, 0, 0.5, -13),
			Font = Enum.Font.GothamBold,
			Text = if item.State == "Listed" then "IN DELIVERY" else "SOLD",
			TextColor3 = Theme.Paper,
			TextSize = 10,
			ZIndex = 14,
			Parent = card,
		})
	end
	card.MouseButton1Click:Connect(function()
		selectedItem = item
		refreshInventory()
	end)
end

refreshInventory = function()
	for _, child in ipairs(inventoryGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
	for category, button in pairs(categoryButtons) do
		local selected = category == currentCategory
		button.BackgroundColor3 = if selected then Theme.Lime else Theme.SurfaceLight
		button.TextColor3 = if selected then Theme.Background else Theme.Paper
	end
	local order = 0
	for _, item in ipairs(inventory) do
		if item.Category == currentCategory then
			order += 1
			makeItemCard(item, order)
		end
	end
	refreshInspector()
	cashLabel.Text = "$" .. formatCoins(coins)
end

for category, button in pairs(categoryButtons) do
	button.MouseButton1Click:Connect(function()
		currentCategory = category
		refreshInventory()
	end)
end

equipButton.MouseButton1Click:Connect(function()
	if selectedItem.State ~= "Owned" then
		showToast("THIS ITEM IS NOT IN YOUR WARDROBE", Theme.Danger)
		return
	end
	equipped[selectedItem.Category] = selectedItem
	showToast(selectedItem.Name .. " EQUIPPED", Theme.Lime)
	refreshInventory()
end)

-- Fit builder --------------------------------------------------------------
local fitHeader = create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.new(1, 0, 0, 88),
	ZIndex = 11,
	Parent = fitWindow,
}) :: Frame
addCorner(fitHeader, 20)
create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 1, -24),
	ZIndex = 11,
	Parent = fitHeader,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0.7, 0, 0, 31),
	Position = UDim2.fromOffset(28, 17),
	Font = Enum.Font.GothamBlack,
	Text = "FIT BUILDER",
	TextColor3 = Theme.White,
	TextSize = 25,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = fitHeader,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0.7, 0, 0, 18),
	Position = UDim2.fromOffset(29, 49),
	Font = Enum.Font.GothamMedium,
	Text = "DRAG A PIECE FROM YOUR WARDROBE INTO A SLOT",
	TextColor3 = Theme.SurfaceLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = fitHeader,
})
local fitClose = makeButton(fitHeader, "×", UDim2.fromOffset(44, 44), false)
fitClose.AnchorPoint = Vector2.new(1, 0.5)
fitClose.Position = UDim2.new(1, -22, 0.5, 0)
fitClose.ZIndex = 13
fitClose.MouseButton1Click:Connect(closeWindows)

local fitCloset = create("ScrollingFrame", {
	BackgroundColor3 = Theme.Surface,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(324, 0),
	Position = UDim2.fromOffset(24, 106),
	AnchorPoint = Vector2.new(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = Theme.Lime,
	ZIndex = 11,
	Parent = fitWindow,
}) :: ScrollingFrame
fitCloset.Size = UDim2.new(0, 324, 1, -130)
addCorner(fitCloset, 16)
addPadding(fitCloset, 12, 12, 13, 13)
create("UIListLayout", {
	Padding = UDim.new(0, 8),
	Parent = fitCloset,
})

local fitStage = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(222, 237, 255),
	Size = UDim2.new(1, -388, 1, -130),
	Position = UDim2.fromOffset(364, 106),
	ZIndex = 11,
	Parent = fitWindow,
}) :: Frame
addCorner(fitStage, 16)
addStroke(fitStage, Theme.SurfaceLight, 1)
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.fromOffset(0, 14),
	Font = Enum.Font.GothamBold,
	Text = "YOUR CURRENT FIT",
	TextColor3 = Theme.Muted,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 12,
	Parent = fitStage,
})

-- A clean mannequin keeps the outfit screen readable until character clothing models are added.
local mannequin = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(154, 350),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.55, 0),
	ZIndex = 12,
	Parent = fitStage,
}) :: Frame
local mannequinParts = {
	{ UDim2.fromOffset(64, 64), UDim2.fromOffset(45, 0), 30 },
	{ UDim2.fromOffset(92, 111), UDim2.fromOffset(31, 72), 18 },
	{ UDim2.fromOffset(26, 112), UDim2.fromOffset(0, 86), 12 },
	{ UDim2.fromOffset(26, 112), UDim2.fromOffset(128, 86), 12 },
	{ UDim2.fromOffset(38, 125), UDim2.fromOffset(37, 188), 11 },
	{ UDim2.fromOffset(38, 125), UDim2.fromOffset(79, 188), 11 },
}
for _, detail in ipairs(mannequinParts) do
	local bodyPart = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Size = detail[1],
		Position = detail[2],
		ZIndex = 12,
		Parent = mannequin,
	})
	addCorner(bodyPart, detail[3])
end

type FitDropSlot = {
	Frame: Frame,
	ItemLabel: TextLabel,
	Category: string,
}

local fitDropSlots: { [string]: FitDropSlot } = {}
local fitSlotData = {
	{ Category = "Head", Label = "HEAD", Position = UDim2.new(0.5, -77, 0.12, 0), Size = UDim2.fromOffset(154, 66) },
	{ Category = "Top", Label = "TOP", Position = UDim2.new(0.5, -86, 0.34, 0), Size = UDim2.fromOffset(172, 70) },
	{ Category = "Bottom", Label = "BOTTOM", Position = UDim2.new(0.5, -86, 0.56, 0), Size = UDim2.fromOffset(172, 70) },
	{ Category = "Shoes", Label = "SHOES", Position = UDim2.new(0.5, -86, 0.79, 0), Size = UDim2.fromOffset(172, 70) },
	{ Category = "Accessory", Label = "EXTRA ACC", Position = UDim2.new(0.75, 14, 0.39, 0), Size = UDim2.fromOffset(140, 62) },
}

for _, slotData in ipairs(fitSlotData) do
	local slot = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Size = slotData.Size,
		Position = slotData.Position,
		ZIndex = 14,
		Parent = fitStage,
	}) :: Frame
	addCorner(slot, 12)
	addStroke(slot, Theme.Lime, 1)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 16),
		Position = UDim2.fromOffset(8, 7),
		Font = Enum.Font.GothamBold,
		Text = slotData.Label,
		TextColor3 = Theme.Muted,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 15,
		Parent = slot,
	})
	local itemLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 25),
		Position = UDim2.fromOffset(8, 26),
		Font = Enum.Font.GothamBold,
		Text = "DROP ITEM HERE",
		TextColor3 = Theme.Muted,
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 15,
		Parent = slot,
	}) :: TextLabel
	fitDropSlots[slotData.Category] = { Frame = slot, ItemLabel = itemLabel, Category = slotData.Category }
end

local fitValue = create("TextLabel", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.fromOffset(148, 32),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 14),
	Font = Enum.Font.GothamBlack,
	Text = "FIT VALUE  $0",
	TextColor3 = Theme.White,
	TextSize = 12,
	ZIndex = 16,
	Parent = fitStage,
}) :: TextLabel
addCorner(fitValue, 12)

local draggedItem: ClothingItem? = nil
local dragGhost: Frame? = nil
local isDraggingFitItem = false

local function updateDragGhost(position: Vector3)
	if dragGhost then
		dragGhost.Position = UDim2.fromOffset(position.X - 70, position.Y - 40)
	end
end

local function beginFitDrag(item: ClothingItem, position: Vector3)
	if item.State ~= "Owned" then
		showToast("ONLY OWNED ITEMS CAN BE WORN", Theme.Danger)
		return
	end
	draggedItem = item
	isDraggingFitItem = true
	dragGhost = create("Frame", {
		BackgroundColor3 = Theme.LimeDark,
		Size = UDim2.fromOffset(140, 80),
		ZIndex = 50,
		Parent = screenGui,
	}) :: Frame
	addCorner(dragGhost, 13)
	addStroke(dragGhost, Theme.White, 1)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		Font = Enum.Font.GothamBold,
		Text = item.Name,
		TextColor3 = Theme.White,
		TextSize = 12,
		TextWrapped = true,
		ZIndex = 51,
		Parent = dragGhost,
	})
	updateDragGhost(position)
end

local function isInside(gui: GuiObject, position: Vector3): boolean
	local guiPosition = gui.AbsolutePosition
	local guiSize = gui.AbsoluteSize
	return position.X >= guiPosition.X and position.X <= guiPosition.X + guiSize.X and position.Y >= guiPosition.Y and position.Y <= guiPosition.Y + guiSize.Y
end

local function endFitDrag(position: Vector3)
	if not isDraggingFitItem or not draggedItem then
		return
	end
	local dropped = false
	for category, slot in pairs(fitDropSlots) do
		if isInside(slot.Frame, position) then
			dropped = true
			if category == draggedItem.Category then
				equipped[category] = draggedItem
				showToast(draggedItem.Name .. " ADDED TO YOUR FIT", Theme.Lime)
			else
				showToast("DROP " .. string.upper(draggedItem.Category) .. " INTO ITS OWN SLOT", Theme.Danger)
			end
			break
		end
	end
	if not dropped then
		showToast("DROP THE ITEM ON A FIT SLOT", Theme.Danger)
	end
	if dragGhost then
		dragGhost:Destroy()
	end
	dragGhost = nil
	draggedItem = nil
	isDraggingFitItem = false
	refreshFit()
	refreshInventory()
end

local function makeFitWardrobeCard(item: ClothingItem)
	local card = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.SurfaceLight,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 88),
		Text = "",
		ZIndex = 12,
		Parent = fitCloset,
	}) :: TextButton
	addCorner(card, 12)
	createGarmentPreview(card, item, UDim2.fromOffset(8, 8), UDim2.fromOffset(80, 72), 13)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -108, 0, 16),
		Position = UDim2.fromOffset(98, 12),
		Font = Enum.Font.GothamBold,
		Text = string.upper(item.Brand),
		TextColor3 = rarityColor(item),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -108, 0, 32),
		Position = UDim2.fromOffset(98, 29),
		Font = Enum.Font.GothamBold,
		Text = item.Name,
		TextColor3 = Theme.Paper,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -108, 0, 15),
		Position = UDim2.fromOffset(98, 62),
		Font = Enum.Font.GothamMedium,
		Text = "DRAG TO " .. string.upper(item.Category),
		TextColor3 = Theme.Muted,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginFitDrag(item, input.Position)
		end
	end)
end

refreshFit = function()
	clearChildrenExceptLayout(fitCloset)
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			makeFitWardrobeCard(item)
		end
	end
	local value = 0
	for category, slot in pairs(fitDropSlots) do
		local item = equipped[category]
		if item then
			slot.ItemLabel.Text = item.Name
			slot.ItemLabel.TextColor3 = rarityColor(item)
			slot.Frame.BackgroundColor3 = Theme.White
			value += item.Value
		else
			slot.ItemLabel.Text = "DROP ITEM HERE"
			slot.ItemLabel.TextColor3 = Theme.Muted
			slot.Frame.BackgroundColor3 = Theme.Surface
		end
	end
	fitValue.Text = "FIT VALUE  $" .. formatCoins(value)
end

fitButton.MouseButton1Click:Connect(function()
	openWindow(fitWindow)
	refreshFit()
end)

UserInputService.InputChanged:Connect(function(input)
	if isDraggingFitItem and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateDragGhost(input.Position)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if isDraggingFitItem and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		endFitDrag(input.Position)
	end
end)

-- Phone window -------------------------------------------------------------
local phoneTop = create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.new(1, 0, 0, 82),
	Position = UDim2.fromOffset(0, 38),
	ZIndex = 11,
	Parent = phoneScreen,
}) :: Frame
addCorner(phoneTop, 20)
create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 25),
	Position = UDim2.new(0, 0, 1, -25),
	ZIndex = 11,
	Parent = phoneTop,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -86, 0, 32),
	Position = UDim2.fromOffset(24, 17),
	Font = Enum.Font.GothamBlack,
	Text = "FLIPTAG",
	TextColor3 = Theme.White,
	TextSize = 27,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = phoneTop,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -86, 0, 18),
	Position = UDim2.fromOffset(25, 46),
	Font = Enum.Font.GothamMedium,
	Text = "SELL IT. SHIP IT. FLEX IT.",
	TextColor3 = Theme.SurfaceLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = phoneTop,
})
local phoneClose = makeButton(phoneTop, "×", UDim2.fromOffset(42, 42), false)
phoneClose.AnchorPoint = Vector2.new(1, 0.5)
phoneClose.Position = UDim2.new(1, -17, 0.5, 0)
phoneClose.ZIndex = 13
phoneClose.MouseButton1Click:Connect(closeWindows)

local phoneTabs = create("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.new(1, 0, 0, 52),
	Position = UDim2.fromOffset(0, 120),
	ZIndex = 11,
	Parent = phoneScreen,
}) :: Frame
addPadding(phoneTabs, 18, 18, 8, 8)
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	Parent = phoneTabs,
})
local phoneTabButtons: { [string]: TextButton } = {}
for _, tab in ipairs({ "LISTINGS", "DELIVERIES", "UPGRADES" }) do
	local button = makeButton(phoneTabs, tab, UDim2.new(1 / 3, -4, 1, 0), false)
	button.ZIndex = 12
	phoneTabButtons[tab] = button
end

local phoneContent = create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -36, 1, -198),
	Position = UDim2.fromOffset(18, 181),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Theme.Lime,
	ZIndex = 11,
	Parent = phoneScreen,
}) :: ScrollingFrame
create("UIListLayout", {
	Padding = UDim.new(0, 9),
	Parent = phoneContent,
})

local function addPhoneLabel(text: string, muted: boolean?)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = if muted then Theme.Muted else Theme.Paper,
		TextSize = if muted then 10 else 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
		Parent = phoneContent,
	})
end

local function addPhoneCard(item: ClothingItem, actionText: string, action: () -> ())
	local card = create("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 100),
		ZIndex = 12,
		Parent = phoneContent,
	}) :: Frame
	addCorner(card, 13)
	addPadding(card, 13, 13, 12, 12)
	local bar = create("Frame", {
		BackgroundColor3 = rarityColor(item),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(4, 58),
		ZIndex = 13,
		Parent = card,
	})
	addCorner(bar, 4)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 0, 17),
		Position = UDim2.fromOffset(14, 1),
		Font = Enum.Font.GothamBold,
		Text = string.upper(item.Brand),
		TextColor3 = rarityColor(item),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 0, 35),
		Position = UDim2.fromOffset(14, 20),
		Font = Enum.Font.GothamBold,
		Text = item.Name,
		TextColor3 = Theme.Paper,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 0, 18),
		Position = UDim2.fromOffset(14, 61),
		Font = Enum.Font.GothamMedium,
		Text = "$" .. formatCoins(item.Value),
		TextColor3 = Theme.Muted,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	local button = makeButton(card, actionText, UDim2.fromOffset(105, 38), actionText == "POST")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.ZIndex = 14
	button.MouseButton1Click:Connect(action)
end

refreshPhone = function()
	clearChildrenExceptLayout(phoneContent)
	for tab, button in pairs(phoneTabButtons) do
		local selected = tab == currentPhoneTab
		button.BackgroundColor3 = if selected then Theme.Lime else Theme.SurfaceLight
		button.TextColor3 = if selected then Theme.Background else Theme.Paper
	end

	if currentPhoneTab == "LISTINGS" then
		addPhoneLabel("READY TO POST")
		local posted = 0
		for _, item in ipairs(inventory) do
			if item.State == "Owned" then
				posted += 1
				addPhoneCard(item, "POST", function()
					item.State = "Listed"
					table.insert(shipments, { Item = item, FinishAt = os.clock() + 18 })
					showToast(item.Name .. " IS ON THE WAY", Theme.Lime)
					refreshInventory()
					refreshPhone()
				end)
			end
		end
		if posted == 0 then
			addPhoneLabel("NO ITEMS READY. FIND MORE PIECES IN A THRIFT STORE.", true)
		end
	elseif currentPhoneTab == "DELIVERIES" then
		addPhoneLabel("ACTIVE SHIPMENTS")
		if #shipments == 0 then
			addPhoneLabel("NOTHING IS ON THE ROAD RIGHT NOW.", true)
		end
		for _, shipment in ipairs(shipments) do
			local secondsLeft = math.max(0, math.ceil(shipment.FinishAt - os.clock()))
			addPhoneCard(shipment.Item, string.format("%02ds", secondsLeft), function()
				showToast("WAIT FOR THE BUYER'S PAYMENT", Theme.Lime)
			end)
		end
	elseif currentPhoneTab == "UPGRADES" then
		addPhoneLabel("APP UPGRADES")
		local upgrades = {
			{ Name = "QUICKSHIP I", Description = "Shorter delivery times", Cost = 700 },
			{ Name = "SAFEBOX I", Description = "Lower lost-package chance", Cost = 900 },
			{ Name = "BOOSTER I", Description = "Better buyer reach", Cost = 1100 },
		}
		for _, upgrade in ipairs(upgrades) do
			local row = create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 84),
				ZIndex = 12,
				Parent = phoneContent,
			}) :: Frame
			addCorner(row, 13)
			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -112, 0, 19),
				Position = UDim2.fromOffset(13, 13),
				Font = Enum.Font.GothamBold,
				Text = upgrade.Name,
				TextColor3 = Theme.Paper,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 13,
				Parent = row,
			})
			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -112, 0, 18),
				Position = UDim2.fromOffset(13, 37),
				Font = Enum.Font.GothamMedium,
				Text = upgrade.Description,
				TextColor3 = Theme.Muted,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 13,
				Parent = row,
			})
			local buy = makeButton(row, "$" .. formatCoins(upgrade.Cost), UDim2.fromOffset(91, 35), false)
			buy.AnchorPoint = Vector2.new(1, 0.5)
			buy.Position = UDim2.new(1, -12, 0.5, 0)
			buy.ZIndex = 14
			buy.MouseButton1Click:Connect(function()
				showToast("UPGRADE LOGIC COMES IN THE NEXT STEP", Theme.Lime)
			end)
		end
	end
end

for tab, button in pairs(phoneTabButtons) do
	button.MouseButton1Click:Connect(function()
		currentPhoneTab = tab
		refreshPhone()
	end)
end

listButton.MouseButton1Click:Connect(function()
	if selectedItem.State ~= "Owned" then
		showToast("THIS ITEM CANNOT BE LISTED", Theme.Danger)
		return
	end
	openWindow(phoneWindow)
	currentPhoneTab = "LISTINGS"
	refreshPhone()
	showToast("POST " .. selectedItem.Name .. " FROM YOUR PHONE", Theme.Lime)
end)

inventoryButton.MouseButton1Click:Connect(function()
	openWindow(inventoryWindow)
	refreshInventory()
end)

phoneDockButton.MouseButton1Click:Connect(function()
	openWindow(phoneWindow)
	refreshPhone()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		openWindow(inventoryWindow)
		refreshInventory()
	elseif input.KeyCode == Enum.KeyCode.F then
		openWindow(fitWindow)
		refreshFit()
	elseif input.KeyCode == Enum.KeyCode.P then
		openWindow(phoneWindow)
		refreshPhone()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		closeWindows()
	end
end)

task.spawn(function()
	while screenGui.Parent do
		task.wait(1)
		local paidOut = false
		for index = #shipments, 1, -1 do
			local shipment = shipments[index]
			if os.clock() >= shipment.FinishAt then
				shipment.Item.State = "Sold"
				coins += shipment.Item.Value
				table.remove(shipments, index)
				paidOut = true
				showToast("SOLD: +$" .. formatCoins(shipment.Item.Value), Theme.Lime)
			end
		end
		if paidOut then
			refreshInventory()
		end
		if phoneWindow.Visible and currentPhoneTab == "DELIVERIES" then
			refreshPhone()
		end
	end
end)

-- The server owns the donation-bin interaction. This client hook only displays
-- the received item in the prototype wardrobe; persistence moves server-side next.
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("ThriftRemotes")
	local remote = remotes:WaitForChild("ClothingFound")
	if not remote:IsA("RemoteEvent") then
		return
	end

	remote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.Type ~= "Found" or type(payload.Item) ~= "table" then
			return
		end

		task.spawn(animateClothingRoll, payload.Item)
	end)
end)

refreshInventory()
refreshFit()
refreshPhone()
showToast("WELCOME TO THRIFT//RUN", Theme.Lime)
