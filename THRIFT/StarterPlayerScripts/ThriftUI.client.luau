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
	Background = Color3.fromRGB(220, 244, 255),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceLight = Color3.fromRGB(191, 231, 250),
	Paper = Color3.fromRGB(15, 48, 78),
	Muted = Color3.fromRGB(82, 119, 145),
	Lime = Color3.fromRGB(61, 169, 242),
	LimeDark = Color3.fromRGB(22, 108, 184),
	Danger = Color3.fromRGB(255, 91, 91),
	Common = Color3.fromRGB(117, 158, 184),
	Uncommon = Color3.fromRGB(52, 194, 116),
	Rare = Color3.fromRGB(61, 157, 242),
	Grail = Color3.fromRGB(181, 82, 228),
	Limited = Color3.fromRGB(255, 171, 48),
	Legendary = Color3.fromRGB(255, 193, 36),
	Mythic = Color3.fromRGB(255, 91, 91),
	Secret = Color3.fromRGB(239, 92, 255),
	White = Color3.fromRGB(255, 255, 255),
}

local SocialTheme = {
	Background = Color3.fromRGB(226, 247, 255),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceLight = Color3.fromRGB(196, 235, 252),
	Purple = Color3.fromRGB(45, 177, 239),
	PurpleDark = Color3.fromRGB(17, 125, 190),
	Pink = Color3.fromRGB(255, 105, 125),
	Text = Color3.fromRGB(15, 48, 78),
	Muted = Color3.fromRGB(82, 128, 153),
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
	Image: string?,
	Limited: string?,
	State: string,
}

type Shipment = {
	Item: ClothingItem,
	FinishAt: number,
}

local inventory: { ClothingItem } = {
	{ Id = "heavy_blank_tee", Name = "Heavy Blank Tee", Brand = "Basefile", Category = "Top", Style = "Street", Rarity = "Common", Value = 70, Visual = "TEE", State = "Owned" },
	{ Id = "rack_blue_tshirt", Name = "Blue T-Shirt", Brand = "Blue Hour", Category = "Top", Style = "Street", Rarity = "Uncommon", Value = 180, Visual = "BLUE T-SHIRT", Image = "rbxassetid://87365206745199", State = "Owned" },
	{ Id = "dead_signal_zip", Name = "Dead Signal Zip Hoodie", Brand = "Last Call", Category = "Top", Style = "Y2K", Rarity = "Uncommon", Value = 420, Visual = "ZIP HOODIE", State = "Owned" },
	{ Id = "transit_leather", Name = "Transit Leather Jacket", Brand = "Morrow", Category = "Top", Style = "Archive", Rarity = "Grail", Value = 8500, Visual = "LEATHER JACKET", State = "Owned" },
	{ Id = "washed_straight", Name = "Washed Straight Denim", Brand = "Rivet", Category = "Bottom", Style = "Vintage", Rarity = "Common", Value = 110, Visual = "STRAIGHT DENIM", State = "Owned" },
	{ Id = "widefade_denim", Name = "Widefade Denim", Brand = "Nox Denim", Category = "Bottom", Style = "Archive", Rarity = "Uncommon", Value = 360, Visual = "WIDE DENIM", State = "Owned" },
	{ Id = "canvas_90", Name = "Canvas 90", Brand = "Nice", Category = "Shoes", Style = "Skate", Rarity = "Common", Value = 130, Visual = "LOW-TOP", State = "Owned" },
	{ Id = "fourline_runner", Name = "Fourline Runner", Brand = "Abibas", Category = "Shoes", Style = "Sport", Rarity = "Uncommon", Value = 500, Visual = "RUNNER", State = "Owned" },
	{ Id = "obsidian_stack", Name = "Obsidian Stack Boots", Brand = "Bick Bowens", Category = "Shoes", Style = "Archive", Rarity = "Grail", Value = 11000, Visual = "STACK BOOT", State = "Owned" },
	{ Id = "faded_cap", Name = "Faded Logo Cap", Brand = "Kabel 04", Category = "Head", Style = "Street", Rarity = "Common", Value = 90, Visual = "CAP", State = "Owned" },
	{ Id = "shield_visor", Name = "Shield Visor", Brand = "Suture", Category = "Head", Style = "Y2K", Rarity = "Rare", Value = 1800, Visual = "VISOR", State = "Owned" },
	{ Id = "chrome_link", Name = "Chrome Link Belt", Brand = "Chrome Souls", Category = "Accessory", Style = "Archive", Rarity = "Rare", Value = 2400, Visual = "CHAIN BELT", State = "Owned" },
	{ Id = "moonwire", Name = "Moonwire Glasses", Brand = "Lumen 03", Category = "Accessory", Style = "Y2K", Rarity = "Limited", Value = 24000, Visual = "WIRE GLASSES", Limited = "#042 / 500", State = "Owned" },
	{ Id = "test_secret_top", Name = "Secret Archive Tee", Brand = "Hidden Label", Category = "Top", Style = "Secret", Rarity = "Secret", Value = 100000, Visual = "SECRET TEE", State = "Owned" },
	{ Id = "test_secret_bottom", Name = "Secret Wide Denim", Brand = "Hidden Label", Category = "Bottom", Style = "Secret", Rarity = "Secret", Value = 110000, Visual = "SECRET DENIM", State = "Owned" },
	{ Id = "test_secret_shoes", Name = "Secret Archive Boots", Brand = "Hidden Label", Category = "Shoes", Style = "Secret", Rarity = "Secret", Value = 125000, Visual = "SECRET BOOTS", State = "Owned" },
	{ Id = "test_secret_head", Name = "Secret Collector Cap", Brand = "Hidden Label", Category = "Head", Style = "Secret", Rarity = "Secret", Value = 90000, Visual = "SECRET CAP", State = "Owned" },
	{ Id = "test_secret_accessory", Name = "Secret Chrome Chain", Brand = "Hidden Label", Category = "Accessory", Style = "Secret", Rarity = "Secret", Value = 150000, Visual = "SECRET CHAIN", State = "Owned" },
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
	Top = inventory[14],
	Bottom = inventory[15],
	Shoes = inventory[16],
	Head = inventory[17],
	Accessory = inventory[18],
}
local shipments: { Shipment } = {}
local currentPhoneTab = "LISTINGS"

-- Namespace table for all helper/UI-building functions below.
-- (Grouping them here instead of 50+ separate top-level locals is what keeps
-- this script under Luau's 200-local-register-per-chunk limit.)
local Fn = {}

-- Paczki z FinishAt = 0 czekają na odłożenie w paczkomacie (dostawa jeszcze się nie zaczęła).
function Fn.countPendingShipments(): number
	local pending = 0
	for _, shipment in ipairs(shipments) do
		if shipment.FinishAt == 0 then
			pending += 1
		end
	end
	return pending
end
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
type RollState = {
	Active: boolean,
	Auto: boolean,
	Source: string?,
	Price: number,
	Remote: RemoteEvent?,
	LuckRemote: RemoteEvent?,
	LuckLabel: TextLabel?,
}
local rollState: RollState = {
	Active = false,
	Auto = false,
	Source = nil,
	Price = 0,
	Remote = nil,
	LuckRemote = nil,
	LuckLabel = nil,
}
local socialPaletteActive = false
local toastVersion = 0
local toastQueue: { { message: string, accent: Color3? } } = {}
local toastShowing = false

local pendingPhotoContent: string? = nil
local pendingPhotoId: string? = nil
local pendingPhotoPose = "FRONT"
local postPreviewModal: Frame? = nil
local postPreviewImage: ImageLabel? = nil
local postPreviewCaption: TextBox? = nil

function Fn.create(className: string, properties: { [string]: any }?): Instance
	local instance = Instance.new(className)
	if properties then
		for property, value in pairs(properties) do
			(instance :: any)[property] = value
		end
	end
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		instance.FontFace = InterfaceFont
		instance.TextStrokeTransparency = 1
		if properties and type(properties.TextSize) == "number" then
			instance.TextSize = properties.TextSize + FontSizeBoost
		end
	end
	return instance
end

function Fn.addCorner(parent: Instance, radius: number)
	Fn.create("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	})
end

function Fn.addStroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	Fn.create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Fn.addPadding(parent: Instance, left: number, right: number, top: number, bottom: number)
	Fn.create("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom),
		Parent = parent,
	})
end

function Fn.formatCoins(amount: number): string
	local reversed = tostring(math.floor(amount)):reverse()
	local grouped = reversed:gsub("(%d%d%d)", "%1,")
	local result = grouped:reverse():gsub("^,", "")
	return result
end

function Fn.rarityColor(item: ClothingItem): Color3
	if item.Limited then
		return Theme.Limited
	end
	return (Theme :: any)[item.Rarity] or Theme.Common
end

function Fn.rarityLuck(rarity: string): number
	if rarity == "Uncommon" then return 0.1 end
	if rarity == "Rare" then return 0.25 end
	if rarity == "Epic" then return 0.5 end
	if rarity == "Grail" then return 1 end
	if rarity == "Limited" then return 1.5 end
	if rarity == "Legendary" then return 2 end
	if rarity == "Mythic" then return 3 end
	if rarity == "Secret" then return 5 end
	return 0
end

function Fn.ownedCount(): number
	local count = 0
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			count += 1
		end
	end
	return count
end

local screenGui = Fn.create("ScreenGui", {
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

local hud = Fn.create("Frame", {
	Name = "HUD",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = screenGui,
}) :: Frame

local titleBlock = Fn.create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.fromOffset(218, 74),
	Position = UDim2.fromOffset(22, 22),
	Parent = hud,
}) :: Frame
titleBlock.Visible = false
Fn.addCorner(titleBlock, 14)
Fn.addStroke(titleBlock, Theme.SurfaceLight, 1)
Fn.addPadding(titleBlock, 15, 15, 11, 10)

Fn.create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 24),
	Font = Enum.Font.GothamBlack,
	Text = "THRIFT//RUN",
	TextColor3 = Theme.White,
	TextSize = 23,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBlock,
})

local cashChip = Fn.create("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.fromOffset(152, 58),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 22),
	Parent = hud,
}) :: Frame
Fn.addCorner(cashChip, 16)
Fn.addStroke(cashChip, Theme.SurfaceLight, 1)
Fn.create("TextLabel", {
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
local cashLabel = Fn.create("TextLabel", {
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
rollState.LuckLabel = Fn.create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(190, 24),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 82),
	Font = Enum.Font.GothamBlack,
	Text = "DROP LUCK  +0.0%  1.00x",
	TextColor3 = Theme.Uncommon,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 12,
	Parent = hud,
}) :: TextLabel
Fn.create("TextLabel", {
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

local hudButtons = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(284, 58),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -184, 0, 22),
	Parent = hud,
}) :: Frame
Fn.create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	Parent = hudButtons,
})

function Fn.makeButton(parent: Instance, text: string, size: UDim2, accent: boolean?, fixedColor: boolean?): TextButton
	local accentColor = if currentPhoneApp == "SOCIAL" then SocialTheme.Purple else Theme.Lime
	local accentTextColor = if currentPhoneApp == "SOCIAL" then SocialTheme.Text else Theme.Background
	local button = Fn.create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if accent then accentColor else Theme.Surface,
		Size = size,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = if accent then accentTextColor else Theme.Paper,
		TextSize = 14,
		Parent = parent,
	}) :: TextButton
	Fn.addCorner(button, 12)
	Fn.addStroke(button, Theme.Paper, 3)

	if not fixedColor then
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
	end
	return button
end

local inventoryButton = Fn.makeButton(hudButtons, "WARDROBE", UDim2.fromOffset(138, 58), false)
local fitButton = Fn.makeButton(hudButtons, "FIT BUILDER", UDim2.fromOffset(138, 58), true)

local phoneDock = Fn.create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.fromOffset(176, 48),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	ZIndex = 4,
	Parent = hud,
}) :: Frame
Fn.addCorner(phoneDock, 18)
Fn.addStroke(phoneDock, Theme.White, 1, 0.25)
local phoneDockButton = Fn.makeButton(phoneDock, "PHONE", UDim2.fromScale(1, 1), true, true)
phoneDockButton.BackgroundColor3 = Theme.LimeDark
phoneDockButton.TextColor3 = Theme.White
phoneDockButton.ZIndex = 5

local backdrop = Fn.create("TextButton", {
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

local toast = Fn.create("Frame", {
	BackgroundColor3 = Theme.Paper,
	Size = UDim2.fromOffset(360, 52),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -70),
	ZIndex = 30,
	Parent = screenGui,
}) :: Frame
Fn.addCorner(toast, 13)
local toastLabel = Fn.create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	Text = "",
	TextColor3 = Theme.Background,
	TextSize = 13,
	ZIndex = 31,
	Parent = toast,
}) :: TextLabel

function Fn.processToastQueue()
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

function Fn.showToast(message: string, accent: Color3?)
	table.insert(toastQueue, {
		message = message,
		accent = accent,
	})
	Fn.processToastQueue()
end

function Fn.animateClothingRoll(rawItem: { [string]: any })
	--==================================================
	-- HORIZONTAL CLOTHING ROULETTE
	--==================================================

	local rollWindow = Fn.create("Frame", {
		Name = "ClothingRoll",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(680, 185),
		ZIndex = 40,
		Parent = screenGui,
	}) :: Frame
	Fn.addCorner(rollWindow, 18)
	Fn.addStroke(rollWindow, Theme.Lime, 4)

	if rollState.Source then
		local autoRollButton = Fn.create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = if rollState.Auto then Theme.Danger else Theme.Lime,
			Size = UDim2.fromOffset(180, 38),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 14),
			Font = Enum.Font.GothamBold,
			Text = if rollState.Auto then "STOP" else "AUTOROLL",
			TextColor3 = Theme.Background,
			TextSize = 13,
			ZIndex = 70,
			Parent = rollWindow,
		}) :: TextButton
		Fn.addCorner(autoRollButton, 12)
		Fn.addStroke(autoRollButton, Theme.Paper, 2)
		autoRollButton.MouseButton1Click:Connect(function()
			rollState.Auto = not rollState.Auto
			autoRollButton.Text = if rollState.Auto then "STOP" else "AUTOROLL"
			autoRollButton.BackgroundColor3 = if rollState.Auto then Theme.Danger else Theme.Lime
		end)
	end

	-- Inner viewport, matching the reference style.
	local viewport = Fn.create("Frame", {
		Name = "RollViewport",
		BackgroundColor3 = Color3.fromRGB(48, 48, 48),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 1, -20),
		ZIndex = 41,
		Parent = rollWindow,
	}) :: Frame
	Fn.addCorner(viewport, 13)

	--==================================================
	-- CENTER MARKER
	--==================================================

	local marker = Fn.create("Frame", {
		Name = "CenterMarker",
		BackgroundColor3 = Theme.Lime,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(4, 165),
		ZIndex = 60,
		Parent = viewport,
	}) :: Frame
	Fn.addCorner(marker, 3)

	local markerTop = Fn.create("Frame", {
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
		Image = if rawItem.Image ~= nil then tostring(rawItem.Image) else nil,
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

	local rollList = Fn.create("Frame", {
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
		local card = Fn.create("Frame", {
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
		Fn.addCorner(card, 9)

		local rarityStripe = Fn.create("Frame", {
			BackgroundColor3 = Fn.rarityColor(item),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 5),
			ZIndex = 47,
			Parent = card,
		}) :: Frame
		Fn.addCorner(rarityStripe, 6)

		local imageBox = Fn.create("Frame", {
			BackgroundColor3 = Color3.fromRGB(225, 225, 225),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(88, 66),
			ZIndex = 47,
			Parent = card,
		}) :: Frame
		Fn.addCorner(imageBox, 5)

		if item.Image and string.match(item.Image, "^rbxassetid://%d+$") then
			Fn.create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = item.Image,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 48,
				Parent = imageBox,
			})
		else
			Fn.create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Font = Enum.Font.GothamBlack,
				Text = string.upper(tostring(item.Visual or "ITEM")),
				TextColor3 = Fn.rarityColor(item),
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 48,
				Parent = imageBox,
			})
		end

		Fn.create("TextLabel", {
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

		local valueLabel = Fn.create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, 14),
			Position = UDim2.fromOffset(5, 108),
			Font = Enum.Font.GothamBold,
			Text = "$" .. Fn.formatCoins(item.Value),
			TextColor3 = Fn.rarityColor(item),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 48,
			Parent = card,
		}) :: TextLabel

		local rarityDot = Fn.create("Frame", {
			BackgroundColor3 = Fn.rarityColor(item),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 10),
			Size = UDim2.fromOffset(7, 7),
			ZIndex = 49,
			Parent = card,
		}) :: Frame
		Fn.addCorner(rarityDot, 8)

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
		Fn.addStroke(winnerCard, Theme.Lime, 3)

		local scale = Fn.create("UIScale", {
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
	rollState.Active = false
	if rollState.Auto and rollState.Source and rollState.Remote then
		if coins < rollState.Price then
			rollState.Auto = false
			rollState.Source = nil
			Fn.showToast("AUTOROLL STOPPED - NOT ENOUGH CASH", Theme.Danger)
		else
			local source = rollState.Source
			task.delay(0.35, function()
				if rollState.Auto and not rollState.Active and rollState.Remote then
					rollState.Remote:FireServer("AutoRoll", source)
				end
			end)
		end
	else
		rollState.Source = nil
	end

	--==================================================
	-- ADD WON ITEM TO INVENTORY
	--==================================================

	table.insert(inventory, winner)
	selectedItem = winner
	currentCategory = winner.Category
	Fn.refreshInventory()
	Fn.refreshFit()
	Fn.showToast("FOUND: " .. string.upper(winner.Name), Theme.Lime)
end

-- Product cards use simple garment silhouettes for now. These are intentionally
-- made from UI shapes so every item can be recognised before 3D clothing models exist.
function Fn.createGarmentPreview(parent: Instance, item: ClothingItem, position: UDim2, size: UDim2, zIndex: number)
	local preview = Fn.create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		ZIndex = zIndex,
		Parent = parent,
	}) :: Frame
	Fn.addCorner(preview, 11)
	if item.Image and string.match(item.Image, "^rbxassetid://%d+$") then
		Fn.create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = item.Image,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = zIndex + 1,
			Parent = preview,
		})
		return
	end

	local tint = Fn.rarityColor(item)
	local function part(partSize: UDim2, partPosition: UDim2, rotation: number?)
		local visualPart = Fn.create("Frame", {
			BackgroundColor3 = tint,
			BorderSizePixel = 0,
			Size = partSize,
			Position = partPosition,
			Rotation = rotation or 0,
			ZIndex = zIndex + 1,
			Parent = preview,
		}) :: Frame
		Fn.addCorner(visualPart, 5)
		return visualPart
	end

	if item.Category == "Top" then
		part(UDim2.fromScale(0.34, 0.5), UDim2.fromScale(0.33, 0.25))
		part(UDim2.fromScale(0.2, 0.25), UDim2.fromScale(0.13, 0.34), -12)
		part(UDim2.fromScale(0.2, 0.25), UDim2.fromScale(0.67, 0.34), 12)
		if item.Visual == "ZIP HOODIE" or item.Visual == "LEATHER JACKET" then
			local zip = Fn.create("Frame", {
				BackgroundColor3 = Theme.White,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.018, 0.43),
				Position = UDim2.fromScale(0.491, 0.29),
				ZIndex = zIndex + 2,
				Parent = preview,
			})
			Fn.addCorner(zip, 2)
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
		Fn.create("UIStroke", {
			Color = Theme.White,
			Thickness = 3,
			Parent = ring,
		})
		if item.Visual == "WIRE GLASSES" then
			part(UDim2.fromScale(0.16, 0.18), UDim2.fromScale(0.3, 0.4))
			part(UDim2.fromScale(0.16, 0.18), UDim2.fromScale(0.54, 0.4))
		end
	end

	Fn.create("TextLabel", {
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

function Fn.makeWindow(name: string, size: UDim2): Frame
	local window = Fn.create("Frame", {
		Name = name,
		BackgroundColor3 = Theme.Surface,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.52, 0),
		Visible = false,
		ZIndex = 10,
		Parent = screenGui,
	}) :: Frame
	Fn.addCorner(window, 18)
	Fn.addStroke(window, Theme.Paper, 4)
	return window
end

local inventoryWindow = Fn.makeWindow("InventoryWindow", UDim2.fromScale(0.84, 0.77))
local fitWindow = Fn.makeWindow("FitWindow", UDim2.fromScale(0.84, 0.77))
local phoneWindow = Fn.create("Frame", {
	Name = "PhoneWindow",
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.fromOffset(414, 660),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 740),
	ClipsDescendants = false,
	Visible = false,
	ZIndex = 10,
	Parent = screenGui,
}) :: Frame
Fn.addCorner(phoneWindow, 38)
Fn.addStroke(phoneWindow, Theme.Paper, 4)

local phoneScreen = Fn.create("Frame", {
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -16, 1, -16),
	Position = UDim2.fromOffset(8, 8),
	ClipsDescendants = true,
	ZIndex = 11,
	Parent = phoneWindow,
}) :: Frame
Fn.addCorner(phoneScreen, 31)

Fn.create("TextLabel", {
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
local dynamicIsland = Fn.create("Frame", {
	BackgroundColor3 = Theme.Paper,
	Size = UDim2.fromOffset(106, 27),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	ZIndex = 20,
	Parent = phoneScreen,
}) :: Frame
Fn.addCorner(dynamicIsland, 15)
Fn.create("Frame", {
	BackgroundColor3 = Theme.Lime,
	Size = UDim2.fromOffset(8, 8),
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	ZIndex = 21,
	Parent = dynamicIsland,
})
Fn.create("TextLabel", {
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
Fn.create("TextLabel", {
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
local battery = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(18, 9),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 15),
	ZIndex = 21,
	Parent = phoneScreen,
}) :: Frame
Fn.addCorner(battery, 3)
Fn.addStroke(battery, Theme.Paper, 1)

function Fn.makePhoneSideButton(position: UDim2, size: UDim2)
	local sideButton = Fn.create("Frame", {
		BackgroundColor3 = Theme.Paper,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		ZIndex = 9,
		Parent = phoneWindow,
	})
	Fn.addCorner(sideButton, 3)
	return sideButton
end
Fn.makePhoneSideButton(UDim2.fromOffset(-4, 128), UDim2.fromOffset(5, 30))
Fn.makePhoneSideButton(UDim2.fromOffset(-4, 187), UDim2.fromOffset(5, 48))
Fn.makePhoneSideButton(UDim2.fromOffset(-4, 243), UDim2.fromOffset(5, 48))
Fn.makePhoneSideButton(UDim2.new(1, -1, 0, 172), UDim2.fromOffset(5, 72))
local homeBar = Fn.create("Frame", {
	BackgroundColor3 = Theme.Paper,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(132, 5),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	ZIndex = 24,
	Parent = phoneScreen,
})
Fn.addCorner(homeBar, 5)

local activeWindow: Frame? = nil
function Fn.closeWindows()
	Fn.setCameraActive(false)
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

function Fn.openWindow(window: Frame)
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

backdrop.MouseButton1Click:Connect(Fn.closeWindows)

-- Inventory window ---------------------------------------------------------
local inventoryHeader = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 88),
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: Frame
Fn.addPadding(inventoryHeader, 28, 28, 22, 14)
Fn.create("TextLabel", {
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
Fn.create("TextLabel", {
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
local inventoryClose = Fn.makeButton(inventoryHeader, "×", UDim2.fromOffset(42, 42), false)
inventoryClose.AnchorPoint = Vector2.new(1, 0.5)
inventoryClose.Position = UDim2.new(1, 0, 0.5, 0)
inventoryClose.ZIndex = 12
inventoryClose.MouseButton1Click:Connect(Fn.closeWindows)

local categoryRail = Fn.create("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.new(0, 140, 1, -112),
	Position = UDim2.fromOffset(24, 88),
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: Frame
Fn.addCorner(categoryRail, 15)
Fn.addPadding(categoryRail, 11, 11, 12, 12)
local categoryLayout = Fn.create("UIListLayout", {
	Padding = UDim.new(0, 8),
	Parent = categoryRail,
})

local inventoryGrid = Fn.create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -516, 1, -138),
	Position = UDim2.fromOffset(185, 109),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Theme.Lime,
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: ScrollingFrame
Fn.addPadding(inventoryGrid, 3, 3, 3, 3)
local gridLayout = Fn.create("UIGridLayout", {
	CellSize = UDim2.fromOffset(174, 242),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = inventoryGrid,
})

local inspector = Fn.create("Frame", {
	BackgroundColor3 = Theme.Surface,
	Size = UDim2.fromOffset(292, 0),
	Position = UDim2.new(1, -316, 0, 106),
	AnchorPoint = Vector2.new(0, 0),
	ZIndex = 11,
	Parent = inventoryWindow,
}) :: Frame
inspector.Size = UDim2.new(0, 292, 1, -132)
Fn.addCorner(inspector, 15)
Fn.addPadding(inspector, 17, 17, 17, 17)

local inspectorBrand = Fn.create("TextLabel", {
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
local inspectorName = Fn.create("TextLabel", {
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
local inspectorMeta = Fn.create("TextLabel", {
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

local equippedPanel = Fn.create("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.new(1, 0, 0, 136),
	Position = UDim2.fromOffset(0, 165),
	ZIndex = 12,
	Parent = inspector,
}) :: Frame
Fn.addCorner(equippedPanel, 12)
Fn.addPadding(equippedPanel, 11, 11, 10, 10)
Fn.create("TextLabel", {
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
local equippedList = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, -26),
	Position = UDim2.fromOffset(0, 26),
	ZIndex = 13,
	Parent = equippedPanel,
}) :: Frame
Fn.create("UIListLayout", {
	Padding = UDim.new(0, 4),
	Parent = equippedList,
})

local equipButton = Fn.makeButton(inspector, "EQUIP TO FIT", UDim2.new(1, 0, 0, 45), true)
equipButton.Position = UDim2.new(0, 0, 1, -101)
equipButton.ZIndex = 13
local listButton = Fn.makeButton(inspector, "LIST ON FLIPTAG", UDim2.new(1, 0, 0, 43), false)
listButton.Position = UDim2.new(0, 0, 1, -50)
listButton.ZIndex = 13

local categoryButtons: { [string]: TextButton } = {}
for _, category in ipairs(CategoryOrder) do
	local button = Fn.makeButton(categoryRail, CategoryShort[category], UDim2.new(1, 0, 0, 48), false)
	button.ZIndex = 12
	categoryButtons[category] = button
end

function Fn.clearChildrenExceptLayout(parent: Instance)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end


function Fn.refreshEquipped()
	Fn.clearChildrenExceptLayout(equippedList)
	for _, category in ipairs(CategoryOrder) do
		local item = equipped[category]
		Fn.create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Enum.Font.GothamMedium,
			Text = string.format("%s  %s", CategoryShort[category], if item then item.Name else "—"),
			TextColor3 = if item then Theme.Paper else Theme.Muted,
			TextSize = 9,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 14,
			Parent = equippedList,
		})
	end
end

function Fn.refreshInspector()
	inspectorBrand.Text = string.upper(selectedItem.Brand)
	inspectorBrand.TextColor3 = Fn.rarityColor(selectedItem)
	inspectorName.Text = selectedItem.Name
	local status = if selectedItem.State == "Owned" then "IN WARDROBE" elseif selectedItem.State == "Listed" then "ON DELIVERY" elseif selectedItem.State == "Traded" then "TRADED AWAY" else "SOLD"
	inspectorMeta.Text = string.format("%s · %s\n%s · $%s", selectedItem.Style, selectedItem.Rarity, status, Fn.formatCoins(selectedItem.Value))
	if selectedItem.Limited then
		inspectorMeta.Text ..= "\nLIMITED " .. selectedItem.Limited
	end

	local available = selectedItem.State == "Owned"
	equipButton.Text = if equipped[selectedItem.Category] == selectedItem then "EQUIPPED" else "EQUIP TO FIT"
	equipButton.BackgroundColor3 = if available then Theme.Lime else Theme.SurfaceLight
	equipButton.TextColor3 = if available then Theme.Background else Theme.Muted
	listButton.Text = if selectedItem.State == "Owned" then "LIST ON FLIPTAG" elseif selectedItem.State == "Listed" then "DELIVERY IN PROGRESS" elseif selectedItem.State == "Lost" then "PACKAGE LOST" elseif selectedItem.State == "Traded" then "TRADED AWAY" else "ALREADY SOLD"
	listButton.TextColor3 = if selectedItem.State == "Owned" then Theme.Paper else Theme.Muted
	Fn.refreshEquipped()
end

function Fn.makeItemCard(item: ClothingItem, order: number)
	local card = Fn.create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if selectedItem == item then Theme.SurfaceLight else Theme.Surface,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Text = "",
		ZIndex = 12,
		Parent = inventoryGrid,
	}) :: TextButton
	Fn.addCorner(card, 13)
	Fn.addStroke(card, if selectedItem == item then Theme.Lime else Theme.SurfaceLight, 1)
	Fn.addPadding(card, 12, 12, 11, 11)

	Fn.createGarmentPreview(card, item, UDim2.fromOffset(12, 11), UDim2.new(1, -24, 0, 92), 13)
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 113),
		Font = Enum.Font.GothamBold,
		Text = string.upper(item.Brand),
		TextColor3 = Fn.rarityColor(item),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	Fn.create("TextLabel", {
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
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 178),
		Font = Enum.Font.GothamMedium,
		Text = string.format("%s · %s · LUCK +%.1f%%", item.Style, item.Rarity, Fn.rarityLuck(item.Rarity)),
		TextColor3 = Theme.Muted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -27),
		Font = Enum.Font.GothamBlack,
		Text = "$" .. Fn.formatCoins(item.Value),
		TextColor3 = Theme.Paper,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	if item.Limited then
		Fn.create("TextLabel", {
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
		Fn.create("TextLabel", {
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
		Fn.refreshInventory()
	end)
end

Fn.refreshInventory = function()
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
			Fn.makeItemCard(item, order)
		end
	end
	Fn.refreshInspector()
	cashLabel.Text = "$" .. Fn.formatCoins(coins)
	local luck = 0
	for _, equippedItem in pairs(equipped) do
		if equippedItem then
			if equippedItem.Rarity == "Uncommon" then luck += 0.1 end
			if equippedItem.Rarity == "Rare" then luck += 0.25 end
			if equippedItem.Rarity == "Epic" then luck += 0.5 end
			if equippedItem.Rarity == "Grail" then luck += 1 end
			if equippedItem.Rarity == "Limited" then luck += 1.5 end
			if equippedItem.Rarity == "Legendary" then luck += 2 end
			if equippedItem.Rarity == "Mythic" then luck += 3 end
			if equippedItem.Rarity == "Secret" then luck += 5 end
		end
	end
	if rollState.LuckLabel then
		rollState.LuckLabel.Text = string.format("DROP LUCK  +%.1f%%  %.2fx", luck, 1 + luck / 100)
		rollState.LuckLabel.TextColor3 = if luck > 0 then Theme.Uncommon else Theme.Muted
	end
	if rollState.LuckRemote then
		rollState.LuckRemote:FireServer(luck)
	end
end

function Fn.removeFromWardrobe(item: ClothingItem)
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
		Fn.refreshInventory()
	end)
end

equipButton.MouseButton1Click:Connect(function()
	if selectedItem.State ~= "Owned" then
		Fn.showToast("THIS ITEM IS NOT IN YOUR WARDROBE", Theme.Danger)
		return
	end
	equipped[selectedItem.Category] = selectedItem
	Fn.showToast(selectedItem.Name .. " EQUIPPED", Theme.Lime)
	Fn.refreshInventory()
end)

-- Fit builder --------------------------------------------------------------
local fitHeader = Fn.create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.new(1, 0, 0, 88),
	ZIndex = 11,
	Parent = fitWindow,
}) :: Frame
Fn.addCorner(fitHeader, 20)
Fn.create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 1, -24),
	ZIndex = 11,
	Parent = fitHeader,
})
Fn.create("TextLabel", {
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
Fn.create("TextLabel", {
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
local fitClose = Fn.makeButton(fitHeader, "×", UDim2.fromOffset(44, 44), false)
fitClose.AnchorPoint = Vector2.new(1, 0.5)
fitClose.Position = UDim2.new(1, -22, 0.5, 0)
fitClose.ZIndex = 13
fitClose.MouseButton1Click:Connect(Fn.closeWindows)

local fitCloset = Fn.create("ScrollingFrame", {
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
Fn.addCorner(fitCloset, 16)
Fn.addPadding(fitCloset, 12, 12, 13, 13)
Fn.create("UIListLayout", {
	Padding = UDim.new(0, 8),
	Parent = fitCloset,
})

local fitStage = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(222, 237, 255),
	Size = UDim2.new(1, -388, 1, -130),
	Position = UDim2.fromOffset(364, 106),
	ZIndex = 11,
	Parent = fitWindow,
}) :: Frame
Fn.addCorner(fitStage, 16)
Fn.addStroke(fitStage, Theme.SurfaceLight, 1)
Fn.create("TextLabel", {
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
local mannequin = Fn.create("Frame", {
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
	local bodyPart = Fn.create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Size = detail[1],
		Position = detail[2],
		ZIndex = 12,
		Parent = mannequin,
	})
	Fn.addCorner(bodyPart, detail[3])
end

type FitDropSlot = {
	Frame: Frame,
	ItemLabel: TextLabel,
	ItemImage: ImageLabel,
	Category: string,
}

local fitDropSlots: { [string]: FitDropSlot } = {}
local fitSlotData = {
	{ Category = "Head", Label = "HEAD", Position = UDim2.new(0.5, -77, 0.12, 0), Size = UDim2.fromOffset(154, 66) },
	{ Category = "Top", Label = "TOP", Position = UDim2.new(0.5, -86, 0.34, 0), Size = UDim2.fromOffset(172, 90) },
	{ Category = "Bottom", Label = "BOTTOM", Position = UDim2.new(0.5, -86, 0.62, 0), Size = UDim2.fromOffset(172, 70) },
	{ Category = "Shoes", Label = "SHOES", Position = UDim2.new(0.5, -86, 0.82, 0), Size = UDim2.fromOffset(172, 70) },
	{ Category = "Accessory", Label = "EXTRA ACC", Position = UDim2.new(0.75, 14, 0.39, 0), Size = UDim2.fromOffset(140, 62) },
}

for _, slotData in ipairs(fitSlotData) do
	local slot = Fn.create("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Size = slotData.Size,
		Position = slotData.Position,
		ZIndex = 14,
		Parent = fitStage,
	}) :: Frame
	Fn.addCorner(slot, 12)
	Fn.addStroke(slot, Theme.Lime, 1)
	Fn.create("TextLabel", {
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
	local itemLabel = Fn.create("TextLabel", {
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
	local itemImage = Fn.create("ImageLabel", {
		BackgroundTransparency = 1,
		Size = if slotData.Category == "Top" then UDim2.fromOffset(110, 48) else UDim2.fromOffset(76, 34),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = if slotData.Category == "Top" then UDim2.new(0.5, 0, 0, 22) else UDim2.new(0.5, 0, 0, 24),
		Image = "",
		ScaleType = Enum.ScaleType.Fit,
		Visible = false,
		ZIndex = 15,
		Parent = slot,
	}) :: ImageLabel
	fitDropSlots[slotData.Category] = { Frame = slot, ItemLabel = itemLabel, ItemImage = itemImage, Category = slotData.Category }
end

local fitValue = Fn.create("TextLabel", {
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
Fn.addCorner(fitValue, 12)

local draggedItem: ClothingItem? = nil
local dragGhost: Frame? = nil
local isDraggingFitItem = false

function Fn.updateDragGhost(position: Vector3)
	if dragGhost then
		dragGhost.Position = UDim2.fromOffset(position.X - 70, position.Y - 40)
	end
end

function Fn.beginFitDrag(item: ClothingItem, position: Vector3)
	if item.State ~= "Owned" then
		Fn.showToast("ONLY OWNED ITEMS CAN BE WORN", Theme.Danger)
		return
	end
	draggedItem = item
	isDraggingFitItem = true
	dragGhost = Fn.create("Frame", {
		BackgroundColor3 = Theme.LimeDark,
		Size = UDim2.fromOffset(140, 80),
		ZIndex = 50,
		Parent = screenGui,
	}) :: Frame
	Fn.addCorner(dragGhost, 13)
	Fn.addStroke(dragGhost, Theme.White, 1)
	Fn.create("TextLabel", {
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
	Fn.updateDragGhost(position)
end

function Fn.isInside(gui: GuiObject, position: Vector3): boolean
	local guiPosition = gui.AbsolutePosition
	local guiSize = gui.AbsoluteSize
	return position.X >= guiPosition.X and position.X <= guiPosition.X + guiSize.X and position.Y >= guiPosition.Y and position.Y <= guiPosition.Y + guiSize.Y
end

function Fn.endFitDrag(position: Vector3)
	if not isDraggingFitItem or not draggedItem then
		return
	end
	local dropped = false
	for category, slot in pairs(fitDropSlots) do
		if Fn.isInside(slot.Frame, position) then
			dropped = true
			if category == draggedItem.Category then
				equipped[category] = draggedItem
				Fn.showToast(draggedItem.Name .. " ADDED TO YOUR FIT", Theme.Lime)
			else
				Fn.showToast("DROP " .. string.upper(draggedItem.Category) .. " INTO ITS OWN SLOT", Theme.Danger)
			end
			break
		end
	end
	if not dropped then
		Fn.showToast("DROP THE ITEM ON A FIT SLOT", Theme.Danger)
	end
	if dragGhost then
		dragGhost:Destroy()
	end
	dragGhost = nil
	draggedItem = nil
	isDraggingFitItem = false
	Fn.refreshFit()
	Fn.refreshInventory()
end

function Fn.makeFitWardrobeCard(item: ClothingItem)
	local card = Fn.create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.SurfaceLight,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 88),
		Text = "",
		ZIndex = 12,
		Parent = fitCloset,
	}) :: TextButton
	Fn.addCorner(card, 12)
	Fn.createGarmentPreview(card, item, UDim2.fromOffset(8, 8), UDim2.fromOffset(80, 72), 13)
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -108, 0, 16),
		Position = UDim2.fromOffset(98, 12),
		Font = Enum.Font.GothamBold,
		Text = string.upper(item.Brand),
		TextColor3 = Fn.rarityColor(item),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	Fn.create("TextLabel", {
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
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -108, 0, 15),
		Position = UDim2.fromOffset(98, 62),
		Font = Enum.Font.GothamMedium,
		Text = string.format("DRAG TO %s · LUCK +%.1f%%", string.upper(item.Category), Fn.rarityLuck(item.Rarity)),
		TextColor3 = Theme.Muted,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Fn.beginFitDrag(item, input.Position)
		end
	end)
end

Fn.refreshFit = function()
	Fn.clearChildrenExceptLayout(fitCloset)
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			Fn.makeFitWardrobeCard(item)
		end
	end
	local value = 0
	for category, slot in pairs(fitDropSlots) do
		local item = equipped[category]
		if item then
			slot.ItemLabel.Text = item.Name
			slot.ItemLabel.TextColor3 = Fn.rarityColor(item)
			if item.Image and string.match(item.Image, "^rbxassetid://%d+$") then
				slot.ItemImage.Image = item.Image
				slot.ItemImage.Visible = true
				slot.ItemLabel.Position = if category == "Top" then UDim2.fromOffset(8, 72) else UDim2.fromOffset(8, 53)
				slot.ItemLabel.Size = UDim2.new(1, -16, 0, 15)
				slot.ItemLabel.TextSize = 8
			else
				slot.ItemImage.Image = ""
				slot.ItemImage.Visible = false
				slot.ItemLabel.Position = UDim2.fromOffset(8, 26)
				slot.ItemLabel.Size = UDim2.new(1, -16, 0, 25)
				slot.ItemLabel.TextSize = 10
			end
			slot.Frame.BackgroundColor3 = Theme.White
			value += item.Value
		else
			slot.ItemLabel.Text = "DROP ITEM HERE"
			slot.ItemLabel.TextColor3 = Theme.Muted
			slot.ItemImage.Image = ""
			slot.ItemImage.Visible = false
			slot.ItemLabel.Position = UDim2.fromOffset(8, 26)
			slot.ItemLabel.Size = UDim2.new(1, -16, 0, 25)
			slot.ItemLabel.TextSize = 10
			slot.Frame.BackgroundColor3 = Theme.Surface
		end
	end
	fitValue.Text = "FIT VALUE  $" .. Fn.formatCoins(value)
end

fitButton.MouseButton1Click:Connect(function()
	Fn.openWindow(fitWindow)
	Fn.refreshFit()
end)

UserInputService.InputChanged:Connect(function(input)
	if isDraggingFitItem and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		Fn.updateDragGhost(input.Position)
	end
	if cameraActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		cameraYaw = math.clamp(cameraYaw + input.Delta.X * 0.004, -1.25, 1.25)
		cameraPitch = math.clamp(cameraPitch - input.Delta.Y * 0.004, -0.42, 0.42)
		Fn.updateCameraView()
	elseif cameraActive and input.UserInputType == Enum.UserInputType.MouseWheel then
		cameraDistance = math.clamp(cameraDistance - input.Position.Z * 0.45, 4, 10)
		Fn.updateCameraView()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if isDraggingFitItem and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		Fn.endFitDrag(input.Position)
	end
end)

-- Phone window -------------------------------------------------------------
local phoneTop = Fn.create("Frame", {
	BackgroundColor3 = Theme.LimeDark,
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.fromOffset(0, 38),
	ZIndex = 11,
	Parent = phoneScreen,
}) :: Frame
Fn.addCorner(phoneTop, 20)
local phoneTopBottom = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 12),
	Position = UDim2.new(0, 0, 1, -12),
	ZIndex = 11,
	Parent = phoneTop,
}) :: Frame
local phoneTitle = Fn.create("TextLabel", {
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
local phoneSubtitle = Fn.create("TextLabel", {
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
local phoneClose = Fn.makeButton(phoneTop, "×", UDim2.fromOffset(34, 34), false)
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
		Fn.setCameraActive(false)
		currentPhoneApp = "HOME"
		currentSocialTab = "FYP"
		currentPhoneTab = "LISTINGS"
		phoneWindow.Visible = true
		backdrop.Visible = true
		Fn.refreshPhone()
	else
		Fn.closeWindows()
	end
end)

local phoneTabs = Fn.create("Frame", {
	BackgroundColor3 = Theme.Background,
	Size = UDim2.new(1, 0, 0, 52),
	Position = UDim2.fromOffset(0, 88),
	ZIndex = 11,
	Parent = phoneScreen,
}) :: Frame
Fn.addPadding(phoneTabs, 18, 18, 8, 8)
Fn.create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	Parent = phoneTabs,
})
local phoneTabButtons: { [string]: TextButton } = {}
for _, tab in ipairs({ "LISTINGS", "DELIVERIES", "UPGRADES" }) do
	local button = Fn.makeButton(phoneTabs, tab, UDim2.new(1 / 3, -5, 1, 0), false)
	button.ZIndex = 12
	phoneTabButtons[tab] = button
end
for _, tab in ipairs({ "FYP", "PROFILE", "CAMERA" }) do
	local button = Fn.makeButton(phoneTabs, tab, UDim2.new(1 / 4, -5, 1, 0), false)
	button.ZIndex = 12
	button.Visible = false
	phoneTabButtons[tab] = button
end

local phoneContent = Fn.create("ScrollingFrame", {
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
Fn.create("UIListLayout", {
	Padding = UDim.new(0, 9),
	Parent = phoneContent,
})

-- REAL CAMERA OVERLAY -------------------------------------------------------
-- The 3D world remains visible behind this transparent camera UI. The
-- camera itself is controlled through Workspace.CurrentCamera (Scriptable).
cameraOverlay = Fn.create("Frame", {
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
local cameraCaptureMask = Fn.create("Frame", {
	Name = "CameraCaptureMask",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 80,
	Parent = cameraOverlay,
}) :: Frame

local cameraMaskTop = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame
local cameraMaskBottom = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame
local cameraMaskLeft = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame
local cameraMaskRight = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(225, 235, 246),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 80,
	Parent = cameraCaptureMask,
}) :: Frame

local cameraFrameGuide = Fn.create("Frame", {
	Name = "PhoneCameraFrame",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 89,
	Parent = cameraOverlay,
}) :: Frame
Fn.create("UIAspectRatioConstraint", {
	AspectRatio = 9 / 16,
	DominantAxis = Enum.DominantAxis.Height,
	Parent = cameraFrameGuide,
})
Fn.addStroke(cameraFrameGuide, SocialTheme.Text, 5, 0.02)
Fn.addCorner(cameraFrameGuide, 24)

local cameraFrameInner = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -10, 1, -10),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 90,
	Parent = cameraFrameGuide,
}) :: Frame
Fn.addCorner(cameraFrameInner, 20)
Fn.addStroke(cameraFrameInner, SocialTheme.Purple, 2, 0.08)

local cameraFrameTopGlow = Fn.create("Frame", {
	BackgroundColor3 = SocialTheme.Purple,
	BackgroundTransparency = 0.0,
	BorderSizePixel = 0,
	Size = UDim2.new(0.62, 0, 0, 3),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	ZIndex = 90,
	Parent = cameraFrameGuide,
}) :: Frame
Fn.addCorner(cameraFrameTopGlow, 2)

local cameraTopBar = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(7, 6, 12),
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 68),
	Position = UDim2.fromOffset(0, 0),
	ZIndex = 81,
	Parent = cameraFrameGuide,
}) :: Frame

local cameraClose = Fn.create("TextButton", {
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
Fn.addCorner(cameraClose, 14)

local cameraBottomBar = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(7, 6, 12),
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 150),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	ZIndex = 81,
	Parent = cameraFrameGuide,
}) :: Frame

cameraHud = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 42),
	Position = UDim2.fromOffset(0, 58),
	ZIndex = 82,
	Parent = cameraBottomBar,
}) :: Frame

local cameraModeButton = Fn.makeButton(cameraHud, "FRONT", UDim2.fromOffset(76, 42), true)
cameraModeButton.Position = UDim2.new(0.5, -157, 0, 0)
cameraModeButton.BackgroundColor3 = SocialTheme.Purple
cameraModeButton.TextColor3 = SocialTheme.Text
cameraModeButton.ZIndex = 83

local cameraZoomOut = Fn.makeButton(cameraHud, "−", UDim2.fromOffset(38, 38), false)
cameraZoomOut.Position = UDim2.new(0.5, 53, 0, 2)
cameraZoomOut.ZIndex = 83

local cameraZoomLabel = Fn.create("TextLabel", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.08,
	Size = UDim2.fromOffset(48, 38),
	Position = UDim2.new(0.5, 95, 0, 2),
	Font = Enum.Font.GothamBlack,
	Text = "1.0×",
	TextColor3 = SocialTheme.Text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 83,
	Parent = cameraHud,
}) :: TextLabel
Fn.addCorner(cameraZoomLabel, 12)

local cameraZoomIn = Fn.makeButton(cameraHud, "+", UDim2.fromOffset(38, 38), false)
cameraZoomIn.Position = UDim2.new(0.5, 147, 0, 2)
cameraZoomIn.ZIndex = 83

cameraReticle = Fn.create("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(88, 88),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 82,
	Parent = cameraOverlay,
}) :: Frame
Fn.addStroke(cameraReticle, SocialTheme.Text, 1, 0.45)
Fn.addCorner(cameraReticle, 44)

local reticleH = Fn.create("Frame", {
	BackgroundColor3 = SocialTheme.Text,
	BackgroundTransparency = 0.35,
	Size = UDim2.fromOffset(1, 28),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 83,
	Parent = cameraReticle,
})
local reticleV = Fn.create("Frame", {
	BackgroundColor3 = SocialTheme.Text,
	BackgroundTransparency = 0.35,
	Size = UDim2.fromOffset(28, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 83,
	Parent = cameraReticle,
})

local cameraStatus = Fn.create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -48, 0, 1),
	Position = UDim2.new(0, 24, 0, 58),
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

cameraShutter = Fn.create("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Size = UDim2.fromOffset(82, 82),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Font = Enum.Font.GothamBlack,
	Text = "●",
	TextColor3 = SocialTheme.Purple,
	TextSize = 40,
	ZIndex = 84,
	Parent = cameraBottomBar,
}) :: TextButton
Fn.addCorner(cameraShutter, 41)
Fn.addStroke(cameraShutter, SocialTheme.Purple, 4)

local cameraFlash = Fn.create("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 120,
	Parent = cameraOverlay,
}) :: Frame

-- Post preview: shown only AFTER the photo is captured. The photo is not posted
-- until the player presses POST TO RO-GRAM.
function Fn.closePostPreview()
	pendingPhotoContent = nil
	pendingPhotoId = nil
	if postPreviewCaption then postPreviewCaption.Text = "" end
	if postPreviewModal then postPreviewModal.Visible = false end
end

postPreviewModal = Fn.create("Frame", {
	Name = "RoGramPostPreview",
	BackgroundColor3 = Color3.fromRGB(7, 18, 14),
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 300,
	Parent = phoneScreen,
}) :: Frame

local postPreviewCard = Fn.create("Frame", {
	BackgroundColor3 = SocialTheme.Surface,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -32, 0, 500),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.53, 0),
	ZIndex = 301,
	Parent = postPreviewModal,
}) :: Frame
Fn.addCorner(postPreviewCard, 22)
Fn.addStroke(postPreviewCard, SocialTheme.Purple, 2, 0.15)

Fn.create("TextLabel", {
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

local postPreviewCancel = Fn.create("TextButton", {
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
Fn.addCorner(postPreviewCancel, 17)

postPreviewImage = Fn.create("ImageLabel", {
	BackgroundColor3 = SocialTheme.SurfaceLight,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -28, 0, 230),
	Position = UDim2.fromOffset(14, 52),
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 302,
	Parent = postPreviewCard,
}) :: ImageLabel
Fn.addCorner(postPreviewImage, 16)

Fn.create("TextLabel", {
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

postPreviewCaption = Fn.create("TextBox", {
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
Fn.addCorner(postPreviewCaption, 13)
Fn.addPadding(postPreviewCaption, 11, 11, 9, 9)

local postPreviewDiscard = Fn.create("TextButton", {
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
Fn.addCorner(postPreviewDiscard, 14)

local postPreviewPost = Fn.create("TextButton", {
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
Fn.addCorner(postPreviewPost, 14)

postPreviewCancel.MouseButton1Click:Connect(Fn.closePostPreview)
postPreviewDiscard.MouseButton1Click:Connect(function()
	Fn.closePostPreview()
	Fn.showToast("PHOTO DISCARDED", SocialTheme.Purple)
end)

postPreviewPost.MouseButton1Click:Connect(function()
	if not pendingPhotoContent or not pendingPhotoId then
		Fn.closePostPreview()
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
	Fn.closePostPreview()
	Fn.flashCamera()
	Fn.showToast("PHOTO POSTED TO RO-GRAM", SocialTheme.Purple)
	currentSocialTab = "PROFILE"
	profileName = player.Name
	currentPhoneApp = "SOCIAL"
	phoneWindow.Visible = true
	backdrop.Visible = true
	Fn.refreshPhone()
end)

function Fn.addPhoneLabel(text: string, muted: boolean?)
	Fn.create("TextLabel", {
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

function Fn.addPhoneCard(item: ClothingItem, actionText: string, action: () -> ())
	local card = Fn.create("Frame", {
		BackgroundColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Surface else Theme.Surface,
		Size = UDim2.new(1, 0, 0, 100),
		ZIndex = 12,
		Parent = phoneContent,
	}) :: Frame
	Fn.addCorner(card, 13)
	Fn.addPadding(card, 13, 13, 12, 12)
	local bar = Fn.create("Frame", {
		BackgroundColor3 = Fn.rarityColor(item),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(4, 58),
		ZIndex = 13,
		Parent = card,
	})
	Fn.addCorner(bar, 4)
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 0, 17),
		Position = UDim2.fromOffset(14, 1),
		Font = Enum.Font.GothamBold,
		Text = string.upper(item.Brand),
		TextColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Purple else Fn.rarityColor(item),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	Fn.create("TextLabel", {
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
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 0, 18),
		Position = UDim2.fromOffset(14, 61),
		Font = Enum.Font.GothamMedium,
		Text = "$" .. Fn.formatCoins(item.Value),
		TextColor3 = if currentPhoneApp == "SOCIAL" then SocialTheme.Muted else Theme.Muted,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 13,
		Parent = card,
	})
	local button = Fn.makeButton(card, actionText, UDim2.fromOffset(105, 38), actionText == "POST")
	if currentPhoneApp == "SOCIAL" then
		button.BackgroundColor3 = SocialTheme.Purple
		button.TextColor3 = SocialTheme.Text
	end
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.ZIndex = 14
	button.MouseButton1Click:Connect(action)
end

function Fn.socialNames(): { string }
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

function Fn.socialCard(height: number): Frame
	local card = Fn.create("Frame", {
		BackgroundColor3 = SocialTheme.Surface,
		Size = UDim2.new(1, 0, 0, height),
		ZIndex = 12,
		Parent = phoneContent,
	}) :: Frame
	Fn.addCorner(card, 13)
	Fn.addPadding(card, 13, 13, 12, 12)
	return card
end

Fn.updateCameraFrame = function()
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

Fn.setCameraActive = function(active: boolean)
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
		Fn.updateCameraFrame()
		Fn.updateCameraView()
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

Fn.updateCameraView = function()
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
	if cameraModeButton then cameraModeButton.Text = cameraMode end
end

function Fn.flashCamera()
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

function Fn.takeRoGramPhoto()
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
	Fn.updateCameraFrame()

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
			Fn.setCameraActive(false)
			currentPhoneApp = "SOCIAL"
			currentSocialTab = "FYP"
			phoneWindow.Visible = true
			phoneWindow.Active = true
			backdrop.Visible = true
			Fn.refreshPhone()
			if postPreviewModal then postPreviewModal.Visible = true end
		else
			Fn.showToast("CAMERA CAPTURE FAILED", Theme.Danger)
		end
	end)
end

cameraClose.MouseButton1Click:Connect(function()
	Fn.setCameraActive(false)
	currentPhoneApp = "HOME"
	currentSocialTab = "FYP"
	currentPhoneTab = "LISTINGS"
	phoneWindow.Visible = true
	phoneDock.Visible = false
	backdrop.Visible = true
	Fn.refreshPhone()
end)

cameraModeButton.MouseButton1Click:Connect(function()
	cameraMode = if cameraMode == "SELFIE" then "FRONT" else "SELFIE"
	Fn.updateCameraView()
end)

cameraZoomOut.MouseButton1Click:Connect(function()
	cameraDistance = math.clamp(cameraDistance + 0.7, 4, 10)
	Fn.updateCameraView()
end)

cameraZoomIn.MouseButton1Click:Connect(function()
	cameraDistance = math.clamp(cameraDistance - 0.7, 4, 10)
	Fn.updateCameraView()
end)

cameraShutter.MouseButton1Click:Connect(Fn.takeRoGramPhoto)

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if cameraActive then
		Fn.updateCameraFrame()
	end
end)

function Fn.getProfilePlayer(name: string): Player?
	local found = Players:FindFirstChild(name)
	if found and found:IsA("Player") then
		return found
	end
	return nil
end

function Fn.getProfileBio(name: string): string
	local cached = socialBios[name]
	if cached ~= nil then
		return cached
	end
	local profilePlayer = Fn.getProfilePlayer(name)
	if profilePlayer then
		local attr = profilePlayer:GetAttribute("SocialBio")
		if type(attr) == "string" then
			socialBios[name] = attr
			return attr
		end
	end
	return "No bio yet."
end

function Fn.openSocialProfile(name: string)
	profileName = name
	socialSearchQuery = name
	currentSocialTab = "PROFILE"
	tradeTarget = nil
	Fn.refreshPhone()
end

function Fn.addSocialPhoto(owner: string, caption: string, pose: string, likes: number, captureContent: string?, photoId: string?)
	local isOwnPhoto = owner == player.Name and photoId ~= nil
	local card = Fn.socialCard(258)
	local photo = Fn.create("Frame", {
		BackgroundColor3 = SocialTheme.SurfaceLight,
		Size = UDim2.new(1, 0, 0, 182),
		ZIndex = 13,
		Parent = card,
	}) :: Frame
	Fn.addCorner(photo, 10)
	Fn.create("UIAspectRatioConstraint", {
		AspectRatio = 9 / 16,
		DominantAxis = Enum.DominantAxis.Width,
		Parent = photo,
	})

	if captureContent then
		local capturedImage = Fn.create("ImageLabel", {
			BackgroundColor3 = SocialTheme.SurfaceLight,
			BackgroundTransparency = 0,
			Image = captureContent,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 13,
			Parent = photo,
		}) :: ImageLabel
		Fn.addCorner(capturedImage, 10)
	else
		Fn.create("TextLabel", {
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

	local ownerButton = Fn.create("TextButton", {
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
	Fn.addCorner(ownerButton, 9)
	Fn.addPadding(ownerButton, 10, 10, 0, 0)
	ownerButton.MouseButton1Click:Connect(function()
		Fn.openSocialProfile(owner)
	end)

	Fn.create("TextLabel", {
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
	local captionLabel = Fn.create("TextLabel", {
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
		local deleteButton = Fn.makeButton(card, "DELETE", UDim2.fromOffset(76, 28), false)
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
			Fn.showToast("PHOTO DELETED", SocialTheme.Purple)
			Fn.refreshPhone()
		end)
	end
end

function Fn.makeSocialButton(parent: Instance, text: string, size: UDim2, filled: boolean?, compact: boolean?): TextButton
	local isFilled = filled == true
	local button = Fn.create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = if isFilled then SocialTheme.Purple else SocialTheme.Surface,
		Size = size,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = if isFilled then SocialTheme.Text else SocialTheme.PurpleDark,
		TextSize = if compact then 10 else 11,
		Parent = parent,
	}) :: TextButton
	Fn.addCorner(button, if compact then 18 else 10)
	Fn.addStroke(button, SocialTheme.Purple, if isFilled then 1 else 2, 0.05)
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

function Fn.addSocialProfile(name: string, isOwnProfile: boolean)
	local profilePlayer = Fn.getProfilePlayer(name)
	local profileUserId = if profilePlayer then profilePlayer.UserId else player.UserId
	local card = Fn.socialCard(if isOwnProfile then 196 else 150)
	local avatar = Fn.create("ImageLabel", {
		BackgroundColor3 = SocialTheme.SurfaceLight,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(profileUserId) .. "&w=150&h=150",
		Size = UDim2.fromOffset(66, 66),
		Position = UDim2.fromOffset(0, 0),
		ZIndex = 14,
		Parent = card,
	}) :: ImageLabel
	Fn.addCorner(avatar, 33)
	Fn.addStroke(avatar, SocialTheme.Purple, 2)

	Fn.create("TextLabel", {
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
	Fn.create("TextLabel", {
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
	local bioLabel = Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, if isOwnProfile then 46 else 62),
		Position = UDim2.fromOffset(0, 76),
		Font = Enum.Font.GothamMedium,
		Text = Fn.getProfileBio(name),
		TextColor3 = SocialTheme.Text,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = card,
	})

	if isOwnProfile then
		local edit = Fn.makeSocialButton(card, "EDIT BIO", UDim2.fromOffset(92, 30), false, true)
		edit.AnchorPoint = Vector2.new(1, 1)
		edit.Position = UDim2.new(1, 0, 1, 0)
		edit.ZIndex = 15
		edit.MouseButton1Click:Connect(function()
			bioLabel.Visible = false
			edit.Visible = false
			local box = Fn.create("TextBox", {
				BackgroundColor3 = SocialTheme.SurfaceLight,
				Size = UDim2.new(1, -106, 0, 48),
				Position = UDim2.fromOffset(0, 76),
				ClearTextOnFocus = false,
				MultiLine = true,
				Text = Fn.getProfileBio(name) == "No bio yet." and "" or Fn.getProfileBio(name),
				PlaceholderText = "WRITE SOMETHING ABOUT YOUR STYLE...",
				TextColor3 = SocialTheme.Text,
				PlaceholderColor3 = SocialTheme.Muted,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 16,
				Parent = card,
			}) :: TextBox
			Fn.addCorner(box, 9)
			Fn.addPadding(box, 10, 10, 7, 7)
			local save = Fn.makeSocialButton(card, "SAVE", UDim2.fromOffset(74, 30), true, true)
			save.AnchorPoint = Vector2.new(1, 1)
			save.Position = UDim2.new(1, 0, 1, 0)
			save.ZIndex = 16
			save.MouseButton1Click:Connect(function()
				local text = string.sub(box.Text, 1, 160)
				socialBios[name] = text
				if setBioRemote then
					setBioRemote:FireServer(text)
				end
				Fn.showToast("PROFILE BIO SAVED", SocialTheme.Purple)
				Fn.refreshPhone()
			end)
		end)
	else
		local action = Fn.makeSocialButton(card, if socialFollowers[name] then "✓ FOLLOWING" else "+ FOLLOW", UDim2.fromOffset(108, 32), true, true)
		action.AnchorPoint = Vector2.new(1, 0)
		action.Position = UDim2.new(1, 0, 0, 4)
		action.ZIndex = 14
		action.MouseButton1Click:Connect(function()
			if socialFollowers[name] then
				socialFollowers[name] = nil
				Fn.showToast("UNFOLLOWED @" .. name, Theme.Muted)
			else
				socialFollowers[name] = 1
				Fn.showToast("FOLLOWING @" .. name .. "  ·  +$1 / 30s", Theme.Lime)
			end
			Fn.refreshPhone()
		end)
		local trade = Fn.makeSocialButton(card, "↔ TRADE", UDim2.fromOffset(108, 32), false, true)
		trade.AnchorPoint = Vector2.new(1, 0)
		trade.Position = UDim2.new(1, 0, 0, 42)
		trade.ZIndex = 14
		trade.MouseButton1Click:Connect(function()
			tradeTarget = name
			if tradeRemote then
				local targetPlayer = Fn.getProfilePlayer(name)
				if targetPlayer then
					tradeRemote:FireServer("Request", targetPlayer.UserId)
				end
			end
			Fn.refreshPhone()
			Fn.showToast("TRADE REQUEST SENT TO @" .. name, SocialTheme.Purple)
		end)
	end
end

function Fn.addTradeItemRow(parent: Instance, item: ClothingItem, selected: boolean, actionText: string, callback: () -> ())
	local row = Fn.create("Frame", {
		BackgroundColor3 = if selected then SocialTheme.SurfaceLight else SocialTheme.Surface,
		Size = UDim2.new(1, 0, 0, 56),
		ZIndex = 13,
		Parent = parent,
	}) :: Frame
	Fn.addCorner(row, 9)
	Fn.create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -92, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Text = item.Name .. "\n$" .. Fn.formatCoins(item.Value),
		TextColor3 = SocialTheme.Text,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 14,
		Parent = row,
	})
	local button = Fn.makeSocialButton(row, actionText, UDim2.fromOffset(78, 32), selected, true)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -8, 0.5, 0)
	button.ZIndex = 15
	button.MouseButton1Click:Connect(callback)
end

function Fn.addTradePanel()
	local card = Fn.socialCard(420)
	Fn.addPhoneLabel("TRADE  /  @" .. tostring(tradeTarget or "PLAYER"), false)
	Fn.create("TextLabel", {
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
	local list = Fn.create("ScrollingFrame", {
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
	Fn.create("UIListLayout", { Padding = UDim.new(0, 5), Parent = list })
	for _, item in ipairs(inventory) do
		if item.State == "Owned" then
			local selected = table.find(tradeMyOffer, item.Id) ~= nil
			Fn.addTradeItemRow(list, item, selected, if selected then "REMOVE" else "OFFER", function()
				if selected then
					table.remove(tradeMyOffer, table.find(tradeMyOffer, item.Id) :: number)
				else
					table.insert(tradeMyOffer, item.Id)
				end
				tradeMyReady = false
				if tradeRemote then tradeRemote:FireServer("Offer", tradeMyOffer) end
				Fn.refreshPhone()
			end)
		end
	end
	local their = Fn.create("TextLabel", {
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
		local item = Fn.findInventoryItem(id)
		if item then table.insert(theirNames, item.Name) end
	end
	Fn.create("TextLabel", {
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
	local status = Fn.create("TextLabel", {
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
	local ready = Fn.makeSocialButton(card, if tradeMyReady then "UNREADY" else "READY", UDim2.fromOffset(98, 36), tradeMyReady, true)
	ready.Position = UDim2.fromOffset(0, 304)
	ready.ZIndex = 15
	ready.MouseButton1Click:Connect(function()
		tradeMyReady = not tradeMyReady
		if tradeRemote then tradeRemote:FireServer("Ready", tradeMyReady) end
		Fn.refreshPhone()
	end)
	local cancel = Fn.makeSocialButton(card, "CANCEL", UDim2.fromOffset(98, 36), false, true)
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
		Fn.refreshPhone()
	end)
	if tradeMyReady and tradeTheirReady then
		local accept = Fn.makeSocialButton(card, "ACCEPT TRADE", UDim2.new(1, 0, 0, 42), true, true)
		accept.Position = UDim2.fromOffset(0, 352)
		accept.ZIndex = 15
		accept.MouseButton1Click:Connect(function()
			if tradeRemote then tradeRemote:FireServer("Accept") end
			tradeStatus = "CONFIRMING..."
			Fn.refreshPhone()
		end)
	end
end

function Fn.refreshSocial()
	Fn.clearChildrenExceptLayout(phoneContent)
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
			Fn.addStroke(button, SocialTheme.PurpleDark, 1, 0.15)
		else
			Fn.addStroke(button, SocialTheme.SurfaceLight, 1, 0)
		end
	end
	phoneTabButtons.LISTINGS.Visible = false
	phoneTabButtons.DELIVERIES.Visible = false
	phoneTabButtons.UPGRADES.Visible = false
	phoneTabs.BackgroundColor3 = SocialTheme.Background
	phoneTabs.BackgroundTransparency = 0

	if currentSocialTab == "FYP" then
		local searchRow = Fn.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 42),
			ZIndex = 12,
			Parent = phoneContent,
		}) :: Frame
		local search = Fn.create("TextBox", {
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
		Fn.addCorner(search, 11)
		Fn.addPadding(search, 12, 12, 0, 0)
		local searchButton = Fn.makeSocialButton(searchRow, "SEARCH", UDim2.fromOffset(82, 42), true)
		searchButton.Position = UDim2.new(1, 0, 0, 0)
		searchButton.AnchorPoint = Vector2.new(1, 0)
		searchButton.BackgroundColor3 = SocialTheme.Purple
		searchButton.MouseButton1Click:Connect(function()
			socialSearchQuery = search.Text
			profileName = search.Text
			currentSocialTab = "PROFILE"
			Fn.refreshPhone()
		end)
		Fn.addPhoneLabel("FOR YOU  ·  PHONE FITS", false)
		if #socialPhotos == 0 then
			Fn.addPhoneLabel("NO POSTS YET", true)
			Fn.addPhoneLabel("Take a photo with CAMERA to make the first post.", false)
		else
			for _, photo in ipairs(socialPhotos) do
				Fn.addSocialPhoto(photo.Owner, photo.Caption, photo.Pose, photo.Likes, photo.CaptureContent, photo.PhotoId)
			end
		end
	elseif currentSocialTab == "PROFILE" then
		local profile = profileName
		if profile == "" then profile = player.Name end
		local isOwn = profile == player.Name
		local targetPlayer = Fn.getProfilePlayer(profile)
		if not isOwn and not targetPlayer then
			Fn.addPhoneLabel("PROFILE NOT FOUND", true)
			local back = Fn.makeSocialButton(phoneContent, "BACK TO FYP", UDim2.new(1, 0, 0, 42), true)
			back.ZIndex = 14
			back.MouseButton1Click:Connect(function()
				currentSocialTab = "FYP"
				Fn.refreshPhone()
			end)
			return
		end

		local back = Fn.makeSocialButton(phoneContent, "‹  BACK TO FYP", UDim2.new(1, 0, 0, 36), false)
		back.BackgroundColor3 = SocialTheme.SurfaceLight
		back.TextColor3 = SocialTheme.Muted
		back.ZIndex = 14
		back.MouseButton1Click:Connect(function()
			currentSocialTab = "FYP"
			tradeTarget = nil
			Fn.refreshPhone()
		end)
		Fn.addPhoneLabel("PROFILE  /  @" .. profile, false)
		Fn.addSocialProfile(profile, isOwn)

		if tradeIncomingFrom == profile and not tradeSessionActive then
			local requestCard = Fn.socialCard(92)
			Fn.create("TextLabel", {
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
			local accept = Fn.makeSocialButton(requestCard, "ACCEPT", UDim2.fromOffset(76, 32), true)
			accept.AnchorPoint = Vector2.new(1, 0.5)
			accept.Position = UDim2.new(1, -82, 0.5, 0)
			accept.ZIndex = 15
			accept.MouseButton1Click:Connect(function()
				tradeSessionActive = true
				tradeTarget = profile
				tradeIncomingFrom = nil
				tradeStatus = "TRADE OPEN"
				if tradeRemote then tradeRemote:FireServer("Respond", true) end
				Fn.refreshPhone()
			end)
			local decline = Fn.makeSocialButton(requestCard, "DECLINE", UDim2.fromOffset(76, 32), false)
			decline.AnchorPoint = Vector2.new(1, 0.5)
			decline.Position = UDim2.new(1, 0, 0.5, 0)
			decline.ZIndex = 15
			decline.MouseButton1Click:Connect(function()
				if tradeRemote then tradeRemote:FireServer("Respond", false) end
				tradeIncomingFrom = nil
				Fn.refreshPhone()
			end)
		end

		local profilePhotos = 0
		for _, photo in ipairs(socialPhotos) do
			if photo.Owner == profile then
				profilePhotos += 1
				Fn.addSocialPhoto(photo.Owner, photo.Caption, photo.Pose, photo.Likes, photo.CaptureContent, photo.PhotoId)
			end
		end
		if profilePhotos == 0 then
			Fn.addPhoneLabel("NO PHOTOS YET", true)
		end

		if tradeSessionActive and tradeTarget == profile then
			Fn.addTradePanel()
		end
	elseif currentSocialTab == "CAMERA" then
		-- Camera is a fixed capture mode: do not animate/slide the phone UI while shooting.
		phoneDock.Visible = false
		phoneWindow.Visible = false
		phoneWindow.Active = false
		Fn.setCameraActive(true)
	end
end

Fn.refreshPhone = function()
	if currentPhoneApp == "HOME" then
		Fn.setCameraActive(false)
		phoneWindow.Visible = true
		backdrop.Visible = true
		Fn.clearChildrenExceptLayout(phoneContent)
		for _, button in pairs(phoneTabButtons) do
			button.Visible = false
		end
		phoneTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		phoneTopBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		phoneScreen.BackgroundColor3 = SocialTheme.Background
		phoneTitle.Text = "PHONE"
		phoneSubtitle.Text = "YOUR APPS"

		local homeHeader = Fn.create("TextLabel", {
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
		local welcome = Fn.create("TextLabel", {
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
		local apps = Fn.create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 270),
			Position = UDim2.fromOffset(0, 102),
			ZIndex = 13,
			Parent = phoneContent,
		}) :: Frame
		local appGrid = Fn.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(128, 128),
			CellPadding = UDim2.fromOffset(12, 12),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Parent = apps,
		})
		local function addHomeApp(icon: string, title: string, subtitle: string, accent: Color3, appName: string)
			local button = Fn.create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = accent,
				Size = UDim2.fromOffset(128, 128),
				Text = "",
				ZIndex = 14,
				Parent = apps,
			}) :: TextButton
			Fn.addCorner(button, 25)
			Fn.addStroke(button, Color3.fromRGB(255, 255, 255), 1, 0.65)
			Fn.create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 58),
				Position = UDim2.fromOffset(0, 16),
				Text = icon,
				TextColor3 = SocialTheme.Text,
				TextSize = 38,
				ZIndex = 15,
				Parent = button,
			})
			Fn.create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.fromOffset(6, 72),
				Text = title,
				TextColor3 = SocialTheme.Text,
				TextSize = 14,
				ZIndex = 15,
				Parent = button,
			})
			Fn.create("TextLabel", {
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
				Fn.refreshPhone()
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
			Fn.setCameraActive(false)
			phoneWindow.Visible = true
			backdrop.Visible = true
		end
		Fn.refreshSocial()
		return
	end
	Fn.setCameraActive(false)
	phoneWindow.Visible = true
	Fn.clearChildrenExceptLayout(phoneContent)
	for tab, button in pairs(phoneTabButtons) do
		button.Visible = tab ~= "FYP" and tab ~= "PROFILE" and tab ~= "CAMERA"
		button.Text = tab
		local selected = tab == currentPhoneTab
		button.BackgroundColor3 = if selected then Theme.Lime else Theme.SurfaceLight
		button.TextColor3 = if selected then Theme.Background else Theme.Paper
	end

	if currentPhoneTab == "LISTINGS" then
		Fn.addPhoneLabel("READY TO POST")
		local posted = 0
		for _, item in ipairs(inventory) do
			if item.State == "Owned" then
				posted += 1
				Fn.addPhoneCard(item, "POST", function()
					-- Max 5 paczek naraz w rękach — resztę trzeba najpierw odłożyć w paczkomacie.
					if Fn.countPendingShipments() >= 5 then
						Fn.showToast("HANDS FULL — DROP PACKAGES AT THE PACZKOMAT [E]", Theme.Danger)
						return
					end
					item.State = "Listed"
					-- Dostawa startuje dopiero po odłożeniu paczek w paczkomacie (klawisz E).
					table.insert(shipments, { Item = item, FinishAt = 0 })
					-- Hand the player a cardboard box for the sold item (server-side).
					local thriftRemotes = ReplicatedStorage:FindFirstChild("ThriftRemotes")
					local boxRemote = thriftRemotes and thriftRemotes:FindFirstChild("FlipTagBox")
					if boxRemote and boxRemote:IsA("RemoteEvent") then
						boxRemote:FireServer()
					end
					Fn.showToast(item.Name .. " IS ON THE WAY", Theme.Lime)
					Fn.refreshInventory()
					Fn.refreshPhone()
				end)
			end
		end
		if posted == 0 then
			Fn.addPhoneLabel("NO ITEMS READY. FIND MORE PIECES IN A THRIFT STORE.", true)
		end
	elseif currentPhoneTab == "DELIVERIES" then
		Fn.addPhoneLabel("ACTIVE SHIPMENTS")
		if #shipments == 0 then
			Fn.addPhoneLabel("NOTHING IS ON THE ROAD RIGHT NOW.", true)
		end
		for _, shipment in ipairs(shipments) do
			if shipment.FinishAt == 0 then
				Fn.addPhoneCard(shipment.Item, "DROP OFF", function()
					Fn.showToast("GO TO THE PACZKOMAT AND PRESS E", Theme.Lime)
				end)
			else
				local secondsLeft = math.max(0, math.ceil(shipment.FinishAt - os.clock()))
				Fn.addPhoneCard(shipment.Item, string.format("%02ds", secondsLeft), function()
					Fn.showToast("WAIT FOR THE BUYER'S PAYMENT", Theme.Lime)
				end)
			end
		end
	elseif currentPhoneTab == "UPGRADES" then
		Fn.addPhoneLabel("APP UPGRADES")
		Fn.addPhoneLabel("UPGRADE ANYTIME · EACH UPGRADE MAKES THE NEXT ONE MORE EXPENSIVE", true)

		local upgradeMultiplier = 1.5
		local upgrades = {
			{ Id = "QUICKSHIP", Name = "QUICKSHIP", Description = "Shorter delivery times", BaseCost = 700 },
			{ Id = "SAFEBOX", Name = "SAFEBOX", Description = "Lower lost-package chance", BaseCost = 900 },
			{ Id = "BOOSTER", Name = "BOOSTER", Description = "Better buyer reach", BaseCost = 1100 },
		}

		for _, upgrade in ipairs(upgrades) do
			local level = appUpgradeLevels[upgrade.Id] or 0
			local cost = math.floor(upgrade.BaseCost * (upgradeMultiplier ^ level))

			local row = Fn.create("Frame", {
				BackgroundColor3 = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 84),
				ZIndex = 12,
				Parent = phoneContent,
			}) :: Frame
			Fn.addCorner(row, 13)

			Fn.create("TextLabel", {
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

			Fn.create("TextLabel", {
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

			local buy = Fn.makeButton(row, "$" .. Fn.formatCoins(cost), UDim2.fromOffset(91, 35), coins >= cost)
			buy.AnchorPoint = Vector2.new(1, 0.5)
			buy.Position = UDim2.new(1, -12, 0.5, 0)
			buy.ZIndex = 14

			buy.MouseButton1Click:Connect(function()
				if coins < cost then
					Fn.showToast("NOT ENOUGH CASH", Theme.Danger)
					return
				end

				coins -= cost
				appUpgradeLevels[upgrade.Id] = level + 1
				cashLabel.Text = "$" .. Fn.formatCoins(coins)
				Fn.showToast(upgrade.Name .. " UPGRADED TO LV. " .. tostring(level + 1), Theme.Lime)
				Fn.refreshPhone()
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
		Fn.refreshPhone()
	end)
end

-- Home-screen app launcher is the main way to switch between FLIPTAG and ro-gram.
function Fn.openPhoneHome()
	Fn.setCameraActive(false)
	currentPhoneApp = "HOME"
	currentSocialTab = "FYP"
	currentPhoneTab = "LISTINGS"
	Fn.openWindow(phoneWindow)
	Fn.refreshPhone()
end

phoneDockButton.MouseButton1Click:Connect(Fn.openPhoneHome)

listButton.MouseButton1Click:Connect(function()
	if selectedItem.State ~= "Owned" then
		Fn.showToast("THIS ITEM CANNOT BE LISTED", Theme.Danger)
		return
	end
	Fn.openWindow(phoneWindow)
	currentPhoneApp = "FLIPTAG"
	currentPhoneTab = "LISTINGS"
	Fn.refreshPhone()
	Fn.showToast("POST " .. selectedItem.Name .. " FROM YOUR PHONE", Theme.Lime)
end)

inventoryButton.MouseButton1Click:Connect(function()
	Fn.openWindow(inventoryWindow)
	Fn.refreshInventory()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		Fn.openWindow(inventoryWindow)
		Fn.refreshInventory()
	elseif input.KeyCode == Enum.KeyCode.F then
		Fn.openWindow(fitWindow)
		Fn.refreshFit()
	elseif input.KeyCode == Enum.KeyCode.P then
		Fn.openPhoneHome()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		Fn.closeWindows()
	end
end)

task.spawn(function()
	while screenGui.Parent do
		task.wait(0.05)
		if cameraActive then
			Fn.updateCameraView()
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
			cashLabel.Text = "$" .. Fn.formatCoins(coins)
			Fn.showToast("SOCIAL INCOME: +$" .. Fn.formatCoins(passiveIncome), Theme.Lime)
		end
	end
end)

task.spawn(function()
	while screenGui.Parent do
		task.wait(1)
		local paidOut = false
		for index = #shipments, 1, -1 do
			local shipment = shipments[index]
			if shipment.FinishAt > 0 and os.clock() >= shipment.FinishAt then
				-- Packages can be lost during delivery. The SAFEBOX upgrade lowers the chance.
				local safeBoxLevel = appUpgradeLevels.SAFEBOX or 0
				local lostChance = math.max(0.02, 0.10 - (safeBoxLevel * 0.02))
				local wasLost = math.random() < lostChance

				if wasLost then
					shipment.Item.State = "Lost"
					table.remove(shipments, index)
					paidOut = true
					Fn.showToast("PACKAGE LOST: NO PAYMENT", Theme.Lime)
				else
					local soldItem = shipment.Item
					soldItem.State = "Sold"
					coins += soldItem.Value
					Fn.removeFromWardrobe(soldItem)
					table.remove(shipments, index)
					paidOut = true
					Fn.showToast("SOLD: +$" .. Fn.formatCoins(soldItem.Value), Theme.Lime)
				end
			end
		end
		if paidOut then
			Fn.refreshInventory()
			Fn.refreshFit()
			if phoneWindow.Visible and currentPhoneTab == "DELIVERIES" then
				Fn.refreshPhone()
			end
		end
		if phoneWindow.Visible and currentPhoneTab == "DELIVERIES" then
			Fn.refreshPhone()
		end
	end
end)

-- PACZKOMAT (parcel locker) ------------------------------------------------
-- Paczki wystawione na FLIPTAG NIE startują dostawy, dopóki gracz nie podejdzie
-- do paczkomatu i nie wciśnie E, żeby je odłożyć. Każdy gracz ma indywidualnie
-- 5 slotów; paczkomat odświeża się (zwalnia sloty) co 5 minut.

local ProximityPromptService = game:GetService("ProximityPromptService")

local PACZKOMAT_SLOTS = 5
local PACZKOMAT_REFRESH = 300 -- sekundy

local paczkomatModel = workspace:FindFirstChild("paczkomat")
local paczkomatPart = paczkomatModel and paczkomatModel:FindFirstChildWhichIsA("BasePart", true)

if paczkomatPart then
	local paczkomatSlotsUsed = 0
	local paczkomatNextRefresh = os.clock() + PACZKOMAT_REFRESH

	-- Billboard nad paczkomatem: zajęte sloty + czas do odświeżenia.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PaczkomatStatus"
	billboard.Size = UDim2.fromOffset(230, 96)
	billboard.StudsOffset = Vector3.new(0, paczkomatPart.Size.Y * 0.5 + 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	billboard.Parent = paczkomatPart

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Size = UDim2.fromScale(1, 1)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 16
	statusLabel.TextColor3 = Theme.Paper
	statusLabel.TextStrokeTransparency = 0.2
	statusLabel.Parent = billboard

	local function updatePaczkomatStatus()
		local secondsLeft = math.max(0, math.ceil(paczkomatNextRefresh - os.clock()))
		statusLabel.Text = string.format(
			"PACZKOMAT\nSLOTY: %d/%d\nODŚWIEŻENIE: %d:%02d",
			paczkomatSlotsUsed, PACZKOMAT_SLOTS, math.floor(secondsLeft / 60), secondsLeft % 60
		)
	end
	updatePaczkomatStatus()

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PaczkomatPrompt"
	prompt.ActionText = "ODŁÓŻ PACZKI"
	prompt.ObjectText = "PACZKOMAT"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = paczkomatPart

	ProximityPromptService.PromptTriggered:Connect(function(triggeredPrompt)
		if triggeredPrompt ~= prompt then return end

		local pending = Fn.countPendingShipments()
		if pending == 0 then
			Fn.showToast("NO PACKAGES TO DROP OFF", Theme.Danger)
			return
		end

		local freeSlots = PACZKOMAT_SLOTS - paczkomatSlotsUsed
		if freeSlots <= 0 then
			Fn.showToast("PACZKOMAT FULL — WAIT FOR REFRESH", Theme.Danger)
			return
		end

		local deposited = math.min(pending, freeSlots)
		local started = 0
		for _, shipment in ipairs(shipments) do
			if started >= deposited then break end
			if shipment.FinishAt == 0 then
				shipment.FinishAt = os.clock() + 18
				started += 1
			end
		end
		paczkomatSlotsUsed += deposited

		-- Zdejmij karton z rąk (serwer).
		local thriftRemotes = ReplicatedStorage:FindFirstChild("ThriftRemotes")
		local boxRemote = thriftRemotes and thriftRemotes:FindFirstChild("FlipTagBox")
		if boxRemote and boxRemote:IsA("RemoteEvent") then
			boxRemote:FireServer("deposit")
		end

		Fn.showToast("DEPOSITED " .. deposited .. " PACKAGE(S) — DELIVERY STARTED", Theme.Lime)
		updatePaczkomatStatus()
		if phoneWindow.Visible and currentPhoneTab == "DELIVERIES" then
			Fn.refreshPhone()
		end
	end)

	task.spawn(function()
		while screenGui.Parent do
			task.wait(1)
			if os.clock() >= paczkomatNextRefresh then
				paczkomatNextRefresh = os.clock() + PACZKOMAT_REFRESH
				if paczkomatSlotsUsed > 0 then
					paczkomatSlotsUsed = 0
					Fn.showToast("PACZKOMAT REFRESHED — SLOTS FREE", Theme.Lime)
				end
			end
			updatePaczkomatStatus()
		end
	end)
else
	warn("[ThriftUI] Brak modelu 'paczkomat' w Workspace")
end

-- RO-GRAM / TRADE SERVER SYNC ---------------------------------------------
function Fn.findInventoryItem(itemId: string): ClothingItem?
	for _, item in ipairs(inventory) do
		if item.Id == itemId then
			return item
		end
	end
	return nil
end

function Fn.registerOwnedInventory()
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

function Fn.resetTradeState()
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
		Fn.registerOwnedInventory()
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
				if phoneWindow.Visible and currentPhoneApp == "SOCIAL" then Fn.refreshPhone() end
			elseif action == "Deleted" and type(ownerName) == "string" and type(payload) == "string" then
				for index = #socialPhotos, 1, -1 do
					if socialPhotos[index].Owner == ownerName and socialPhotos[index].PhotoId == payload then
						table.remove(socialPhotos, index)
					end
				end
				if phoneWindow.Visible and currentPhoneApp == "SOCIAL" then Fn.refreshPhone() end
			end
		end)
	end

	if tradeRemote then
		tradeRemote.OnClientEvent:Connect(function(action, data, extra)
			if action == "RequestSent" then
				Fn.showToast("TRADE REQUEST SENT TO @" .. tostring(data), SocialTheme.Purple)
			elseif action == "IncomingRequest" then
				tradeIncomingFrom = tostring(data)
				profileName = tradeIncomingFrom
				currentSocialTab = "PROFILE"
				Fn.showToast("TRADE REQUEST FROM @" .. tradeIncomingFrom, SocialTheme.Purple)
				if phoneWindow.Visible and currentPhoneApp == "SOCIAL" then Fn.refreshPhone() end
			elseif action == "Declined" then
				Fn.showToast("TRADE DECLINED BY @" .. tostring(data), Theme.Danger)
				Fn.resetTradeState()
				if phoneWindow.Visible then Fn.refreshPhone() end
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
				Fn.showToast("TRADE OPEN WITH @" .. tradeTarget, SocialTheme.Purple)
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "Offer" then
				if type(data) == "table" then
					tradeTheirOffer = {}
					for _, id in ipairs(data) do if type(id) == "string" then table.insert(tradeTheirOffer, id) end end
				end
				tradeTheirReady = false
				tradeStatus = "OFFER UPDATED"
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "OfferConfirmed" then
				tradeMyOffer = {}
				if type(data) == "table" then
					for _, id in ipairs(data) do if type(id) == "string" then table.insert(tradeMyOffer, id) end end
				end
				tradeMyReady = false
				tradeStatus = "OFFER SENT"
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "Ready" then
				tradeTheirReady = data == true
				tradeStatus = if tradeTheirReady then "OTHER PLAYER READY" else "OTHER PLAYER NOT READY"
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "ReadyConfirmed" then
				tradeMyReady = data == true
				tradeStatus = if tradeMyReady then "YOU ARE READY" else "EDITING OFFER"
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "Completed" then
				local info = if type(data) == "table" then data else {}
				local receivedMap = if type(info.Received) == "table" then info.Received else {}
				local givenMap = if type(info.Given) == "table" then info.Given else {}
				local received = receivedMap[player.UserId]
				local given = givenMap[player.UserId]
				if type(given) == "table" then
					for _, id in ipairs(given) do
						if type(id) == "string" then
							local item = Fn.findInventoryItem(id)
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
							local item = Fn.findInventoryItem(id)
							if item then item.State = "Owned" end
						end
					end
				end
				Fn.showToast("TRADE COMPLETE", SocialTheme.Purple)
				Fn.resetTradeState()
				Fn.registerOwnedInventory()
				Fn.refreshInventory()
				Fn.refreshFit()
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "Cancelled" then
				Fn.showToast("TRADE CANCELLED", Theme.Muted)
				Fn.resetTradeState()
				if phoneWindow.Visible then Fn.refreshPhone() end
			elseif action == "Error" then
				Fn.showToast(tostring(data), Theme.Danger)
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
	local luckRemote = remotes:WaitForChild("RollLuckUpdate")
	rollState.Remote = rackRemote
	if luckRemote:IsA("RemoteEvent") then
		rollState.LuckRemote = luckRemote
	end

	if not remote:IsA("RemoteEvent") or not rackRemote:IsA("RemoteEvent") or not luckRemote:IsA("RemoteEvent") then
		return
	end
	Fn.refreshInventory()

	-- Okragly wieszak: serwer najpierw proponuje wylosowany item za $100.
	-- Poniewaz obecny prototyp przechowuje coins lokalnie, platnosc jest
	-- odejmowana tutaj, a dopiero potem serwer zatwierdza wygrana.
	rackRemote.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and payload.Type == "Depleted" then
			rollState.Auto = false
			rollState.Source = nil
			local secs = tonumber(payload.RefillIn) or 600
			local mins = math.max(1, math.floor(secs / 60))
			Fn.showToast("OUT OF STOCK - REFILL IN " .. mins .. " MIN", Theme.Danger)
			return
		end
		if type(payload) ~= "table" or payload.Type ~= "Offer" then
			return
		end
		if rollState.Active then
			rackRemote:FireServer("Cancel")
			return
		end
		local price = tonumber(payload.Price) or 100
		if coins < price then
			rollState.Auto = false
			rollState.Source = nil
			Fn.showToast("NOT ENOUGH CASH - NEED $" .. Fn.formatCoins(price), Theme.Danger)
			rackRemote:FireServer("Cancel")
			return
		end

		rollState.Source = tostring(payload.Source or "")
		rollState.Price = price
		coins -= price
		cashLabel.Text = "$" .. Fn.formatCoins(coins)
		Fn.showToast(string.upper(tostring(payload.Source or "CLOTHING ROLL")) .. ": -$" .. Fn.formatCoins(price), Theme.Muted)

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
		if rollState.Active then
			return
		end
		rollState.Source = if payload.Source ~= nil then tostring(payload.Source) else nil
		rollState.Price = tonumber(payload.Price) or 0
		rollState.Active = true
		task.spawn(function()
			local ok, errorMessage = pcall(Fn.animateClothingRoll, payload.Item)
			rollState.Active = false
			if not ok then
				warn("[ThriftUI] Clothing roll error:", errorMessage)
				Fn.showToast("CLOTHING ROLL FAILED", Theme.Danger)
			end
		end)
		Fn.registerOwnedInventory()

		if payload.UnlockMessage then
			task.delay(3.8, function()
				Fn.showToast(string.upper(tostring(payload.UnlockMessage)), Theme.Lime)
			end)
		end
	end)
end)

Fn.refreshInventory()
Fn.refreshFit()
currentPhoneApp = "HOME"
Fn.refreshPhone()
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
Fn.showToast("WELCOME TO THRIFT//RUN", Theme.Lime)
