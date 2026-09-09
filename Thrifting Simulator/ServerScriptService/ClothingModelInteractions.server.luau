local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

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

local PRICE = 100
local random = Random.new()
local pendingOffers = {}
local lastUse = {}

local function item(id, name, brand, category, style, rarity, value, visual, unlock)
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

local spins = {}

local function choose(list)
	return list[random:NextInteger(1, #list)]
end

local function chooseRackLoot(spin)
	local roll = random:NextNumber(0, 100)
	if spin < 5 then
		if roll <= 62 then return table.clone(choose(common)) end
		if roll <= 88 then return table.clone(choose(uncommon)) end
		return table.clone(choose(rare))
	elseif spin < 10 then
		if roll <= 52 then return table.clone(choose(common)) end
		if roll <= 80 then return table.clone(choose(uncommon)) end
		if roll <= 95 then return table.clone(choose(rare)) end
		return table.clone(choose(epic))
	elseif spin < 15 then
		if roll <= 46 then return table.clone(choose(common)) end
		if roll <= 74 then return table.clone(choose(uncommon)) end
		if roll <= 92 then return table.clone(choose(rare)) end
		return table.clone(choose(grail))
	else
		if roll <= 40 then return table.clone(choose(common)) end
		if roll <= 68 then return table.clone(choose(uncommon)) end
		if roll <= 87 then return table.clone(choose(rare)) end
		if roll <= 97 then return table.clone(choose(grail)) end
		return table.clone(choose(limited))
	end
end

local function unlockText(spin)
	if spin == 5 then return "NEW CLOTHES UNLOCKED: EPIC" end
	if spin == 10 then return "NEW CLOTHES UNLOCKED: GRAIL" end
	if spin == 15 then return "NEW CLOTHES UNLOCKED: LIMITED" end
	return nil
end

local function findModel(names)
	local roots = {
		Workspace:FindFirstChild("Modele"),
		Workspace:FindFirstChild("modele"),
		Workspace,
		ReplicatedStorage:FindFirstChild("Modele"),
		ReplicatedStorage:FindFirstChild("modele"),
		ServerStorage:FindFirstChild("Modele"),
		ServerStorage:FindFirstChild("modele"),
	}
	for _, root in roots do
		if root then
			for _, descendant in root:GetDescendants() do
				local descendantName = string.lower(descendant.Name)
				local matchesName = false
				for _, name in names do
					if descendantName == string.lower(name) then
						matchesName = true
						break
					end
				end
				if matchesName and (descendant:IsA("Model") or descendant:IsA("BasePart") or descendant:IsA("Folder")) then
					local found = descendant
					if not found:IsDescendantOf(Workspace) then
						found = found:Clone()
						found.Parent = Workspace
					end
					return found
				end
			end
		end
	end
	return nil
end

local function addPrompt(target, actionText, objectText, callback)
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
		local pivot = geometry:GetPivot()
		local depth = geometry:IsA("BasePart") and geometry.Size.Z or geometry:GetExtentsSize().Z
		anchor.CFrame = pivot * CFrame.new(0, 2, -math.max(depth / 2, 2.5))
		anchor.Parent = model
	end

	local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = actionText
		prompt.ObjectText = objectText
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor
	end
	prompt.Triggered:Connect(callback)
end

local function waitForModel(names)
	for _ = 1, 20 do
		local found = findModel(names)
		if found then
			return found
		end
		task.wait(0.5)
	end
	return nil
end

local bin = waitForModel({ "bin", "Bin", "ClothingBIn", "ClothingBin", "CubeClothingDonationBin" })
local rack = waitForModel({ "rack", "Rack", "ClothingRack", "CubeRoundClothingRack", "RoundThriftRack" })

if bin then
	addPrompt(bin, "Search", "Clothing Donation Bin", function(player)
		local now = os.clock()
		if lastUse[player] and now - lastUse[player] < 1 then return end
		lastUse[player] = now
		local found = table.clone(choose(binLoot))
		found.Id = string.format("%s_%d_%d", found.Id, player.UserId, math.floor(now * 1000))
		clothingFound:FireClient(player, { Type = "Found", Item = found })
	end)
	print("[ClothingModels] Bin connected:", bin:GetFullName())
else
	warn("[ClothingModels] Nie znaleziono modelu bin w Workspace/Modele.")
end

if rack then
	addPrompt(rack, "Roll clothing ($100)", "Circular Clothing Rack", function(player)
		local now = os.clock()
		if lastUse[player] and now - lastUse[player] < 1 then return end
		if pendingOffers[player] then return end
		lastUse[player] = now
		local spin = (spins[player] or 0) + 1
		local found = chooseRackLoot(spin)
		found.Id = string.format("%s_%d_%d", found.Id, player.UserId, math.floor(now * 1000))
		pendingOffers[player] = { Item = found, SpinNumber = spin }
		rackRoll:FireClient(player, {
			Type = "Offer",
			Item = found,
			Price = PRICE,
			SpinNumber = spin,
			UnlockMessage = unlockText(spin),
		})
	end)
	print("[ClothingModels] Rack connected:", rack:GetFullName())
else
	warn("[ClothingModels] Nie znaleziono modelu rack w Workspace/Modele.")
end

rackRoll.OnServerEvent:Connect(function(player, action)
	if action ~= "Confirm" and action ~= "Cancel" then return end
	local offer = pendingOffers[player]
	if not offer then return end
	pendingOffers[player] = nil
	if action == "Cancel" then return end
	spins[player] = offer.SpinNumber
	clothingFound:FireClient(player, {
		Type = "Found",
		Item = offer.Item,
		Price = PRICE,
		Source = "RoundRack",
		SpinNumber = offer.SpinNumber,
		UnlockMessage = unlockText(offer.SpinNumber),
	})
end)

Players.PlayerRemoving:Connect(function(player)
	pendingOffers[player] = nil
	lastUse[player] = nil
	spins[player] = nil
end)
