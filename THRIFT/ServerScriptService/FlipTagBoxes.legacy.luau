-- FlipTagBoxes: when a player lists a clothing item for sale on FLIPTAG,
-- the server attaches the "karton" model to their hands (two-handed carry).
-- The box grows with every additional listed item (up to MAX_ITEMS).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("ThriftRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "ThriftRemotes"
	remotes.Parent = ReplicatedStorage
end

local boxRemote = remotes:FindFirstChild("FlipTagBox")
if not boxRemote then
	boxRemote = Instance.new("RemoteEvent")
	boxRemote.Name = "FlipTagBox"
	boxRemote.Parent = remotes
end

local MAX_ITEMS = 5
local boxCounts = {}

local kartonTemplate = ReplicatedStorage:FindFirstChild("karton")

local function getHands(character)
	local right = character:FindFirstChild("RightHand")
	local left = character:FindFirstChild("LeftHand")
	if right and left and right:IsA("BasePart") and left:IsA("BasePart") then
		return right, left
	end
	-- R6 fallback
	right = character:FindFirstChild("Right Arm")
	left = character:FindFirstChild("Left Arm")
	if right and left and right:IsA("BasePart") and left:IsA("BasePart") then
		return right, left
	end
	return nil, nil
end

local function getOrCreateBox(character)
	local box = character:FindFirstChild("FlipTagBox")
	if box and box:IsA("Model") then
		return box
	end
	if not kartonTemplate then
		warn("[FlipTagBoxes] Brak szablonu kartonu w ReplicatedStorage")
		return nil
	end

	box = kartonTemplate:Clone()
	box.Name = "FlipTagBox"
	for _, part in ipairs(box:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.Anchored = false
		end
	end
	box.Parent = character
	return box
end

local function seatBox(box, rightHand, leftHand)
	local character = rightHand.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local rootCFrame = root and root.CFrame or rightHand.CFrame

	-- Hold the box in front of the chest, between both hands, far enough
	-- forward that it never intersects the torso while running.
	local mid = (rightHand.Position + leftHand.Position) / 2
	local offsetY = rootCFrame:PointToObjectSpace(mid).Y
	local forward = 1.9 + box:GetExtentsSize().Z * 0.25
	box:PivotTo(rootCFrame * CFrame.new(0, offsetY, -forward))

	-- Remove old welds, then weld the box to BOTH hands so the player
	-- carries it with two hands.
	for _, child in ipairs(box:GetDescendants()) do
		if child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end
	local mainPart = box.PrimaryPart or box:FindFirstChildWhichIsA("BasePart", true)
	if not mainPart then return end
	if not box.PrimaryPart then
		box.PrimaryPart = mainPart
	end

	local weldRight = Instance.new("WeldConstraint")
	weldRight.Name = "BoxWeldRight"
	weldRight.Part0 = rightHand
	weldRight.Part1 = mainPart
	weldRight.Parent = mainPart

	local weldLeft = Instance.new("WeldConstraint")
	weldLeft.Name = "BoxWeldLeft"
	weldLeft.Part0 = leftHand
	weldLeft.Part1 = mainPart
	weldLeft.Parent = mainPart
end

local function updateBoxSize(box, rightHand, leftHand, count)
	-- The template karton is ~3.5 studs wide; scale it down for carrying
	-- and let it grow with each additional sold item.
	local scale = 0.4 + count * 0.08
	box:ScaleTo(scale)
	seatBox(box, rightHand, leftHand)
end

boxRemote.OnServerEvent:Connect(function(player, action)
	local character = player.Character
	if not character then return end

	-- "deposit": gracz odłożył paczki w paczkomacie — zdejmij karton z rąk.
	if action == "deposit" then
		local box = character:FindFirstChild("FlipTagBox")
		if box then
			box.Parent = nil
		end
		boxCounts[player] = 0
		return
	end

	local rightHand, leftHand = getHands(character)
	if not rightHand then return end

	local count = math.min(MAX_ITEMS, (boxCounts[player] or 0) + 1)
	boxCounts[player] = count

	local box = getOrCreateBox(character)
	if not box then return end
	updateBoxSize(box, rightHand, leftHand, count)
end)

-- The box is parented to the character, so it disappears on death/respawn.
-- Reset the carried-item counter at the same time.
local function onCharacterAdded(player, character)
	boxCounts[player] = 0
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	boxCounts[player] = nil
end)