--!strict
-- Thrifting Simulator - clickable GUI prototype
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts when working directly in Roblox Studio.
-- It uses local mock data for now; the real inventory and economy will be connected later.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CaptureService = game:GetService("CaptureService")
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

local SocialTheme = {
	Background = Color3.fromRGB(240, 250, 246),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceLight = Color3.fromRGB(220, 243, 232),
	Purple = Color3.fromRGB(48, 177, 119),
	PurpleDark = Color3.fromRGB(27, 125, 82),
	Pink = Color3.fromRGB(91, 205, 150),
	Text = Color3.fromRGB(19, 58, 43),
	Muted = Color3.fromRGB(91, 132, 113),
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
local appUpgradeLevels = {
	QUICKSHIP = 0,
	SAFEBOX = 0,
	BOOSTER = 0,
}
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
local currentPhoneApp = "HOME"
local currentSocialTab = "FYP"
local socialSearchQuery = ""
local socialFollowers: { [string]: number } = {}
local socialBios: { [string]: string } = {}
local socialPhotos: { { Owner: string, Caption: string, Pose: string, Likes: number, CaptureContent: string?, PhotoId: string? } } = {}
local profileName = player.Name
local tradeTarget: string? = nil
local tradeSessionActive = false
local tradeIncomingFrom: string? = nil
local tradeMyOffer: { string } = {}
local tradeTheirOffer: { string } = {}
local tradeMyReady = false
local tradeTheirReady = false
local tradeStatus = "IDLE"
local roGramRemotes: Folder? = nil
local setBioRemote: RemoteEvent? = nil
local tradeRemote: RemoteEvent? = nil
local photoRemote: RemoteEvent? = nil
local cameraMode = "FRONT"
local cameraYaw = 0
local cameraPitch = 0
local cameraActive = false
local savedCameraType: Enum.CameraType? = nil
local savedCameraCFrame: CFrame? = nil
local savedCameraFov: number? = nil
local cameraDistance = 7
local cameraOverlay: Frame? = nil
local cameraReticle: Frame? = nil
local cameraHud: Frame? = nil
local cameraShutter: TextButton? = nil
local cameraCaptionBox: TextBox? = nil
local socialPaletteActive = false
local toastVersion = 0
local toastQueue: { { message: string, accent: Color3? } } = {}
local toastShowing = false
local refreshInventory: () -> ()
local refreshFit: () -> ()
local refreshPhone: () -> ()
local setCameraActive: (boolean) -> ()
local updateCameraView: () -> ()
local updateCameraFrame: () -> ()

local pendingPhotoContent: string? = nil
local pendingPhotoId: string? = nil
local pendingPhotoPose = "FRONT"
local postPreviewModal: Frame? = nil
local postPreviewImage: ImageLabel? = nil
local postPreviewCaption: TextBox? = nil

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

-- Server-backed ro-gram/trade remotes. The separate server script creates these.
-- The client remains usable without them, but cross-player trade/bio sync needs the server script.
local remoteFolder = ReplicatedStorage:FindFirstChild("RoGramRemotes")
if remoteFolder and remoteFolder:IsA("Folder") then
	roGramRemotes = remoteFolder
	local bioRemote = remoteFolder:FindFirstChild("SetBio")
	local tRemote = remoteFolder:FindFirstChild("Trade")
	local pRemote = remoteFolder:FindFirstChild("PhotoPosted")
	if bioRemote and bioRemote:IsA("RemoteEvent") then setBioRemote = bioRemote end
	if tRemote and tRemote:IsA("RemoteEvent") then tradeRemote = tRemote end
	if pRemote and pRemote:IsA("RemoteEvent") then photoRemote = pRemote end
end

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
	local accentColor = if currentPhoneApp == "SOCIAL" then SocialTheme.Purple else Theme.Lime
	local accentTextColor = if currentPhoneApp == "SOCIAL" then SocialTheme.Text else Theme.Background
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if accent then accentColor else Theme.Surface,
		Size = size,
		Font = Enum.Font.GothamBold,
	Text = text,
		TextColor3 = if accent then accentTextColor else Theme.Paper,
	TextSize = 14,
		Parent = parent,
	}) :: TextButton
	addCorner(button, 12)
	addStroke(button, if accent then Theme.Lime else Theme.SurfaceLight, 1)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = if accent
				then if currentPhoneApp == "SOCIAL" then SocialTheme.PurpleDark else Color3.fromRGB(92, 157, 255)
				else Theme.SurfaceLight,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = if accent
				then if currentPhoneApp == "SOCIAL" then SocialTheme.Purple else Theme.Lime
				else Theme.Surface,
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

local function processToastQueue()
	if toastShowing then
		return
	end

	toastShowing = true

	task.spawn(function()
		while #toastQueue > 0 do
			local nextToast = table.remove(toastQueue, 1)
			if not nextToast then
				break
			end

			toastVersion += 1
			toastLabel.Text = nextToast.message
			toast.BackgroundColor3 = nextToast.accent or Theme.Paper
			toastLabel.TextColor3 = Theme.Background

			TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 20),
			}):Play()

			task.wait(2.4)

			local hideTween = TweenService:Create(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -70),
			})
			hideTween:Play()
			hideTween.Completed:Wait()
		end

		toastShowing = false
	end)
end

local function showToast(message: string, accent: Color3?)
	table.insert(toastQueue, {
		message = message,
		accent = accent,
	})
	processToastQueue()
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
	addStroke(rollWindow, Theme.Lime, 4)

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
		BackgroundColor3 = Theme.Lime,
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
		BackgroundColor3 = Theme.Lime,
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
		addStroke(winnerCard, Theme.Lime, 3)

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
	BackgroundColor3 = Color3.fromRGB(231, 242, 255),
	Size = UDim2.fromOffset(414, 710),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 740),
	ClipsDescendants = false,
	Visible = false,
	ZIndex = 10,
	Parent = screenGui,
}) :: Frame
addCorner(phoneWindow, 38)
addStroke(phoneWindow, Color3.fromRGB(91, 145, 205), 2)

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
	BackgroundColor3 = Color3.fromRGB(210, 228, 248),
	Size = UDim2.fromOffset(106, 27),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	ZIndex = 20,
	Parent = phoneScreen,
}) :: Frame
addCorner(dynamicIsland, 15)
create("Frame", {
	BackgroundColor3 = Color3.fromRGB(75, 116, 165),
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
		BackgroundColor3 = Color3.fromRGB(91, 145, 205),
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
	setCameraActive(false)
	phoneDock.Visible = true
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
	local status = if selectedItem.State == "Owned" then "IN WARDROBE" elseif selectedItem.State == "Listed" then "ON DELIVERY" elseif selectedItem.State == "Traded" then "TRADED AWAY" else "SOLD"
	inspectorMeta.Text = string.format("%s · %s\n%s · $%s", selectedItem.Style, selectedItem.Rarity, status, formatCoins(selectedItem.Value))
	if selectedItem.Limited then
		inspectorMeta.Text ..= "\nLIMITED " .. selectedItem.Limited
	end

	local available = selectedItem.State == "Owned"
	equipButton.Text = if equipped[selectedItem.Category] == selectedItem then "EQUIPPED" else "EQUIP TO FIT"
	equipButton.BackgroundColor3 = if available then Theme.Lime else Theme.SurfaceLight
	equipButton.TextColor3 = if available then Theme.Background else Theme.Muted
	listButton.Text = if selectedItem.State == "Owned" then "LIST ON FLIPTAG" elseif selectedItem.State == "Listed" then "DELIVERY IN PROGRESS" elseif selectedItem.State == "Lost" then "PACKAGE LOST" elseif selectedItem.State == "Traded" then "TRADED AWAY" else "ALREADY SOLD"
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
			Text = if item.State == "Listed" then "IN DELIVERY" elseif item.State == "Lost" then "PACKAGE LOST" else "SOLD",
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

local function removeFromWardrobe(item: ClothingItem)
	for index, inventoryItem in ipairs(inventory) do
		if inventoryItem == item then
			table.remove(inventory, index)
			break
		end
	end

	for category, equippedItem in pairs(equipped) do
		if equippedItem == item then
			equipped[category] = nil
		end
	end

	if selectedItem == item and #inventory > 0 then
		selectedItem = inventory[1]
	end
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
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 1,
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
	if cameraActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		cameraYaw = math.clamp(cameraYaw + input.Delta.X * 0.004, -1.25, 1.25)
		cameraPitch = math.clamp(cameraPitch - input.Delta.Y * 0.004, -0.42, 0.42)
		updateCameraView()
	elseif cameraActive and input.UserInputType == Enum.UserInputType.MouseWheel then
		cameraDistance = math.clamp(cameraDistance - input.Position.Z * 0.45, 4, 10)
		updateCameraView()
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
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.fromOffset(0, 38),
	ZIndex = 11,
	Parent = phoneScreen,
}) :: Frame
addCorner(phoneTop, 20)
local phoneTopBottom = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 12),
	Position = UDim2.new(0, 0, 1, -12),
	ZIndex = 11,
	Parent = phoneTop,
}) :: Frame
local phoneTitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -86, 0, 24),
	Position = UDim2.fromOffset(18, 10),
	Font = Enum.Font.GothamBlack,
	Text = "FLIPTAG",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = phoneTop,
}) :: TextLabel
local phoneSubtitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -86, 0, 12),
	Position = UDim2.fromOffset(18, 30),
	Font = Enum.Font.GothamMedium,
	Text = "SELL IT. SHIP IT. FLEX IT.",
	TextColor3 = Theme.SurfaceLight,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 12,
	Parent = phoneTop,
}) :: TextLabel
local phoneClose = makeButton(phoneTop, "×", UDim2.fromOffset(34, 34), false)
phoneClose.AnchorPoint = Vector2.new(1, 0.5)
phoneClose.Position = UDim2.new(1, -10, 0.5, 0)
phoneClose.ZIndex = 13
phoneClose.BackgroundColor3 = Color3.fromRGB(245, 248, 252)
phoneClose.TextColor3 = Color3.fromRGB(55, 65, 80)
phoneClose.TextSize = 20
phoneClose.AutoButtonColor = false
phoneClose.MouseButton1Click:Connect(function()
	-- Inside an app, X returns to the phone desktop instead of closing the phone.
	if currentPhoneApp ~= "HOME" then
		setCameraActive(false)
		currentPhoneApp = "HOME"
		currentSocialTab = "FYP"
		currentPhoneTab = "LISTINGS"
		phoneWindow.Visible = true
		backdrop.Visible = true
		refreshPhone()
	else
		closeWindows()
	end
end)

local phoneTabs = create("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.new(1, 0, 0, 52),
	Position = UDim2.fromOffset(0, 88),
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
	local button = makeButton(phoneTabs, tab, UDim2.new(1 / 3, -5, 1, 0), false)
	button.ZIndex = 12
	phoneTabButtons[tab] = button
end
for _, tab in ipairs({ "FYP", "PROFILE", "CAMERA" }) do
	local button = makeButton(phoneTabs, tab, UDim2.new(1 / 4, -5, 1, 0), false)
	button.ZIndex = 12
	button.Visible = false
	phoneTabButtons[tab] = button
end

local phoneContent = create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -36, 1, -166),
	Position = UDim2.fromOffset(18, 149),
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

-- REAL CAMERA OVERLAY -------------------------------------------------------
-- The 3D world remains visible behind this transparent camera UI. The
-- camera itself is controlled through Workspace.CurrentCamera (Scriptable).
cameraOverlay = create("Frame", {
	Name = "RoGramCameraOverlay",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 80,
	Parent = screenGui,
}) :: Frame

-- Portrait camera frame: the live camera and final photo are composed inside a
-- 9:16 phone-shaped area. The dark mask outside it makes the capture boundary
-- obvious and also lets CaptureScreenshot keep only the central phone area.
local cameraCaptureMask = create("Frame", {
	Name = "CameraCaptureMask",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 80,
	Parent = cameraOverlay,
}) :: Frame

local cameraMaskTop = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame
local cameraMaskBottom = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame
local cameraMaskLeft = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame
local cameraMaskRight = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame

local cameraFrameGuide = create("Frame", {
	Name = "PhoneCameraFrame",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 89,
	Parent = cameraOverlay,
}) :: Frame
create("UIAspectRatioConstraint", {
	AspectRatio = 9 / 16,
	DominantAxis = Enum.DominantAxis.Height,
	Parent = cameraFrameGuide,
})
addStroke(cameraFrameGuide, SocialTheme.Text, 5, 0.02)
addCorner(cameraFrameGuide, 24)

local cameraFrameInner = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -10, 1, -10),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 90,
	Parent = cameraFrameGuide,
}) :: Frame
addCorner(cameraFrameInner, 20)
addStroke(cameraFrameInner, SocialTheme.Purple, 2, 0.08)

local cameraFrameTopGlow = create("Frame", {
	BackgroundColor3 = SocialTheme.Purple,
	BackgroundTransparency = 0.0,
	BorderSizePixel = 0,
	Size = UDim2.new(0.62, 0, 0, 3),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	ZIndex = 90,
	Parent = cameraFrameGuide,
}) :: Frame
addCorner(cameraFrameTopGlow, 2)

local cameraTopBar = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(7, 6, 12),
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 96),
	Position = UDim2.fromOffset(0, 0),
	ZIndex = 81,
	Parent = cameraOverlay,
}) :: Frame
local cameraTopTitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -160, 0, 30),
	Position = UDim2.fromOffset(28, 23),
	Font = Enum.Font.GothamBlack,
	Text = "RO-GRAM",
	TextColor3 = SocialTheme.Text,
	TextSize = 25,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 82,
	Parent = cameraTopBar,
})
create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -160, 0, 20),
	Position = UDim2.fromOffset(29, 54),
	Font = Enum.Font.GothamMedium,
	Text = "CAMERA  ·  FIT CAPTURE",
	TextColor3 = SocialTheme.Muted,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 82,
	Parent = cameraTopBar,
})

local cameraClose = create("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Size = UDim2.fromOffset(44, 44),
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -24, 0.5, 0),
	Font = Enum.Font.GothamBlack,
	Text = "×",
	TextColor3 = Color3.fromRGB(12, 8, 18),
	TextSize = 22,
	ZIndex = 83,
	Parent = cameraTopBar,
}) :: TextButton
addCorner(cameraClose, 14)

local cameraBottomBar = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(7, 6, 12),
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 170),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	ZIndex = 81,
	Parent = cameraOverlay,
}) :: Frame

cameraHud = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -48, 0, 52),
	Position = UDim2.fromOffset(24, 18),
	ZIndex = 82,
	Parent = cameraBottomBar,
}) :: Frame

local cameraModeButton = makeButton(cameraHud, "FRONT CAMERA", UDim2.fromOffset(128, 42), true)
cameraModeButton.BackgroundColor3 = SocialTheme.Purple
cameraModeButton.TextColor3 = SocialTheme.Text
cameraModeButton.ZIndex = 83

local cameraZoomOut = makeButton(cameraHud, "−", UDim2.fromOffset(42, 42), false)
cameraZoomOut.Position = UDim2.fromOffset(138, 0)
cameraZoomOut.ZIndex = 83

local cameraZoomLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(70, 42),
	Position = UDim2.fromOffset(184, 0),
	Font = Enum.Font.GothamBlack,
	Text = "1.0×",
	TextColor3 = SocialTheme.Text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 83,
	Parent = cameraHud,
}) :: TextLabel

local cameraZoomIn = makeButton(cameraHud, "+", UDim2.fromOffset(42, 42), false)
cameraZoomIn.Position = UDim2.fromOffset(258, 0)
cameraZoomIn.ZIndex = 83

cameraReticle = create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(88, 88),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 82,
	Parent = cameraOverlay,
}) :: Frame
addStroke(cameraReticle, SocialTheme.Text, 1, 0.45)
addCorner(cameraReticle, 44)

local reticleH = create("Frame", {
	BackgroundColor3 = SocialTheme.Text,
	BackgroundTransparency = 0.35,
	Size = UDim2.fromOffset(1, 28),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 83,
	Parent = cameraReticle,
})
local reticleV = create("Frame", {
	BackgroundColor3 = SocialTheme.Text,
	BackgroundTransparency = 0.35,
	Size = UDim2.fromOffset(28, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 83,
	Parent = cameraReticle,
})

local cameraStatus = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -48, 0, 1),
	Position = UDim2.new(0, 24, 0, 76),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextColor3 = SocialTheme.Text,
	TextTransparency = 0.12,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 83,
	Parent = cameraBottomBar,
}) :: TextLabel

cameraCaptionBox = nil

cameraShutter = create("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Size = UDim2.fromOffset(82, 82),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -25),
	Font = Enum.Font.GothamBlack,
	Text = "●",
	TextColor3 = SocialTheme.Purple,
	TextSize = 40,
	ZIndex = 84,
	Parent = cameraBottomBar,
}) :: TextButton
addCorner(cameraShutter, 41)
addStroke(cameraShutter, SocialTheme.Purple, 4)

local cameraFlash = create("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 120,
	Parent = cameraOverlay,
}) :: Frame

-- Post preview: shown only AFTER the photo is captured. The photo is not posted
-- until the player presses POST TO RO-GRAM.
local function closePostPreview()
	pendingPhotoContent = nil
	pendingPhotoId = nil
	if postPreviewCaption then postPreviewCaption.Text = "" end
	if postPreviewModal then postPreviewModal.Visible = false end
end

postPreviewModal = create("Frame", {
	Name = "RoGramPostPreview",
	BackgroundColor3 = Color3.fromRGB(7, 18, 14),
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 300,
	Parent = phoneScreen,
}) :: Frame

local postPreviewCard = create("Frame", {
	BackgroundColor3 = SocialTheme.Surface,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -32, 0, 500),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.53, 0),
	ZIndex = 301,
	Parent = postPreviewModal,
}) :: Frame
addCorner(postPreviewCard, 22)
addStroke(postPreviewCard, SocialTheme.Purple, 2, 0.15)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -100, 0, 30),
	Position = UDim2.fromOffset(18, 12),
	Font = Enum.Font.GothamBlack,
	Text = "NEW RO-GRAM POST",
	TextColor3 = SocialTheme.Text,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 302,
	Parent = postPreviewCard,
})

local postPreviewCancel = create("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = SocialTheme.SurfaceLight,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(34, 34),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = SocialTheme.Text,
	TextSize = 20,
	ZIndex = 303,
	Parent = postPreviewCard,
}) :: TextButton
addCorner(postPreviewCancel, 17)

postPreviewImage = create("ImageLabel", {
	BackgroundColor3 = SocialTheme.SurfaceLight,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -28, 0, 230),
	Position = UDim2.fromOffset(14, 52),
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 302,
	Parent = postPreviewCard,
}) :: ImageLabel
addCorner(postPreviewImage, 16)

create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -28, 0, 18),
	Position = UDim2.fromOffset(14, 292),
	Font = Enum.Font.GothamBold,
	Text = "ADD A DESCRIPTION (OPTIONAL)",
	TextColor3 = SocialTheme.Muted,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 302,
	Parent = postPreviewCard,
})

postPreviewCaption = create("TextBox", {
	Name = "PostDescription",
	BackgroundColor3 = Color3.fromRGB(248, 252, 250),
	BorderSizePixel = 0,
	PlaceholderText = "Write something about this photo...",
	PlaceholderColor3 = SocialTheme.Muted,
	Text = "",
	TextColor3 = SocialTheme.Text,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	ClearTextOnFocus = false,
	MultiLine = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.new(1, -28, 0, 60),
	Position = UDim2.fromOffset(14, 313),
	ZIndex = 302,
	Parent = postPreviewCard,
}) :: TextBox
addCorner(postPreviewCaption, 13)
addPadding(postPreviewCaption, 11, 11, 9, 9)

local postPreviewDiscard = create("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = SocialTheme.SurfaceLight,
	BorderSizePixel = 0,
	Size = UDim2.new(0.5, -18, 0, 40),
	Position = UDim2.new(0, 14, 1, -54),
	Font = Enum.Font.GothamBold,
	Text = "DISCARD",
	TextColor3 = SocialTheme.Muted,
	TextSize = 11,
	ZIndex = 302,
	Parent = postPreviewCard,
}) :: TextButton
addCorner(postPreviewDiscard, 14)

local postPreviewPost = create("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = SocialTheme.Purple,
	BorderSizePixel = 0,
	Size = UDim2.new(0.5, -18, 0, 40),
	Position = UDim2.new(0.5, 4, 1, -54),
	Font = Enum.Font.GothamBlack,
	Text = "POST TO RO-GRAM",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
	ZIndex = 302,
	Parent = postPreviewCard,
}) :: TextButton
addCorner(postPreviewPost, 14)

postPreviewCancel.MouseButton1Click:Connect(closePostPreview)
postPreviewDiscard.MouseButton1Click:Connect(function()
	closePostPreview()
	showToast("PHOTO DISCARDED", SocialTheme.Purple)
end)

postPreviewPost.MouseButton1Click:Connect(function()
	if not pendingPhotoContent or not pendingPhotoId then
		closePostPreview()
		return
	end
	local caption = ""
	if postPreviewCaption then
		caption = string.sub(string.gsub(postPreviewCaption.Text, "^%s*(.-)%s*$", "%1"), 1, 180)
	end
	local photoData = {
		Owner = player.Name,
		Caption = caption,
		Pose = pendingPhotoPose,
		Likes = 0,
		CaptureContent = pendingPhotoContent,
		PhotoId = pendingPhotoId,
	}
	table.insert(socialPhotos, 1, photoData)
	if photoRemote then
		photoRemote:FireServer("Post", photoData.PhotoId, photoData.Caption, photoData.Pose, photoData.Likes, photoData.CaptureContent)
	end
	closePostPreview()
	flashCamera()
	showToast("PHOTO POSTED TO RO-GRAM", SocialTheme.Purple)
	currentSocialTab = "PROFILE"
	profileName = player.Name
	currentPhoneApp = "SOCIAL"
	phoneWindow.Visible = true
	backdrop.Visible = true
	refreshPhone()
end)

local function addPhoneLabel(text: string, muted: boolean?)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = if currentPhoneApp == "SOCIAL"
			then if muted then SocialTheme.Muted else SocialTheme.Text
			else if muted then Theme.Muted else Theme.Paper,
		TextSize = if muted then 10 else 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
		Parent = phoneContent,
	})
end

local function addPhoneCard(item: ClothingItem, actionText: string, action: () -> ())
	local card = create("Frame", {
		BackgroundColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Surface else Theme.Surface,
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
		TextColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Purple else rarityColor(item),
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
		TextColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Text else Theme.Paper,
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
		TextColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Muted else Theme.Muted,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	local button = makeButton(card, actionText, UDim2.fromOffset(105, 38), actionText == "POST")
	if currentPhoneApp == "SOCIAL" then
		button.BackgroundColor3 = SocialTheme.Purple
		button.TextColor3 = SocialTheme.Text
	end
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.ZIndex = 14
	button.MouseButton1Click:Connect(action)
end

local function socialNames(): { string }
	local names = { player.Name }
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			table.insert(names, otherPlayer.Name)
		end
	end
	if #names == 1 then
		table.insert(names, "MikaArchive")
		table.insert(names, "SoleilVintage")
	end
	return names
end

local function socialCard(height: number): Frame
	local card = create("Frame", {
		BackgroundColor3 = SocialTheme.Surface,
		Size = UDim2.new(1, 0, 0, height),
		ZIndex = 12,
		Parent = phoneContent,
	}) :: Frame
	addCorner(card, 13)
	addPadding(card, 13, 13, 12, 12)
	return card
end

updateCameraFrame = function()
	if not cameraOverlay or not cameraFrameGuide then
		return
	end

	local viewportSize = screenGui.AbsoluteSize
	if viewportSize.X <= 0 or viewportSize.Y <= 0 then
		return
	end

	local frameHeight = viewportSize.Y
	local frameWidth = frameHeight * (9 / 16)
	if frameWidth > viewportSize.X then
		frameWidth = viewportSize.X
		frameHeight = frameWidth * (16 / 9)
	end

	local frameX = (viewportSize.X - frameWidth) / 2
	local frameY = (viewportSize.Y - frameHeight) / 2

	local function setRect(frame: Frame, x: number, y: number, w: number, h: number)
		frame.Position = UDim2.fromOffset(x, y)
		frame.Size = UDim2.fromOffset(math.max(0, w), math.max(0, h))
	end

	setRect(cameraMaskTop, 0, 0, viewportSize.X, frameY)
	setRect(cameraMaskBottom, 0, frameY + frameHeight, viewportSize.X, viewportSize.Y - (frameY + frameHeight))
	setRect(cameraMaskLeft, 0, frameY, frameX, frameHeight)
	setRect(cameraMaskRight, frameX + frameWidth, frameY, viewportSize.X - (frameX + frameWidth), frameHeight)
end

setCameraActive = function(active: boolean)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if active and not cameraActive then
		savedCameraType = camera.CameraType
		savedCameraCFrame = camera.CFrame
		savedCameraFov = camera.FieldOfView
		cameraActive = true
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 62
		cameraDistance = 7
		cameraYaw = 0
		cameraPitch = 0
		if cameraCaptionBox then cameraCaptionBox.Text = "" end
		phoneWindow.Active = false
		phoneDock.Visible = false
		if cameraOverlay then cameraOverlay.Visible = true end
		if cameraCaptureMask then cameraCaptureMask.Visible = true end
		if cameraFrameGuide then cameraFrameGuide.Visible = true end
		backdrop.Visible = false
		updateCameraFrame()
		updateCameraView()
	elseif not active and cameraActive then
		cameraActive = false
		phoneWindow.Active = true
		phoneDock.Visible = true
		if cameraOverlay then cameraOverlay.Visible = false end
		if cameraCaptureMask then cameraCaptureMask.Visible = false end
		if cameraFrameGuide then cameraFrameGuide.Visible = false end
		if activeWindow == phoneWindow and phoneWindow.Visible then backdrop.Visible = true end
		camera.CameraType = savedCameraType or Enum.CameraType.Custom
		camera.FieldOfView = savedCameraFov or 70
		if savedCameraCFrame then camera.CFrame = savedCameraCFrame end
	end
end

updateCameraView = function()
	if not cameraActive then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not root or not camera or not root:IsA("BasePart") then return end

	local rootPosition = root.Position + Vector3.new(0, 2.0, 0)
	local rootForward = root.CFrame.LookVector
	local yawRotation = CFrame.Angles(0, cameraYaw, 0)
	local pitchRotation = CFrame.Angles(cameraPitch, 0, 0)
	local viewDirection = yawRotation:VectorToWorldSpace(rootForward)
	local distance = cameraDistance

	if cameraMode == "SELFIE" then
		local cameraPosition = rootPosition + viewDirection * distance
		local target = rootPosition + Vector3.new(0, 0.1, 0)
		camera.CFrame = CFrame.lookAt(cameraPosition, target) * pitchRotation
	else
		local cameraPosition = rootPosition - viewDirection * distance
		local target = rootPosition + viewDirection * 3 + Vector3.new(0, 0.15, 0)
		camera.CFrame = CFrame.lookAt(cameraPosition, target) * pitchRotation
	end

	camera.Focus = CFrame.new(rootPosition)
	camera.FieldOfView = math.clamp(62 - ((7 - cameraDistance) * 4), 38, 70)
	if cameraZoomLabel then cameraZoomLabel.Text = string.format("%.1f×", 7 / cameraDistance) end
	if cameraModeButton then cameraModeButton.Text = if cameraMode == "SELFIE" then "SELFIE CAMERA" else "FRONT CAMERA" end
end

local function flashCamera()
	if not cameraFlash then
		return
	end
	cameraFlash.Visible = true
	cameraFlash.BackgroundTransparency = 0.05
	local tween = TweenService:Create(cameraFlash, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		cameraFlash.Visible = false
	end)
end

local function takeRoGramPhoto()
	if not cameraActive then
		return
	end
	local wasVisible = if cameraOverlay then cameraOverlay.Visible else false
	if cameraTopBar then cameraTopBar.Visible = false end
	if cameraBottomBar then cameraBottomBar.Visible = false end
	if cameraCaptionBox then cameraCaptionBox.Visible = false end
	if cameraReticle then cameraReticle.Visible = false end
	if cameraFrameGuide then cameraFrameGuide.Visible = false end
	if cameraFlash then cameraFlash.Visible = false end
	if cameraCaptureMask then cameraCaptureMask.Visible = true end
	updateCameraFrame()

	CaptureService:CaptureScreenshot(function(contentId)
		if cameraTopBar then cameraTopBar.Visible = true end
		if cameraBottomBar then cameraBottomBar.Visible = true end
		if cameraCaptionBox then cameraCaptionBox.Visible = false end
		if cameraReticle then cameraReticle.Visible = true end
		if cameraFrameGuide then cameraFrameGuide.Visible = true end
		if cameraCaptureMask then cameraCaptureMask.Visible = true end
		if cameraOverlay then cameraOverlay.Visible = wasVisible end

		if contentId then
			pendingPhotoId = player.UserId .. "_" .. tostring(math.floor(os.clock() * 1000000))
			pendingPhotoContent = tostring(contentId)
			pendingPhotoPose = cameraMode
			if postPreviewImage then
				postPreviewImage.Image = pendingPhotoContent
			end
			if postPreviewCaption then
				postPreviewCaption.Text = ""
			end
			setCameraActive(false)
			currentPhoneApp = "SOCIAL"
			currentSocialTab = "FYP"
			phoneWindow.Visible = true
			phoneWindow.Active = true
			backdrop.Visible = true
			refreshPhone()
			if postPreviewModal then postPreviewModal.Visible = true end
		else
			showToast("CAMERA CAPTURE FAILED", Theme.Danger)
		end
	end)
end

cameraClose.MouseButton1Click:Connect(function()
	setCameraActive(false)
	currentPhoneApp = "HOME"
	currentSocialTab = "FYP"
	currentPhoneTab = "LISTINGS"
	phoneWindow.Visible = true
	phoneDock.Visible = false
	backdrop.Visible = true
	refreshPhone()
end)

cameraModeButton.MouseButton1Click:Connect(function()
	cameraMode = if cameraMode == "SELFIE" then "FRONT" else "SELFIE"
	updateCameraView()
end)

cameraZoomOut.MouseButton1Click:Connect(function()
	cameraDistance = math.clamp(cameraDistance + 0.7, 4, 10)
	updateCameraView()
end)

cameraZoomIn.MouseButton1Click:Connect(function()
	cameraDistance = math.clamp(cameraDistance - 0.7, 4, 10)
	updateCameraView()
end)

cameraShutter.MouseButton1Click:Connect(takeRoGramPhoto)

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if cameraActive then
		updateCameraFrame()
	end
end)

local function getProfilePlayer(name: string): Player?
	local found = Players:FindFirstChild(name)
	if found and found:IsA("Player") then
		return found
	end
	return nil
end

local function getProfileBio(name: string): string
	local cached = socialBios[name]
	if cached ~= nil then
		return cached
	end
	local profilePlayer = getProfilePlayer(name)
	if profilePlayer then
		local attr = profilePlayer:GetAttribute("SocialBio")
		if type(attr) == "string" then
			socialBios[name] = attr
			return attr
		end
	end
	return "No bio yet."
end

local function openSocialProfile(name: string)
	profileName = name
	socialSearchQuery = name
	currentSocialTab = "PROFILE"
	tradeTarget = nil
	refreshPhone()
end

local function addSocialPhoto(owner: string, caption: string, pose: string, likes: number, captureContent: string?, photoId: string?)
	local isOwnPhoto = owner == player.Name and photoId ~= nil
	local card = socialCard(258)
	local photo = create("Frame", {
		BackgroundColor3 = SocialTheme.SurfaceLight,
		Size = UDim2.new(1, 0, 0, 182),
		ZIndex = 13,
		Parent = card,
	}) :: Frame
	addCorner(photo, 10)
	create("UIAspectRatioConstraint", {
		AspectRatio = 9 / 16,
		DominantAxis = Enum.DominantAxis.Width,
		Parent = photo,
	})

	if captureContent then
		local capturedImage = create("ImageLabel", {
			BackgroundColor3 = SocialTheme.SurfaceLight,
			BackgroundTransparency = 0,
			Image = captureContent,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 13,
			Parent = photo,
		}) :: ImageLabel
		addCorner(capturedImage, 10)
	else
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "RO-GRAM\nPHONE PHOTO",
			TextColor3 = SocialTheme.Muted,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
			Parent = photo,
		})
	end

	local ownerButton = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -20, 0, 32),
		Position = UDim2.fromOffset(10, 10),
		Text = "@" .. owner,
		TextColor3 = Color3.fromRGB(28, 38, 52),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 15,
		Parent = photo,
	}) :: TextButton
	addCorner(ownerButton, 9)
	addPadding(ownerButton, 10, 10, 0, 0)
	ownerButton.MouseButton1Click:Connect(function()
		openSocialProfile(owner)
	end)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 19),
		Position = UDim2.fromOffset(10, 148),
		Font = Enum.Font.GothamBold,
		Text = string.upper(pose) .. "  ·  " .. tostring(likes) .. " likes",
		TextColor3 = SocialTheme.Purple,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 15,
		Parent = card,
	})
	local captionLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -100, 0, 26),
		Position = UDim2.fromOffset(0, 177),
		Font = Enum.Font.GothamMedium,
		Text = caption,
		TextColor3 = SocialTheme.Text,
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	if isOwnPhoto then
		local deleteButton = makeButton(card, "DELETE", UDim2.fromOffset(76, 28), false)
		deleteButton.AnchorPoint = Vector2.new(1, 0)
		deleteButton.Position = UDim2.new(1, 0, 0, 175)
		deleteButton.BackgroundColor3 = SocialTheme.SurfaceLight
		deleteButton.TextColor3 = SocialTheme.Muted
		deleteButton.ZIndex = 15
		deleteButton.MouseButton1Click:Connect(function()
			for index, photoData in ipairs(socialPhotos) do
				if (photoId and photoData.PhotoId == photoId) or (not photoId and photoData.Caption == caption and photoData.Owner == owner) then
					table.remove(socialPhotos, index)
					break
				end
			end
			if photoRemote then
				photoRemote:FireServer("Delete", photoId)
			end
			showToast("PHOTO DELETED", SocialTheme.Purple)
			refreshPhone()
		end)
	end
end

local function makeSocialButton(parent: Instance, text: string, size: UDim2, filled: boolean?, compact: boolean?): TextButton
	local isFilled = filled == true
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if isFilled then SocialTheme.Purple else SocialTheme.Surface,
		Size = size,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = if isFilled then SocialTheme.Text else SocialTheme.PurpleDark,
		TextSize = if compact then 10 else 11,
		Parent = parent,
	}) :: TextButton
	addCorner(button, if compact then 18 else 10)
	addStroke(button, SocialTheme.Purple, if isFilled then 1 else 2, 0.05)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = if isFilled then SocialTheme.Pink else SocialTheme.SurfaceLight,
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = if isFilled then SocialTheme.Purple else SocialTheme.Surface,
		}):Play()
	end)
	return button
end

local function addSocialProfile(name: string, isOwnProfile: boolean)
	local profilePlayer = getProfilePlayer(name)
	local profileUserId = if profilePlayer then profilePlayer.UserId else player.UserId
	local card = socialCard(if isOwnProfile then 196 else 150)
	local avatar = create("ImageLabel", {
		BackgroundColor3 = SocialTheme.SurfaceLight,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(profileUserId) .. "&w=150&h=150",
		Size = UDim2.fromOffset(66, 66),
		Position = UDim2.fromOffset(0, 0),
		ZIndex = 14,
		Parent = card,
	}) :: ImageLabel
	addCorner(avatar, 33)
	addStroke(avatar, SocialTheme.Purple, 2)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -82, 0, 25),
		Position = UDim2.fromOffset(78, 0),
		Font = Enum.Font.GothamBlack,
		Text = "@" .. name,
		TextColor3 = SocialTheme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -82, 0, 21),
		Position = UDim2.fromOffset(78, 29),
		Font = Enum.Font.GothamMedium,
		Text = tostring(socialFollowers[name] or 0) .. " followers",
		TextColor3 = SocialTheme.Muted,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	local bioLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, if isOwnProfile then 46 else 62),
		Position = UDim2.fromOffset(0, 76),
		Font = Enum.Font.GothamMedium,
		Text = getProfileBio(name),
		TextColor3 = SocialTheme.Text,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = card,
	})

	if isOwnProfile then
		local edit = makeSocialButton(card, "EDIT BIO", UDim2.fromOffset(92, 30), false, true)
		edit.AnchorPoint = Vector2.new(1, 1)
		edit.Position = UDim2.new(1, 0, 1, 0)
		edit.ZIndex = 15
		edit.MouseButton1Click:Connect(function()
			bioLabel.Visible = false
			edit.Visible = false
			local box = create("TextBox", {
				BackgroundColor3 = SocialTheme.SurfaceLight,
				Size = UDim2.new(1, -106, 0, 48),
				Position = UDim2.fromOffset(0, 76),
				ClearTextOnFocus = false,
				MultiLine = true,
				Text = getProfileBio(name) == "No bio yet." and "" or getProfileBio(name),
				PlaceholderText = "WRITE SOMETHING ABOUT YOUR STYLE...",
				TextColor3 = SocialTheme.Text,
				PlaceholderColor3 = SocialTheme.Muted,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 16,
				Parent = card,
			}) :: TextBox
			addCorner(box, 9)
			addPadding(box, 10, 10, 7, 7)
			local save = makeSocialButton(card, "SAVE", UDim2.fromOffset(74, 30), true, true)
			save.AnchorPoint = Vector2.new(1, 1)
			save.Position = UDim2.new(1, 0, 1, 0)
			save.ZIndex = 16
			save.MouseButton1Click:Connect(function()
				local text = string.sub(box.Text, 1, 160)
				socialBios[name] = text
				if setBioRemote then
					setBioRemote:FireServer(text)
				end
				showToast("PROFILE BIO SAVED", SocialTheme.Purple)
				refreshPhone()
			end)
		end)
	else
		local action = makeSocialButton(card, if socialFollowers[name] then "✓ FOLLOWING" else "+ FOLLOW", UDim2.fromOffset(108, 32), true, true)
		action.AnchorPoint = Vector2.new(1, 0)
		action.Position = UDim2.new(1, 0, 0, 4)
		action.ZIndex = 14
		action.MouseButton1Click:Connect(function()
			if socialFollowers[name] then
				socialFollowers[name] = nil
				showToast("UNFOLLOWED @" .. name, Theme.Muted)
			else
				socialFollowers[name] = 1
				showToast("FOLLOWING @" .. name .. "  ·  +$1 / 30s", Theme.Lime)
			end
			refreshPhone()
		end)
		local trade = makeSocialButton(card, "↔ TRADE", UDim2.fromOffset(108, 32), false, true)
		trade.AnchorPoint = Vector2.new(1, 0)
		trade.Position = UDim2.new(1, 0, 0, 42)
		trade.ZIndex = 14
		trade.MouseButton1Click:Connect(function()
			tradeTarget = name
			if tradeRemote then
				local targetPlayer = getProfilePlayer(name)
				if targetPlayer then
					tradeRemote:FireServer("Request", targetPlayer.UserId)
				end
			end
			refreshPhone()
			showToast("TRADE REQUEST SENT TO @" .. name, SocialTheme.Purple)
		end)
	end
end

local function addTradeItemRow(parent: Instance, item: ClothingItem, selected: boolean, actionText: string, callback: () -> ())
	local row = create("Frame", {
		BackgroundColor3 = if selected then SocialTheme.SurfaceLight else SocialTheme.Surface,
		Size = UDim2.new(1, 0, 0, 56),
		ZIndex = 13,
		Parent = parent,
	}) :: Frame
	addCorner(row, 9)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -92, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Text = item.Name .. "\n$" .. formatCoins(item.Value),
		TextColor3 = SocialTheme.Text,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 14,
		Parent = row,
	})
	local button = makeSocialButton(row, actionText, UDim2.fromOffset(78, 32), selected, true)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -8, 0.5, 0)
	button.ZIndex = 15
	button.MouseButton1Click:Connect(callback)
end

local function addTradePanel()
	local card = socialCard(420)
	addPhoneLabel("TRADE  /  @" .. tostring(tradeTarget or "PLAYER"), false)
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 0),
		Text = "YOUR OFFER",
		TextColor3 = SocialTheme.Purple,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
		Parent = card,
	})
	local list = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 185),
		Position = UDim2.fromOffset(0, 26),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = SocialTheme.Purple,
		ZIndex = 13,
		Parent = card,
	}) :: ScrollingFrame
	create("UIListLayout", { Padding = UDim.new(0, 5), Parent = list })
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			local selected = table.find(tradeMyOffer, item.Id) ~= nil
			addTradeItemRow(list, item, selected, if selected then "REMOVE" else "OFFER", function()
				if selected then
					table.remove(tradeMyOffer, table.find(tradeMyOffer, item.Id) :: number)
				else
					table.insert(tradeMyOffer, item.Id)
				end
				tradeMyReady = false
				if tradeRemote then tradeRemote:FireServer("Offer", tradeMyOffer) end
				refreshPhone()
			end)
		end
	end
	local their = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 225),
		Text = "THEIR OFFER  ·  " .. tostring(#tradeTheirOffer) .. " ITEM(S)",
		TextColor3 = SocialTheme.Purple,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
		Parent = card,
	})
	local theirNames = {}
	for _, id in ipairs(tradeTheirOffer) do
		local item = findInventoryItem(id)
		if item then table.insert(theirNames, item.Name) end
	end
	create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 247),
		Text = if #theirNames > 0 then table.concat(theirNames, "  ·  ") else "WAITING FOR THEIR OFFER...",
		TextColor3 = SocialTheme.Text,
		TextSize = 9,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
		Parent = card,
	})
	local status = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
		Position = UDim2.fromOffset(0, 250),
		Text = "STATUS: " .. tradeStatus .. "\n" .. (if tradeTheirReady then "OTHER PLAYER IS READY" else "WAITING FOR OTHER PLAYER"),
		TextColor3 = if tradeMyReady and tradeTheirReady then SocialTheme.Purple else SocialTheme.Muted,
		TextSize = 10,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 14,
		Parent = card,
	})
	local ready = makeSocialButton(card, if tradeMyReady then "UNREADY" else "READY", UDim2.fromOffset(98, 36), tradeMyReady, true)
	ready.Position = UDim2.fromOffset(0, 304)
	ready.ZIndex = 15
	ready.MouseButton1Click:Connect(function()
		tradeMyReady = not tradeMyReady
		if tradeRemote then tradeRemote:FireServer("Ready", tradeMyReady) end
		refreshPhone()
	end)
	local cancel = makeSocialButton(card, "CANCEL", UDim2.fromOffset(98, 36), false, true)
	cancel.Position = UDim2.fromOffset(108, 304)
	cancel.ZIndex = 15
	cancel.MouseButton1Click:Connect(function()
		if tradeRemote then tradeRemote:FireServer("Cancel") end
		tradeTarget = nil
		tradeSessionActive = false
		tradeMyOffer = {}
		tradeTheirOffer = {}
		tradeMyReady = false
		tradeTheirReady = false
		tradeStatus = "IDLE"
		refreshPhone()
	end)
	if tradeMyReady and tradeTheirReady then
		local accept = makeSocialButton(card, "ACCEPT TRADE", UDim2.new(1, 0, 0, 42), true, true)
		accept.Position = UDim2.fromOffset(0, 352)
		accept.ZIndex = 15
		accept.MouseButton1Click:Connect(function()
			if tradeRemote then tradeRemote:FireServer("Accept") end
			tradeStatus = "CONFIRMING..."
			refreshPhone()
		end)
	end
end

local function refreshSocial()
	clearChildrenExceptLayout(phoneContent)
	for name, button in pairs(phoneTabButtons) do
		button.Visible = true
		local selected = name == currentSocialTab
		button.Text = ({ FYP = "FYP", PROFILE = "PROFILE", CAMERA = "CAMERA" } :: any)[name] or name
		button.BackgroundColor3 = if selected then SocialTheme.Purple else SocialTheme.Surface
		button.TextColor3 = if selected then SocialTheme.Text else SocialTheme.Muted
		button.Font = Enum.Font.GothamBlack
		button.TextSize = 10
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.TextYAlignment = Enum.TextYAlignment.Center
		if selected then
			addStroke(button, SocialTheme.PurpleDark, 1, 0.15)
		else
			addStroke(button, SocialTheme.SurfaceLight, 1, 0)
		end
	end
	phoneTabButtons.LISTINGS.Visible = false
	phoneTabButtons.DELIVERIES.Visible = false
	phoneTabButtons.UPGRADES.Visible = false
	phoneTabs.BackgroundColor3 = SocialTheme.Background
	phoneTabs.BackgroundTransparency = 0

	if currentSocialTab == "FYP" then
		local searchRow = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 42),
			ZIndex = 12,
			Parent = phoneContent,
		}) :: Frame
		local search = create("TextBox", {
			BackgroundColor3 = SocialTheme.Surface,
			PlaceholderText = "SEARCH AN ACCOUNT",
			Text = socialSearchQuery,
			TextColor3 = SocialTheme.Text,
			PlaceholderColor3 = SocialTheme.Muted,
			ClearTextOnFocus = false,
			Size = UDim2.new(1, -92, 0, 42),
			TextSize = 12,
			ZIndex = 12,
			Parent = searchRow,
		}) :: TextBox
		addCorner(search, 11)
		addPadding(search, 12, 12, 0, 0)
		local searchButton = makeSocialButton(searchRow, "SEARCH", UDim2.fromOffset(82, 42), true)
		searchButton.Position = UDim2.new(1, 0, 0, 0)
		searchButton.AnchorPoint = Vector2.new(1, 0)
		searchButton.BackgroundColor3 = SocialTheme.Purple
		searchButton.MouseButton1Click:Connect(function()
			socialSearchQuery = search.Text
			profileName = search.Text
			currentSocialTab = "PROFILE"
			refreshPhone()
		end)
		addPhoneLabel("FOR YOU  ·  PHONE FITS", false)
		if #socialPhotos == 0 then
			addPhoneLabel("NO POSTS YET", true)
			addPhoneLabel("Take a photo with CAMERA to make the first post.", false)
		else
			for _, photo in ipairs(socialPhotos) do
				addSocialPhoto(photo.Owner, photo.Caption, photo.Pose, photo.Likes, photo.CaptureContent, photo.PhotoId)
			end
		end
	elseif currentSocialTab == "PROFILE" then
		local profile = profileName
		if profile == "" then profile = player.Name end
		local isOwn = profile == player.Name
		local targetPlayer = getProfilePlayer(profile)
		if not isOwn and not targetPlayer then
			addPhoneLabel("PROFILE NOT FOUND", true)
			local back = makeSocialButton(phoneContent, "BACK TO FYP", UDim2.new(1, 0, 0, 42), true)
			back.ZIndex = 14
			back.MouseButton1Click:Connect(function()
				currentSocialTab = "FYP"
				refreshPhone()
			end)
			return
		end

		local back = makeSocialButton(phoneContent, "‹  BACK TO FYP", UDim2.new(1, 0, 0, 36), false)
		back.BackgroundColor3 = SocialTheme.SurfaceLight
		back.TextColor3 = SocialTheme.Muted
		back.ZIndex = 14
		back.MouseButton1Click:Connect(function()
			currentSocialTab = "FYP"
			tradeTarget = nil
			refreshPhone()
		end)
		addPhoneLabel("PROFILE  /  @" .. profile, false)
		addSocialProfile(profile, isOwn)

		if tradeIncomingFrom == profile and not tradeSessionActive then
			local requestCard = socialCard(92)
			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -170, 1, 0),
				Text = "TRADE REQUEST\n@" .. profile .. " wants to trade with you.",
				TextColor3 = SocialTheme.Text,
				TextSize = 10,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 14,
				Parent = requestCard,
			})
			local accept = makeSocialButton(requestCard, "ACCEPT", UDim2.fromOffset(76, 32), true)
			accept.AnchorPoint = Vector2.new(1, 0.5)
			accept.Position = UDim2.new(1, -82, 0.5, 0)
			accept.ZIndex = 15
			accept.MouseButton1Click:Connect(function()
				tradeSessionActive = true
				tradeTarget = profile
				tradeIncomingFrom = nil
				tradeStatus = "TRADE OPEN"
				if tradeRemote then tradeRemote:FireServer("Respond", true) end
				refreshPhone()
			end)
			local decline = makeSocialButton(requestCard, "DECLINE", UDim2.fromOffset(76, 32), false)
			decline.AnchorPoint = Vector2.new(1, 0.5)
			decline.Position = UDim2.new(1, 0, 0.5, 0)
			decline.ZIndex = 15
			decline.MouseButton1Click:Connect(function()
				if tradeRemote then tradeRemote:FireServer("Respond", false) end
				tradeIncomingFrom = nil
				refreshPhone()
			end)
		end

		local profilePhotos = 0
		for _, photo in ipairs(socialPhotos) do
			if photo.Owner == profile then
				profilePhotos += 1
				addSocialPhoto(photo.Owner, photo.Caption, photo.Pose, photo.Likes, photo.CaptureContent, photo.PhotoId)
			end
		end
		if profilePhotos == 0 then
			addPhoneLabel("NO PHOTOS YET", true)
		end

		if tradeSessionActive and tradeTarget == profile then
			addTradePanel()
		end
	elseif currentSocialTab == "CAMERA" then
		-- Camera is a fixed capture mode: do not animate/slide the phone UI while shooting.
		phoneDock.Visible = false
		phoneWindow.Visible = false
		phoneWindow.Active = false
		setCameraActive(true)
	end
end

refreshPhone = function()
	if currentPhoneApp == "HOME" then
		setCameraActive(false)
		phoneWindow.Visible = true
		backdrop.Visible = true
		clearChildrenExceptLayout(phoneContent)
		for _, button in pairs(phoneTabButtons) do
			button.Visible = false
		end
		phoneTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		phoneTopBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		phoneScreen.BackgroundColor3 = SocialTheme.Background
		phoneTitle.Text = "PHONE"
		phoneSubtitle.Text = "YOUR APPS"

		local homeHeader = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			Position = UDim2.fromOffset(0, 4),
			Text = "9:41",
			TextColor3 = SocialTheme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 13,
			Parent = phoneContent,
		})
		local welcome = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 50),
			Position = UDim2.fromOffset(0, 34),
			Text = "WHAT ARE YOU\nOPENING TODAY?",
			TextColor3 = SocialTheme.Text,
			TextSize = 19,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 13,
			Parent = phoneContent,
		})
		local apps = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 270),
			Position = UDim2.fromOffset(0, 102),
			ZIndex = 13,
			Parent = phoneContent,
		}) :: Frame
		local appGrid = create("UIGridLayout", {
			CellSize = UDim2.fromOffset(128, 128),
			CellPadding = UDim2.fromOffset(12, 12),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Parent = apps,
		})
		local function addHomeApp(icon: string, title: string, subtitle: string, accent: Color3, appName: string)
			local button = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = accent,
			Size = UDim2.fromOffset(128, 128),
			Text = "",
			ZIndex = 14,
			Parent = apps,
			}) :: TextButton
			addCorner(button, 25)
			addStroke(button, Color3.fromRGB(255, 255, 255), 1, 0.65)
			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 58),
				Position = UDim2.fromOffset(0, 16),
				Text = icon,
				TextColor3 = SocialTheme.Text,
				TextSize = 38,
				ZIndex = 15,
				Parent = button,
			})
			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.fromOffset(6, 72),
				Text = title,
				TextColor3 = SocialTheme.Text,
				TextSize = 14,
				ZIndex = 15,
				Parent = button,
			})
			create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -12, 0, 18),
				Position = UDim2.fromOffset(6, 96),
				Text = subtitle,
				TextColor3 = Color3.fromRGB(240, 226, 250),
				TextSize = 8,
				ZIndex = 15,
				Parent = button,
			})
			button.MouseButton1Click:Connect(function()
				currentPhoneApp = appName
				if appName == "SOCIAL" then
					currentSocialTab = "FYP"
				else
					currentPhoneTab = "LISTINGS"
				end
				refreshPhone()
			end)
		end
		addHomeApp("◎", "RO-GRAM", "PHOTO / SOCIAL", SocialTheme.Purple, "SOCIAL")
		addHomeApp("◆", "FLIPTAG", "CLOTHES / MARKET", Theme.Lime, "FLIPTAG")
		return
	end

	if currentPhoneApp == "SOCIAL" then
		if currentSocialTab == "CAMERA" then
			phoneWindow.Visible = false
		else
			setCameraActive(false)
			phoneWindow.Visible = true
			backdrop.Visible = true
		end
		refreshSocial()
		return
	end
	setCameraActive(false)
	phoneWindow.Visible = true
	clearChildrenExceptLayout(phoneContent)
	for tab, button in pairs(phoneTabButtons) do
		button.Visible = tab ~= "FYP" and tab ~= "PROFILE" and tab ~= "CAMERA"
		button.Text = tab
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
		addPhoneLabel("UPGRADE ANYTIME · EACH UPGRADE MAKES THE NEXT ONE MORE EXPENSIVE", true)

		local upgradeMultiplier = 1.5
		local upgrades = {
			{ Id = "QUICKSHIP", Name = "QUICKSHIP", Description = "Shorter delivery times", BaseCost = 700 },
			{ Id = "SAFEBOX", Name = "SAFEBOX", Description = "Lower lost-package chance", BaseCost = 900 },
			{ Id = "BOOSTER", Name = "BOOSTER", Description = "Better buyer reach", BaseCost = 1100 },
		}

		for _, upgrade in ipairs(upgrades) do
			local level = appUpgradeLevels[upgrade.Id] or 0
			local cost = math.floor(upgrade.BaseCost * (upgradeMultiplier ^ level))

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
				Text = upgrade.Name .. "  LV. " .. tostring(level),
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

			local buy = makeButton(row, "$" .. formatCoins(cost), UDim2.fromOffset(91, 35), coins >= cost)
			buy.AnchorPoint = Vector2.new(1, 0.5)
			buy.Position = UDim2.new(1, -12, 0.5, 0)
			buy.ZIndex = 14

			buy.MouseButton1Click:Connect(function()
				if coins < cost then
					showToast("NOT ENOUGH CASH", Theme.Danger)
					return
				end

				coins -= cost
				appUpgradeLevels[upgrade.Id] = level + 1
				cashLabel.Text = "$" .. formatCoins(coins)
				showToast(upgrade.Name .. " UPGRADED TO LV. " .. tostring(level + 1), Theme.Lime)
				refreshPhone()
			end)
		end
	end
end

for tab, button in pairs(phoneTabButtons) do
	button.MouseButton1Click:Connect(function()
		if currentPhoneApp == "SOCIAL" then
			if tab == "FYP" or tab == "PROFILE" or tab == "CAMERA" then
				currentSocialTab = tab
			end
		else
			currentPhoneTab = tab
		end
		refreshPhone()
	end)
end

-- Home-screen app launcher is the main way to switch between FLIPTAG and ro-gram.
local function openPhoneHome()
	setCameraActive(false)
	currentPhoneApp = "HOME"
	currentSocialTab = "FYP"
	currentPhoneTab = "LISTINGS"
	openWindow(phoneWindow)
	refreshPhone()
end

phoneDockButton.MouseButton1Click:Connect(openPhoneHome)

listButton.MouseButton1Click:Connect(function()
	if selectedItem.State ~= "Owned" then
		showToast("THIS ITEM CANNOT BE LISTED", Theme.Danger)
		return
	end
	openWindow(phoneWindow)
	currentPhoneApp = "FLIPTAG"
	currentPhoneTab = "LISTINGS"
	refreshPhone()
	showToast("POST " .. selectedItem.Name .. " FROM YOUR PHONE", Theme.Lime)
end)

inventoryButton.MouseButton1Click:Connect(function()
	openWindow(inventoryWindow)
	refreshInventory()
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
		openPhoneHome()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		closeWindows()
	end
end)

task.spawn(function()
	while screenGui.Parent do
		task.wait(0.05)
		if cameraActive then
			updateCameraView()
		end
	end
end)

task.spawn(function()
	while screenGui.Parent do
		task.wait(30)
		local followerCount = 0
		for _ in pairs(socialFollowers) do
			followerCount += 1
		end
		if followerCount > 0 then
			local passiveIncome = followerCount
			coins += passiveIncome
			cashLabel.Text = "$" .. formatCoins(coins)
			showToast("SOCIAL INCOME: +$" .. formatCoins(passiveIncome), Theme.Lime)
		end
	end
end)

task.spawn(function()
	while screenGui.Parent do
		task.wait(1)
		local paidOut = false
		for index = #shipments, 1, -1 do
			local shipment = shipments[index]
			if os.clock() >= shipment.FinishAt then
				-- Packages can be lost during delivery. The SAFEBOX upgrade lowers the chance.
				local safeBoxLevel = appUpgradeLevels.SAFEBOX or 0
				local lostChance = math.max(0.02, 0.10 - (safeBoxLevel * 0.02))
				local wasLost = math.random() < lostChance

				if wasLost then
					shipment.Item.State = "Lost"
					table.remove(shipments, index)
					paidOut = true
						showToast("PACKAGE LOST: NO PAYMENT", Theme.Lime)
				else
					local soldItem = shipment.Item
					soldItem.State = "Sold"
					coins += soldItem.Value
					removeFromWardrobe(soldItem)
					table.remove(shipments, index)
					paidOut = true
					showToast("SOLD: +$" .. formatCoins(soldItem.Value), Theme.Lime)
				end
			end
		end
		if paidOut then
			refreshInventory()
			refreshFit()
			if phoneWindow.Visible and currentPhoneTab == "DELIVERIES" then
				refreshPhone()
			end
		end
		if phoneWindow.Visible and currentPhoneTab == "DELIVERIES" then
			refreshPhone()
		end
	end
end)

-- RO-GRAM / TRADE SERVER SYNC ---------------------------------------------
local function findInventoryItem(itemId: string): ClothingItem?
	for _, item in ipairs(inventory) do
		if item.Id == itemId then
			return item
		end
	end
	return nil
end

local function registerOwnedInventory()
	if not tradeRemote or not roGramRemotes then
		return
	end
	local register = roGramRemotes:FindFirstChild("RegisterInventory")
	if not register or not register:IsA("RemoteEvent") then
		return
	end
	local ids: { string } = {}
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			table.insert(ids, item.Id)
		end
	end
	register:FireServer(ids)
end

local function resetTradeState()
	tradeSessionActive = false
	tradeTarget = nil
	tradeIncomingFrom = nil
	tradeMyOffer = {}
	tradeTheirOffer = {}
	tradeMyReady = false
	tradeTheirReady = false
	tradeStatus = "IDLE"
end

task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("RoGramRemotes", 10)
	if not folder or not folder:IsA("Folder") then
		return
	end
	roGramRemotes = folder
	local bioRemote = folder:WaitForChild("SetBio", 5)
	local tRemote = folder:WaitForChild("Trade", 5)
	local pRemote = folder:WaitForChild("PhotoPosted", 5)
	if bioRemote and bioRemote:IsA("RemoteEvent") then setBioRemote = bioRemote end
	if tRemote and tRemote:IsA("RemoteEvent") then tradeRemote = tRemote end
	if pRemote and pRemote:IsA("RemoteEvent") then photoRemote = pRemote end

	local register = folder:FindFirstChild("RegisterInventory")
	if register and register:IsA("RemoteEvent") then
		registerOwnedInventory()
	end

	if setBioRemote then
		-- The profile player attributes are the source of truth for currently loaded players.
		for _, other in ipairs(Players:GetPlayers()) do
			local bio = other:GetAttribute("SocialBio")
			if type(bio) == "string" then
				socialBios[other.Name] = bio
			end
		end
	end

	if photoRemote then
		photoRemote.OnClientEvent:Connect(function(action, ownerName, payload)
			if action == "Posted" and type(ownerName) == "string" and type(payload) == "table" then
				if ownerName ~= player.Name then
					table.insert(socialPhotos, 1, {
						Owner = ownerName,
						Caption = type(payload.Caption) == "string" and payload.Caption or "",
						Pose = type(payload.Pose) == "string" and payload.Pose or "FRONT",
						Likes = type(payload.Likes) == "number" and payload.Likes or 0,
						CaptureContent = type(payload.CaptureContent) == "string" and payload.CaptureContent or nil,
						PhotoId = type(payload.PhotoId) == "string" and payload.PhotoId or nil,
					})
				end
				if phoneWindow.Visible and currentPhoneApp == "SOCIAL" then refreshPhone() end
			elseif action == "Deleted" and type(ownerName) == "string" and type(payload) == "string" then
				for index = #socialPhotos, 1, -1 do
					if socialPhotos[index].Owner == ownerName and socialPhotos[index].PhotoId == payload then
						table.remove(socialPhotos, index)
					end
				end
				if phoneWindow.Visible and currentPhoneApp == "SOCIAL" then refreshPhone() end
			end
		end)
	end

	if tradeRemote then
		tradeRemote.OnClientEvent:Connect(function(action, data, extra)
			if action == "RequestSent" then
				showToast("TRADE REQUEST SENT TO @" .. tostring(data), SocialTheme.Purple)
			elseif action == "IncomingRequest" then
				tradeIncomingFrom = tostring(data)
				profileName = tradeIncomingFrom
				currentSocialTab = "PROFILE"
				showToast("TRADE REQUEST FROM @" .. tradeIncomingFrom, SocialTheme.Purple)
				if phoneWindow.Visible and currentPhoneApp == "SOCIAL" then refreshPhone() end
			elseif action == "Declined" then
				showToast("TRADE DECLINED BY @" .. tostring(data), Theme.Danger)
				resetTradeState()
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "Open" then
				local info = if type(data) == "table" then data else {}
				local otherName = if info.A == player.Name then info.B else info.A
				tradeTarget = tostring(otherName)
				profileName = tradeTarget
				tradeSessionActive = true
				tradeIncomingFrom = nil
				tradeMyOffer = {}
				tradeTheirOffer = {}
				tradeMyReady = false
				tradeTheirReady = false
				tradeStatus = "TRADE OPEN"
				currentSocialTab = "PROFILE"
				showToast("TRADE OPEN WITH @" .. tradeTarget, SocialTheme.Purple)
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "Offer" then
				if type(data) == "table" then
					tradeTheirOffer = {}
					for _, id in ipairs(data) do if type(id) == "string" then table.insert(tradeTheirOffer, id) end end
				end
				tradeTheirReady = false
				tradeStatus = "OFFER UPDATED"
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "OfferConfirmed" then
				tradeMyOffer = {}
				if type(data) == "table" then
					for _, id in ipairs(data) do if type(id) == "string" then table.insert(tradeMyOffer, id) end end
				end
				tradeMyReady = false
				tradeStatus = "OFFER SENT"
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "Ready" then
				tradeTheirReady = data == true
				tradeStatus = if tradeTheirReady then "OTHER PLAYER READY" else "OTHER PLAYER NOT READY"
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "ReadyConfirmed" then
				tradeMyReady = data == true
				tradeStatus = if tradeMyReady then "YOU ARE READY" else "EDITING OFFER"
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "Completed" then
				local info = if type(data) == "table" then data else {}
				local receivedMap = if type(info.Received) == "table" then info.Received else {}
				local givenMap = if type(info.Given) == "table" then info.Given else {}
				local received = receivedMap[player.UserId]
				local given = givenMap[player.UserId]
				if type(given) == "table" then
					for _, id in ipairs(given) do
						if type(id) == "string" then
							local item = findInventoryItem(id)
							if item then
								item.State = "Traded"
								if equipped[item.Category] == item then equipped[item.Category] = nil end
							end
						end
					end
				end
				if type(received) == "table" then
					for _, id in ipairs(received) do
						if type(id) == "string" then
							local item = findInventoryItem(id)
							if item then item.State = "Owned" end
						end
					end
				end
				showToast("TRADE COMPLETE", SocialTheme.Purple)
				resetTradeState()
				registerOwnedInventory()
				refreshInventory()
				refreshFit()
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "Cancelled" then
				showToast("TRADE CANCELLED", Theme.Muted)
				resetTradeState()
				if phoneWindow.Visible then refreshPhone() end
			elseif action == "Error" then
				showToast(tostring(data), Theme.Danger)
			elseif action == "BioUpdated" then
				-- Reserved for future server-side live profile updates.
			end
		end)
	end
end)

-- The server owns the donation-bin interaction. This client hook only displays
-- the received item in the prototype wardrobe; persistence moves server-side next.
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("ThriftRemotes")
	local remote = remotes:WaitForChild("ClothingFound")
	local rackRemote = remotes:WaitForChild("RoundRackRoll")

	if not remote:IsA("RemoteEvent") or not rackRemote:IsA("RemoteEvent") then
		return
	end

	-- Okragly wieszak: serwer najpierw proponuje wylosowany item za $100.
	-- Poniewaz obecny prototyp przechowuje coins lokalnie, platnosc jest
	-- odejmowana tutaj, a dopiero potem serwer zatwierdza wygrana.
	rackRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" or payload.Type ~= "Offer" then
			return
		end

		local price = tonumber(payload.Price) or 100
		if coins < price then
			showToast("NOT ENOUGH CASH - NEED $" .. formatCoins(price), Theme.Danger)
			rackRemote:FireServer("Cancel")
			return
		end

		coins -= price
		cashLabel.Text = "$" .. formatCoins(coins)
		showToast("ROUND RACK: -$" .. formatCoins(price), Theme.Muted)

		-- Serwer posiada juz konkretny wylosowany item, wiec nie mozna
		-- zmienic wyniku po stronie klienta.
		rackRemote:FireServer("Confirm")
	end)

	remote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.Type ~= "Found" or type(payload.Item) ~= "table" then
			return
		end

		task.spawn(animateClothingRoll, payload.Item)
		registerOwnedInventory()

		if payload.UnlockMessage then
			task.delay(3.8, function()
				showToast(string.upper(tostring(payload.UnlockMessage)), Theme.Lime)
			end)
		end
	end)
end)

refreshInventory()
refreshFit()
currentPhoneApp = "HOME"
refreshPhone()
-- Initial state: the phone UI is prepared but the phone itself is closed.
-- Do not leave the world dimmed or require a click to clear the backdrop.
phoneWindow.Visible = false
phoneWindow.Active = false
phoneDock.Visible = true
backdrop.Visible = false
if cameraOverlay then cameraOverlay.Visible = false end
if cameraCaptureMask then cameraCaptureMask.Visible = false end
if cameraFrameGuide then cameraFrameGuide.Visible = false end
activeWindow = nil
showToast("WELCOME TO THRIFT//RUN", Theme.Lime)
