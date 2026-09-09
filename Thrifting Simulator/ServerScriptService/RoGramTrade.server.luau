-- RoGramTrade.server.luau
-- Put this Script in ServerScriptService.
-- Provides server-backed profile bio sync, photo relay and clothing trade sessions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local remotes = ReplicatedStorage:FindFirstChild("RoGramRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "RoGramRemotes"
	remotes.Parent = ReplicatedStorage
end

local function remoteEvent(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end

local setBio = remoteEvent("SetBio")
local trade = remoteEvent("Trade")
local photoPosted = remoteEvent("PhotoPosted")
local registerInventory = remoteEvent("RegisterInventory")

local MAX_BIO_LENGTH = 160
local MAX_OFFER_ITEMS = 5

-- The prototype inventory is registered by each client. The server still validates
-- every trade against this registry before swapping ownership.
local ownedItems: { [Player]: { [string]: boolean } } = {}
local pendingRequests: { [Player]: Player } = {}

type TradeSession = {
	A: Player,
	B: Player,
	Offers: { [Player]: { string } },
	Ready: { [Player]: boolean },
}

local sessions: { [string]: TradeSession } = {}
local activeSessionFor: { [Player]: TradeSession } = {}
local photoHistory: { [Player]: { { PhotoId: string, Caption: string, Pose: string, Likes: number, CaptureContent: string } } } = {}

local function sessionKey(a: Player, b: Player): string
	local aId = a.UserId
	local bId = b.UserId
	if aId < bId then
		return tostring(aId) .. ":" .. tostring(bId)
	end
	return tostring(bId) .. ":" .. tostring(aId)
end

local function validTarget(player: Player, targetUserId: any): Player?
	if type(targetUserId) ~= "number" then
		return nil
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		return nil
	end
	return target
end

local function cleanOffer(player: Player, ids: any): { string }
	local result: { string } = {}
	local seen: { [string]: boolean } = {}
	local ownership = ownedItems[player] or {}
	if type(ids) ~= "table" then
		return result
	end
	for _, id in ipairs(ids) do
		if #result >= MAX_OFFER_ITEMS then
			break
		end
		if type(id) == "string" and not seen[id] and ownership[id] then
			seen[id] = true
			table.insert(result, id)
		end
	end
	return result
end

local function sendSession(session: TradeSession, action: string, payload: any)
	if session.A.Parent == Players then
		trade:FireClient(session.A, action, payload)
	end
	if session.B.Parent == Players then
		trade:FireClient(session.B, action, payload)
	end
end

local function endSession(session: TradeSession, action: string, payload: any?)
	local key = sessionKey(session.A, session.B)
	sessions[key] = nil
	activeSessionFor[session.A] = nil
	activeSessionFor[session.B] = nil
	sendSession(session, action, payload)
end

local function swapOwnership(session: TradeSession)
	local aOffer = session.Offers[session.A] or {}
	local bOffer = session.Offers[session.B] or {}
	local aOwned = ownedItems[session.A] or {}
	local bOwned = ownedItems[session.B] or {}

	for _, id in ipairs(aOffer) do
		aOwned[id] = nil
		bOwned[id] = true
	end
	for _, id in ipairs(bOffer) do
		bOwned[id] = nil
		aOwned[id] = true
	end

	return aOffer, bOffer
end

setBio.OnServerEvent:Connect(function(player, text)
	if type(text) ~= "string" then
		return
	end
	text = string.sub(text, 1, MAX_BIO_LENGTH)
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(text, player.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok or type(filtered) ~= "string" then
		return
	end
	player:SetAttribute("SocialBio", filtered)
end)

registerInventory.OnServerEvent:Connect(function(player, ids)
	if type(ids) ~= "table" then
		return
	end
	local registry: { [string]: boolean } = {}
	for _, id in ipairs(ids) do
		if type(id) == "string" then
			registry[id] = true
		end
	end
	ownedItems[player] = registry
end)

trade.OnServerEvent:Connect(function(player, action, data)
	if type(action) ~= "string" then
		return
	end

	if action == "Request" then
		local target = validTarget(player, data)
		if not target then
			trade:FireClient(player, "Error", "PLAYER NOT FOUND")
			return
		end
		if activeSessionFor[player] or activeSessionFor[target] then
			trade:FireClient(player, "Error", "ONE OF YOU IS ALREADY TRADING")
			return
		end
		pendingRequests[target] = player
		trade:FireClient(player, "RequestSent", target.Name)
		trade:FireClient(target, "IncomingRequest", player.Name)
		return
	end

	if action == "Respond" then
		local requester = pendingRequests[player]
		pendingRequests[player] = nil
		if not requester or requester.Parent ~= Players then
			return
		end
		if data ~= true then
			trade:FireClient(requester, "Declined", player.Name)
			return
		end
		if activeSessionFor[requester] or activeSessionFor[player] then
			return
		end
		local session: TradeSession = {
			A = requester,
			B = player,
			Offers = { [requester] = {}, [player] = {} },
			Ready = { [requester] = false, [player] = false },
		}
		local key = sessionKey(requester, player)
		sessions[key] = session
		activeSessionFor[requester] = session
		activeSessionFor[player] = session
		sendSession(session, "Open", {
			A = requester.Name,
			B = player.Name,
		})
		return
	end

	local session = activeSessionFor[player]
	if not session then
		trade:FireClient(player, "Error", "NO ACTIVE TRADE")
		return
	end

	if action == "Offer" then
		session.Offers[player] = cleanOffer(player, data)
		session.Ready[player] = false
		local other = if session.A == player then session.B else session.A
		trade:FireClient(other, "Offer", session.Offers[player], player.Name)
		trade:FireClient(player, "OfferConfirmed", session.Offers[player])
		return
	end

	if action == "Ready" then
		session.Ready[player] = data == true
		local other = if session.A == player then session.B else session.A
		trade:FireClient(other, "Ready", session.Ready[player], player.Name)
		trade:FireClient(player, "ReadyConfirmed", session.Ready[player])
		return
	end

	if action == "Accept" then
		if not session.Ready[session.A] or not session.Ready[session.B] then
			trade:FireClient(player, "Error", "BOTH PLAYERS MUST BE READY")
			return
		end

		-- Re-check ownership immediately before the swap.
		session.Offers[session.A] = cleanOffer(session.A, session.Offers[session.A])
		session.Offers[session.B] = cleanOffer(session.B, session.Offers[session.B])
		local aOffer, bOffer = swapOwnership(session)
		endSession(session, "Completed", {
			Given = {
				[session.A.UserId] = aOffer,
				[session.B.UserId] = bOffer,
			},
			Received = {
				[session.A.UserId] = bOffer,
				[session.B.UserId] = aOffer,
			},
		})
		return
	end

	if action == "Cancel" then
		endSession(session, "Cancelled", player.Name)
		return
	end
end)

photoPosted.OnServerEvent:Connect(function(player, action, photoId, caption, pose, likes, content)
	if action == "Delete" then
		if type(photoId) ~= "string" then return end
		local history = photoHistory[player]
		if history then
			for index, photo in ipairs(history) do
				if photo.PhotoId == photoId then
					table.remove(history, index)
					break
				end
			end
		end
		photoPosted:FireAllClients("Deleted", player.Name, photoId)
		return
	end
	if action ~= "Post" then return end
	if type(photoId) ~= "string" or type(caption) ~= "string" or type(pose) ~= "string" or type(content) ~= "string" then
		return
	end
	local entry = {
		PhotoId = string.sub(photoId, 1, 100),
		Caption = string.sub(caption, 1, 160),
		Pose = string.sub(pose, 1, 20),
		Likes = if type(likes) == "number" then math.max(0, math.floor(likes)) else 0,
		CaptureContent = string.sub(content, 1, 500),
	}
	photoHistory[player] = photoHistory[player] or {}
	table.insert(photoHistory[player], 1, entry)
	while #photoHistory[player] > 50 do
		table.remove(photoHistory[player])
	end
	photoPosted:FireAllClients("Posted", player.Name, entry)
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("SocialBio", "")
	ownedItems[player] = {}
	photoHistory[player] = {}
end)

Players.PlayerRemoving:Connect(function(player)
	local session = activeSessionFor[player]
	if session then
		endSession(session, "Cancelled", player.Name)
	end
	if pendingRequests[player] then
		pendingRequests[player] = nil
	end
	for target, requester in pairs(pendingRequests) do
		if requester == player then
			pendingRequests[target] = nil
		end
	end
	ownedItems[player] = nil
	photoHistory[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	player:SetAttribute("SocialBio", player:GetAttribute("SocialBio") or "")
	ownedItems[player] = ownedItems[player] or {}
	photoHistory[player] = photoHistory[player] or {}
end
