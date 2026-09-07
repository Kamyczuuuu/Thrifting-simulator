--==================================================
-- THRIFTING SIMULATOR
-- KOSZ NA UŻYWANE UBRANIA
--==================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BIN_NAME = "StarterDonationBin"
local BIN_POSITION = Vector3.new(0, 0, -18)

local random = Random.new()

--==================================================
-- REMOTE EVENTS
--==================================================

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)

	if existing then
		return existing
	end

	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent

	return object
end

local remotes = getOrCreate(
	ReplicatedStorage,
	"Folder",
	"ThriftRemotes"
)

local clothingFoundEvent = getOrCreate(
	remotes,
	"RemoteEvent",
	"ClothingFound"
)

--==================================================
-- LOOT
--==================================================

local commonFinds = {

	{
		Id = "bin_rough_blank",
		Name = "Rough Blank Tee",
		Brand = "Basefile",
		Category = "Top",
		Style = "Street",
		Rarity = "Common",
		Value = 8,
		Visual = "WORN TEE"
	},

	{
		Id = "bin_faded_zip",
		Name = "Faded Zip Hoodie",
		Brand = "Last Call",
		Category = "Top",
		Style = "Vintage",
		Rarity = "Common",
		Value = 16,
		Visual = "ZIP HOODIE"
	},

	{
		Id = "bin_straight_jeans",
		Name = "Thrifted Straight Jeans",
		Brand = "Rivet",
		Category = "Bottom",
		Style = "Vintage",
		Rarity = "Common",
		Value = 14,
		Visual = "STRAIGHT DENIM"
	},

	{
		Id = "bin_loose_sweats",
		Name = "Loose Sweatpants",
		Brand = "Basefile",
		Category = "Bottom",
		Style = "Sport",
		Rarity = "Common",
		Value = 11,
		Visual = "SWEATPANTS"
	},

	{
		Id = "bin_canvas",
		Name = "Scuffed Canvas Shoes",
		Brand = "Nice",
		Category = "Shoes",
		Style = "Skate",
		Rarity = "Common",
		Value = 18,
		Visual = "LOW-TOP"
	},

	{
		Id = "bin_cap",
		Name = "Washed Dad Cap",
		Brand = "Kabel 04",
		Category = "Head",
		Style = "Street",
		Rarity = "Common",
		Value = 7,
		Visual = "CAP"
	},
}

--==================================================
-- COLORS
--==================================================

local GREEN = Color3.fromRGB(27, 165, 75)
local DARK_GREEN = Color3.fromRGB(10, 95, 43)
local LIGHT_GREEN = Color3.fromRGB(52, 190, 88)

local VERY_DARK = Color3.fromRGB(5, 20, 12)
local BLACK = Color3.fromRGB(2, 8, 5)

local METAL = Color3.fromRGB(70, 75, 72)
local DARK_METAL = Color3.fromRGB(35, 40, 37)

local WHITE = Color3.fromRGB(245, 255, 248)

--==================================================
-- PART CREATOR
--==================================================

local function makePart(
	parent,
	name,
	size,
	position,
	color,
	material,
	transparency
)

	local part = Instance.new("Part")

	part.Name = name

	part.Anchored = true
	part.CanCollide = true
	part.CastShadow = true

	part.Size = size
	part.Position = position

	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic

	part.Transparency = transparency or 0

	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	part.Parent = parent

	return part
end

--==================================================
-- WEDGE CREATOR
--==================================================

local function makeWedge(
	parent,
	name,
	size,
	position,
	color,
	material
)

	local wedge = Instance.new("WedgePart")

	wedge.Name = name

	wedge.Anchored = true
	wedge.CanCollide = true
	wedge.CastShadow = true

	wedge.Size = size
	wedge.Position = position

	wedge.Color = color
	wedge.Material = material or Enum.Material.SmoothPlastic

	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth

	wedge.Parent = parent

	return wedge
end

--==================================================
-- BOLT
--==================================================

local function makeBolt(parent, position)

	local bolt = makePart(
		parent,
		"Bolt",
		Vector3.new(0.18, 0.18, 0.12),
		position,
		DARK_METAL,
		Enum.Material.Metal
	)

	bolt.Shape = Enum.PartType.Cylinder

	bolt.CFrame =
		CFrame.new(position)
		* CFrame.Angles(0, math.rad(90), 0)

	return bolt
end

--==================================================
-- TEXT LABEL
--==================================================

local function createText(
	parent,
	name,
	text,
	position,
	size,
	textSize
)

	local gui = Instance.new("SurfaceGui")

	gui.Name = name
	gui.Face = Enum.NormalId.Front

	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45

	gui.Parent = parent

	local label = Instance.new("TextLabel")

	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)

	label.Text = text

	label.Font = Enum.Font.GothamBold
	label.TextScaled = false
	label.TextSize = textSize

	label.TextColor3 = WHITE
	label.TextStrokeColor3 = DARK_GREEN
	label.TextStrokeTransparency = 0.7

	label.TextWrapped = true

	label.Parent = gui

	return gui
end

--==================================================
-- BUILD BIN
--==================================================

local function buildDonationBin()

	-- Usuń poprzednią wersję
	local existing = workspace:FindFirstChild(BIN_NAME)

	if existing then
		existing:Destroy()
	end

	-- Model
	local model = Instance.new("Model")
	model.Name = BIN_NAME
	model.Parent = workspace

	--==================================================
	-- WYMIARY
	--==================================================

	local W = 7.5
	local H = 9
	local D = 4.8

	local x = BIN_POSITION.X
	local y = BIN_POSITION.Y
	local z = BIN_POSITION.Z

	--==================================================
	-- GŁÓWNY KORPUS
	--==================================================

	local body = makePart(
		model,
		"MainBody",
		Vector3.new(W, H, D),
		Vector3.new(x, y + H / 2, z),
		GREEN,
		Enum.Material.Metal
	)

--==================================================
	-- BOKI (Naprawiony Z-fighting przez lekkie wysunięcie)
	--==================================================

	local sideThickness = 0.22
	local offset = 0.02 -- Lekki odstęp, by ściany na siebie nie nachodziły

	makePart(
		model,
		"LeftSide",
		Vector3.new(sideThickness, H + 0.25, D + 0.15),
		Vector3.new(x - W / 2 - (sideThickness / 2) - offset, y + H / 2, z),
		DARK_GREEN,
		Enum.Material.Metal
	)

	makePart(
		model,
		"RightSide",
		Vector3.new(sideThickness, H + 0.25, D + 0.15),
		Vector3.new(x + W / 2 + (sideThickness / 2) + offset, y + H / 2, z),
		DARK_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- DÓŁ (Naprawiony Z-fighting przez wysunięcie w dół i lekki offset)
	--==================================================

	local bottomThickness = 0.25
	local offset = 0.02 -- Lekki odstęp, by ściany na siebie nie nachodziły

	makePart(
		model,
		"Bottom",
		Vector3.new(W + 0.1, bottomThickness, D + 0.1),
		Vector3.new(x, y - (bottomThickness / 2) - offset, z),
		DARK_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- GÓRNA CZĘŚĆ
	--==================================================

	makePart(
		model,
		"Top",
		Vector3.new(W + 0.25, 0.35, D + 0.2),
		Vector3.new(x, y + H + 0.15, z),
		LIGHT_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- GÓRNY DACH / DASZEK
	--==================================================

	makePart(
		model,
		"TopFrontLip",
		Vector3.new(W + 0.2, 0.45, 0.35),
		Vector3.new(x, y + H - 0.05, z - D / 2 - 0.05),
		DARK_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- OTWÓR WRZUTOWY
	--==================================================

	local openingWidth = 6.3
	local openingHeight = 2.7

	-- czarne wnętrze
	makePart(
		model,
		"OpeningDarkness",
		Vector3.new(openingWidth, openingHeight, 0.25),
		Vector3.new(
			x,
			y + H - 1.75,
			z - D / 2 - 0.13
		),
		BLACK,
		Enum.Material.SmoothPlastic
	)

	--==================================================
	-- RAMKA OTWORU
	--==================================================

	makePart(
		model,
		"OpeningLeftFrame",
		Vector3.new(0.25, openingHeight + 0.3, 0.35),
		Vector3.new(
			x - openingWidth / 2,
			y + H - 1.75,
			z - D / 2 - 0.25
		),
		DARK_GREEN,
		Enum.Material.Metal
	)

	makePart(
		model,
		"OpeningRightFrame",
		Vector3.new(0.25, openingHeight + 0.3, 0.35),
		Vector3.new(
			x + openingWidth / 2,
			y + H - 1.75,
			z - D / 2 - 0.25
		),
		DARK_GREEN,
		Enum.Material.Metal
	)

	makePart(
		model,
		"OpeningTopFrame",
		Vector3.new(openingWidth, 0.28, 0.35),
		Vector3.new(
			x,
			y + H - 0.38,
			z - D / 2 - 0.25
		),
		DARK_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- POCHYLONA PÓŁKA WEWNĄTRZ
	--==================================================

	local chute = makePart(
		model,
		"ClothingChute",
		Vector3.new(6.1, 0.22, 2.25),
		Vector3.new(
			x,
			y + H - 3.05,
			z - D / 2 - 0.65
		),
		GREEN,
		Enum.Material.Metal
	)

	chute.CFrame =
		CFrame.new(chute.Position)
		* CFrame.Angles(math.rad(-8), 0, 0)

	--==================================================
	-- TYLNA ŚCIANA W OTWORZE
	--==================================================

	makePart(
		model,
		"OpeningBack",
		Vector3.new(6.1, 2.25, 0.2),
		Vector3.new(
			x,
			y + H - 2.0,
			z - 0.65
		),
		DARK_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- KLAPA / DRZWICZKI WRZUTOWE
	--==================================================

	local flap = makePart(
		model,
		"DropFlap",
		Vector3.new(6.2, 0.25, 1.0),
		Vector3.new(
			x,
			y + H - 3.0,
			z - D / 2 - 0.75
		),
		LIGHT_GREEN,
		Enum.Material.Metal
	)

	flap.CFrame =
		CFrame.new(flap.Position)
		* CFrame.Angles(math.rad(-12), 0, 0)

	--==================================================
	-- DOLNY PANEL
	--==================================================

	makePart(
		model,
		"LowerPanel",
		Vector3.new(W - 0.25, 2.65, 0.25),
		Vector3.new(
			x,
			y + 1.85,
			z - D / 2 - 0.15
		),
		GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- ŚRODKOWA LISTWA
	--==================================================

	makePart(
		model,
		"MiddleBar",
		Vector3.new(W - 0.15, 0.28, 0.35),
		Vector3.new(
			x,
			y + 4.35,
			z - D / 2 - 0.2
		),
		DARK_GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- NAPIS
	--==================================================

	local sign = makePart(
		model,
		"DonationLabel",
		Vector3.new(6.9, 1.7, 0.08),
		Vector3.new(
			x,
			y + 3.25,
			z - D / 2 - 0.32
		),
		WHITE,
		Enum.Material.SmoothPlastic
	)

	createText(
		sign,
		"ClothingDonationsText",
		"CLOTHING\nDONATIONS",
		sign.Position,
		sign.Size,
		38
	)

	--==================================================
	-- MAŁY NAPIS
	--==================================================

	local infoPanel = makePart(
		model,
		"InfoPanel",
		Vector3.new(6.7, 0.9, 0.08),
		Vector3.new(
			x,
			y + 1.35,
			z - D / 2 - 0.33
		),
		GREEN,
		Enum.Material.SmoothPlastic
	)

	createText(
		infoPanel,
		"InfoText",
		"USED CLOTHING • SHOES • TEXTILES",
		infoPanel.Position,
		infoPanel.Size,
		15
	)

	--==================================================
	-- SYMBOL RECYKLINGU
	--==================================================

	local recyclePanel = makePart(
		model,
		"RecyclePanel",
		Vector3.new(1.3, 1.1, 0.08),
		Vector3.new(
			x,
			y + 5.25,
			z - D / 2 - 0.3
		),
		GREEN,
		Enum.Material.SmoothPlastic
	)

	createText(
		recyclePanel,
		"RecycleSymbol",
		"♻",
		recyclePanel.Position,
		recyclePanel.Size,
		45
	)

	--==================================================
	-- ŚRUBY / NITY
	--==================================================

	local frontZ = z - D / 2 - 0.42

	local boltPositions = {

		Vector3.new(x - W / 2 + 0.38, y + 7.8, frontZ),
		Vector3.new(x + W / 2 - 0.38, y + 7.8, frontZ),

		Vector3.new(x - W / 2 + 0.38, y + 4.6, frontZ),
		Vector3.new(x + W / 2 - 0.38, y + 4.6, frontZ),

		Vector3.new(x - W / 2 + 0.38, y + 0.55, frontZ),
		Vector3.new(x + W / 2 - 0.38, y + 0.55, frontZ),
	}

	for _, position in ipairs(boltPositions) do
		makeBolt(model, position)
	end

	--==================================================
	-- ZAWIASY KLAPY
	--==================================================

	makeBolt(
		model,
		Vector3.new(
			x - 2.6,
			y + H - 3.0,
			frontZ
		)
	)

	makeBolt(
		model,
		Vector3.new(
			x + 2.6,
			y + H - 3.0,
			frontZ
		)
	)

	--==================================================
	-- BOCZNE MAŁE DRZWICZKI
	--==================================================

	local sideDoor = makePart(
		model,
		"SideDoor",
		Vector3.new(0.08, 1.3, 1.8),
		Vector3.new(
			x + W / 2 + 0.13,
			y + 2.3,
			z
		),
		GREEN,
		Enum.Material.Metal
	)

	--==================================================
	-- NÓŻKI
	--==================================================

	local legHeight = 0.65

	local legPositions = {
		Vector3.new(x - W / 2 + 0.3, y - legHeight / 2, z - D / 2 + 0.3),
		Vector3.new(x + W / 2 - 0.3, y - legHeight / 2, z - D / 2 + 0.3),
		Vector3.new(x - W / 2 + 0.3, y - legHeight / 2, z + D / 2 - 0.3),
		Vector3.new(x + W / 2 - 0.3, y - legHeight / 2, z + D / 2 - 0.3),
	}

	for _, position in ipairs(legPositions) do

		makePart(
			model,
			"Leg",
			Vector3.new(0.3, legHeight, 0.35),
			position,
			DARK_GREEN,
			Enum.Material.Metal
		)

	end

	--==================================================
	-- INTERACTION
	--==================================================

	local promptAnchor = makePart(
		model,
		"SearchPoint",
		Vector3.new(6.5, 2.5, 2),
		Vector3.new(
			x,
			y + 6.8,
			z - 3
		),
		Color3.new(0, 0, 0),
		Enum.Material.SmoothPlastic,
		1
	)

	promptAnchor.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")

	prompt.Name = "SearchPrompt"

	prompt.ActionText = "Search"
	prompt.ObjectText = "Clothing Donation Bin"

	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX

	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 10

	prompt.RequiresLineOfSight = false

	prompt.Parent = promptAnchor

	--==================================================
	-- LOSOWANIE UBRANIA
	--==================================================

	prompt.Triggered:Connect(function(player)

		local now = os.clock()

		local found =
			commonFinds[
				random:NextInteger(
					1,
					#commonFinds
				)
			]

		local item = table.clone(found)

		item.Id = string.format(
			"%s_%d_%d",
			item.Id,
			player.UserId,
			math.floor(now * 1000)
		)

		clothingFoundEvent:FireClient(
			player,
			{
				Type = "Found",
				Item = item
			}
		)

	end)

	--==================================================
	-- PRIMARY PART
	--==================================================

	model.PrimaryPart = body

	print("Donation bin created successfully!")

	return model
end

--==================================================
-- START
--==================================================

buildDonationBin()