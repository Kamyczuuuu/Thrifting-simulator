local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:FindFirstChild("ThriftRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "ThriftRemotes"
	remotes.Parent = ReplicatedStorage
end

local clothingFound = remotes:FindFirstChild("ClothingFound")
if not clothingFound then
	clothingFound = Instance.new("RemoteEvent")
	clothingFound.Name = "ClothingFound"
	clothingFound.Parent = remotes
end

local rackRoll = remotes:FindFirstChild("RoundRackRoll")
if not rackRoll then
	rackRoll = Instance.new("RemoteEvent")
	rackRoll.Name = "RoundRackRoll"
	rackRoll.Parent = remotes
end

local luckUpdate = remotes:FindFirstChild("RollLuckUpdate")
if not luckUpdate then
	luckUpdate = Instance.new("RemoteEvent")
	luckUpdate.Name = "RollLuckUpdate"
	luckUpdate.Parent = remotes
end

local random = Random.new()
local pendingOffers = {}
local lastUse = {}
local playerLuck = {}
local rarityLuck = {
	Common = 0,
	Uncommon = 0.1,
	Rare = 0.25,
	Epic = 0.5,
	Grail = 1,
	Limited = 1.5,
	Legendary = 2,
	Mythic = 3,
	Secret = 5,
}

luckUpdate.OnServerEvent:Connect(function(player, luck)
	if type(luck) ~= "number" then return end
	playerLuck[player] = math.clamp(luck, 0, 20)
end)

local function item(id, name, brand, category, style, rarity, value, visual, unlock, image)
	return {
		Id = id,
		Name = name,
		Brand = brand,
		Category = category,
		Style = style,
		Rarity = rarity,
		Value = value,
		Visual = visual,
		Unlock = unlock or 0,
		Image = image,
	}
end

local binLoot = {
	item("bin_rough_blank", "Rough Blank Tee", "Basefile", "Top", "Street", "Common", 8, "WORN TEE"),
	item("bin_faded_zip", "Faded Zip Hoodie", "Last Call", "Top", "Vintage", "Common", 16, "ZIP HOODIE"),
	item("bin_straight_jeans", "Thrifted Straight Jeans", "Rivet", "Bottom", "Vintage", "Common", 14, "STRAIGHT DENIM"),
	item("bin_loose_sweats", "Loose Sweatpants", "Basefile", "Bottom", "Sport", "Common", 11, "SWEATPANTS"),
	item("bin_canvas", "Scuffed Canvas Shoes", "Nice", "Shoes", "Skate", "Common", 18, "LOW-TOPS"),
	item("bin_cap", "Washed Dad Cap", "Kabel 04", "Head", "Street", "Common", 7, "CAP"),
}

local common = {
	item("rack_basic_tee", "Faded Heavy Tee", "Last Call", "Top", "Street", "Common", 28, "HEAVY TEE"),
	item("rack_vintage_tee", "Vintage Print Tee", "Basefile", "Top", "Vintage", "Common", 34, "PRINT TEE"),
	item("rack_worn_denim", "Worn Straight Denim", "Rivet", "Bottom", "Vintage", "Common", 39, "STRAIGHT DENIM"),
	item("rack_track_pants", "Track Pants", "Northline", "Bottom", "Sport", "Common", 32, "TRACK PANTS"),
}
local uncommon = {
	item("rack_zip", "Heavy Zip Hoodie", "Archive", "Top", "Y2K", "Uncommon", 120, "ZIP HOODIE"),
	item("rack_cargo", "Loose Cargo Pants", "Nox", "Bottom", "Utility", "Uncommon", 135, "CARGO PANTS"),
	item("rack_work_jacket", "Workwear Jacket", "Field Dept.", "Top", "Workwear", "Uncommon", 165, "WORK JACKET"),
	item("rack_blue_tshirt", "Blue T-Shirt", "Blue Hour", "Top", "Street", "Uncommon", 95, "BLUE T-SHIRT", nil, "rbxassetid://87365206745199"),
}
local rare = {
	item("rack_varsity", "Vintage Varsity Jacket", "Eastline", "Top", "Archive", "Rare", 420, "VARSITY"),
	item("rack_denim_jacket", "Faded Denim Jacket", "Rivet", "Top", "Vintage", "Rare", 460, "DENIM JACKET"),
}
local epic = {
	item("rack_leather", "Distressed Leather Jacket", "Noir Supply", "Top", "Archive", "Epic", 850, "LEATHER JACKET", 5),
	item("rack_wide_denim", "Wide Archive Denim", "Nox Denim", "Bottom", "Archive", "Epic", 760, "WIDE DENIM", 5),
}
local grail = {
	item("rack_bomber", "Archive Flight Bomber", "Aero 97", "Top", "Archive", "Grail", 2200, "ARCHIVE BOMBER", 10),
	item("rack_boots", "Stacked Archive Boots", "Bick Bowens", "Shoes", "Archive", "Grail", 3200, "STACK BOOTS", 10),
}
local limited = {
	item("rack_limited_tee", "One-Off Racing Tee", "Rogue Archive", "Top", "Limited", "Limited", 5000, "ONE-OFF TEE", 15),
}

local legendary = {
	item("mannequin_legendary_jacket", "Museum Varsity Jacket", "Eastline Archive", "Top", "Vintage", "Legendary", 9000, "VARSITY JACKET"),
}
local mythic = {
	item("mannequin_mythic_hoodie", "Rare Atelier Hoodie", "Noir Supply", "Top", "Archive", "Mythic", 18000, "ATELIER HOODIE"),
}
local secret = {
	item("mannequin_secret_piece", "One-of-One Archive Piece", "Blue Hour Atelier", "Top", "Limited", "Secret", 50000, "ONE-OF-ONE PIECE"),
}

local basketLoot = { Common = common, Uncommon = uncommon }
local rackLoot = { Common = common, Uncommon = uncommon, Rare = rare, Epic = epic }
local mannequinLoot = {
	Rare = rare,
	Epic = epic,
	Grail = grail,
	Limited = limited,
	Legendary = legendary,
	Mythic = mythic,
	Secret = secret,
}

local function choose(list)
	return list[random:NextInteger(1, #list)]
end

local function chooseRackLoot(player)
	local roll = random:NextNumber(0, 100) + (playerLuck[player] or 0)
	if roll <= 55 then return table.clone(choose(rackLoot.Common)) end
	if roll <= 85 then return table.clone(choose(rackLoot.Uncommon)) end
	if roll <= 97 then return table.clone(choose(rackLoot.Rare)) end
	return table.clone(choose(rackLoot.Epic))
end

local function chooseBasketLoot(player)
	local roll = random:NextNumber(0, 100) + (playerLuck[player] or 0)
	if roll <= 75 then return table.clone(choose(basketLoot.Common)) end
	return table.clone(choose(basketLoot.Uncommon))
end

local function chooseMannequinLoot(player)
	local roll = random:NextNumber(0, 100) + (playerLuck[player] or 0)
	if roll <= 35 then return table.clone(choose(mannequinLoot.Rare)) end
	if roll <= 60 then return table.clone(choose(mannequinLoot.Epic)) end
	if roll <= 80 then return table.clone(choose(mannequinLoot.Grail)) end
	if roll <= 90 then return table.clone(choose(mannequinLoot.Limited)) end
	if roll <= 97 then return table.clone(choose(mannequinLoot.Legendary)) end
	if roll <= 99 then return table.clone(choose(mannequinLoot.Mythic)) end
	return table.clone(choose(mannequinLoot.Secret))
end

local function anchorObject(target)
	if target:IsA("BasePart") then
		target.Anchored = true
		target.AssemblyLinearVelocity = Vector3.zero
		target.AssemblyAngularVelocity = Vector3.zero
	end

	for _, descendant in ipairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function addPrompt(target, actionText, objectText, callback)
	anchorObject(target)

	local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
	local geometry = model or target
	if target:IsA("Folder") then
		geometry = target:FindFirstChildWhichIsA("Model", true) or target:FindFirstChildWhichIsA("BasePart", true)
		model = target
	end
	if not geometry then
		warn("[ClothingModels] Model nie zawiera BasePart:", target:GetFullName())
		return
	end

	local anchor = model:FindFirstChild("InteractionPoint")
	if not anchor then
		anchor = Instance.new("Part")
		anchor.Name = "InteractionPoint"
		anchor.Size = Vector3.new(5, 3, 3)
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanTouch = false
		anchor.CanQuery = false
		anchor.Parent = model
	end

	local mainPart = geometry:IsA("BasePart") and geometry or nil
	local largestVolume = mainPart and mainPart.Size.X * mainPart.Size.Y * mainPart.Size.Z or 0
	if not mainPart then
		for _, descendant in ipairs(geometry:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
				if volume > largestVolume then
					mainPart = descendant
					largestVolume = volume
				end
			end
		end
	end
	if mainPart then
		anchor.CFrame = mainPart.CFrame
	else
		anchor.CFrame = geometry:GetPivot()
	end

	local nameTag = anchor:FindFirstChild("ModelNameTag")
	if not nameTag then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ModelNameTag"
		billboard.Size = UDim2.fromOffset(220, 42)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 45
		billboard.Adornee = anchor
		billboard.Parent = anchor

		local tagFrame = Instance.new("Frame")
		tagFrame.Name = "TagFrame"
		tagFrame.Size = UDim2.fromScale(1, 1)
		tagFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tagFrame.BackgroundTransparency = 0.05
		tagFrame.BorderSizePixel = 0
		tagFrame.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = tagFrame

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(15, 48, 78)
		stroke.Thickness = 3
		stroke.Parent = tagFrame

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -14, 1, 0)
		label.Position = UDim2.fromOffset(7, 0)
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(15, 48, 78)
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = tagFrame
		nameTag = billboard
	end
	local tagLabel = nameTag:FindFirstChild("TagFrame") and nameTag.TagFrame:FindFirstChild("Label")
	if tagLabel and tagLabel:IsA("TextLabel") then
		tagLabel.Text = objectText
	end

	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = anchor
	end
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(callback)
end

local connected = {}
local paidModelRolls = {}
local freeModelRolls = {}

local binNames = { "bin", "Bin", "ClothingBIn", "ClothingBin", "CubeClothingDonationBin" }
local basketNames = { "koszyk", "Koszyk", "basket", "Basket", "ClothingBasket" }
local rackNames = { "rack", "Rack", "ClothingRack", "CubeRoundClothingRack", "RoundThriftRack" }
local mannequinNames = { "manekin", "Manekin", "mannequin", "Mannequin", "ClothingMannequin" }

local function makeOfferId(found, player, now)
	found.Id = string.format("%s_%d_%d", found.Id, player.UserId, math.floor(now * 1000))
	return found
end

local function sendPaidOffer(player, source, price, chooseLoot, ignoreCooldown)
	local now = os.clock()
	if not ignoreCooldown and lastUse[player] and now - lastUse[player] < 1 then return end
	if pendingOffers[player] then return end
	lastUse[player] = now
	local found = makeOfferId(table.clone(chooseLoot(player)), player, now)
	pendingOffers[player] = { Item = found, Price = price, Source = source }
	rackRoll:FireClient(player, {
		Type = "Offer",
		Item = found,
		Price = price,
		Source = source,
	})
end

local function connectBin(bin)
	if connected[bin] then return end
	connected[bin] = true
	freeModelRolls["Clothing Donation Bin"] = function()
		return choose(binLoot)
	end
	addPrompt(bin, "Search (Free)", "Clothing Donation Bin", function(player)
		local now = os.clock()
		if lastUse[player] and now - lastUse[player] < 1 then return end
		lastUse[player] = now
		local found = makeOfferId(table.clone(choose(binLoot)), player, now)
		clothingFound:FireClient(player, { Type = "Found", Item = found, Price = 0, Source = "Clothing Donation Bin" })
	end)
	print("[ClothingModels] Bin connected:", bin:GetFullName())
end

local function connectPaidModel(target, actionText, objectText, price, chooseLoot)
	if connected[target] then return end
	connected[target] = true
	paidModelRolls[objectText] = { Price = price, ChooseLoot = chooseLoot }
	addPrompt(target, actionText, objectText, function(player)
		sendPaidOffer(player, objectText, price, chooseLoot)
	end)
	print("[ClothingModels] Paid model connected:", target:GetFullName(), price)
end

local function connectBasket(basket)
	connectPaidModel(basket, "Roll clothing ($100)", "Clothing Basket", 100, chooseBasketLoot)
end

local function connectRack(rack)
	connectPaidModel(rack, "Roll clothing ($1,000)", "Clothing Rack", 1000, chooseRackLoot)
end

local function connectMannequin(mannequin)
	connectPaidModel(mannequin, "Roll clothing ($10,000)", "Mannequin", 10000, chooseMannequinLoot)
end

local function tryConnect(object)
	local objectName = string.lower(object.Name)
	for _, name in ipairs(binNames) do
		if objectName == string.lower(name) then
			connectBin(object)
			return
		end
	end
	for _, name in ipairs(rackNames) do
		if objectName == string.lower(name) then
			connectRack(object)
			return
		end
	end
	for _, name in ipairs(basketNames) do
		if objectName == string.lower(name) then
			connectBasket(object)
			return
		end
	end
	for _, name in ipairs(mannequinNames) do
		if objectName == string.lower(name) then
			connectMannequin(object)
			return
		end
	end
end

-- Bind existing models and also models generated later during Play.
for _, object in ipairs(Workspace:GetDescendants()) do
	tryConnect(object)
end
Workspace.DescendantAdded:Connect(function(object)
	task.defer(tryConnect, object)
end)

rackRoll.OnServerEvent:Connect(function(player, action, source)
	if action == "AutoRoll" then
		local roll = paidModelRolls[tostring(source)]
		if roll then
			sendPaidOffer(player, tostring(source), roll.Price, roll.ChooseLoot, true)
			return
		end
		local chooseFreeLoot = freeModelRolls[tostring(source)]
		if chooseFreeLoot then
			local now = os.clock()
			if lastUse[player] and now - lastUse[player] < 1 then return end
			lastUse[player] = now
			local found = makeOfferId(table.clone(chooseFreeLoot(player)), player, now)
			clothingFound:FireClient(player, {
				Type = "Found",
				Item = found,
				Price = 0,
				Source = tostring(source),
			})
		end
		return
	end
	if action ~= "Confirm" and action ~= "Cancel" then return end
	local offer = pendingOffers[player]
	if not offer then return end
	pendingOffers[player] = nil
	if action == "Cancel" then return end
	clothingFound:FireClient(player, {
		Type = "Found",
		Item = offer.Item,
		Price = offer.Price,
		Source = offer.Source,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	pendingOffers[player] = nil
	lastUse[player] = nil
	playerLuck[player] = nil
end)
