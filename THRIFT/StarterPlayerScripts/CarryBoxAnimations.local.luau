-- CarryBoxAnimations: custom walk/run animation while carrying the FlipTag box.
--
-- JAK DODAĆ WŁASNE ANIMACJE:
-- 1. Otwórz Animation Editor (w Studio: zakładka Avatar / Plugin "Animation Editor").
-- 2. Zbuduj animację chodzenia z kartonem (ręce trzymają pudelko przed sobą,
--    nogi normalnie idą) — rig R15, długość zapętli ~1s.
-- 3. Zbuduj osobno animację biegu z kartonem (szybsze kroki, lekki pochył).
-- 4. Opublikuj obie (Publish to Roblox) i wklej ich ID do CARRY_WALK_ID
--    i CARRY_RUN_ID poniżej (format liczbowy, np. 123456789).
-- 5. Animacje muszą należeć do Ciebie lub Twojej grupy, inaczej się nie wczytają.
--
-- Dopóki ID = 0, działa proceduralny fallback (ręce w pozie noszenia z lekkim
-- kołysaniem zsynchronizowanym z ruchem).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- >>> WKLEJ TUTAJ ID SWOICH ANIMACJI <<<
local CARRY_WALK_ID = 0
local CARRY_RUN_ID = 0

local RUN_THRESHOLD = 17 -- powyżej tej prędkości używana jest animacja biegu
local BASE_SPEED = 16 -- prędkość, dla której animacja była zbudowana

local state = {
	character = nil,
	animator = nil,
	walkTrack = nil,
	runTrack = nil,
	active = false,
}

local ARM_FORWARD = math.rad(80)
local ELBOW_BEND = math.rad(25)

local function getJoints(character)
	local right = character:FindFirstChild("RightShoulder")
	local left = character:FindFirstChild("LeftShoulder")
	if right and left and right:IsA("Motor6D") and left:IsA("Motor6D") then
		return right, left,
			character:FindFirstChild("RightElbow"),
			character:FindFirstChild("LeftElbow"), "R15"
	end
	right = character:FindFirstChild("Right Shoulder")
	left = character:FindFirstChild("Left Shoulder")
	if right and left and right:IsA("Motor6D") and left:IsA("Motor6D") then
		return right, left, nil, nil, "R6"
	end
	return nil, nil, nil, nil, nil
end

local function ensureTracks(character, humanoid)
	if state.character == character and state.animator then
		return state.walkTrack or state.runTrack
	end
	state.character = character
	state.animator = humanoid:FindFirstChildOfClass("Animator")
	state.walkTrack = nil
	state.runTrack = nil
	if not state.animator then
		return nil
	end
	if CARRY_WALK_ID ~= 0 then
		local ok, track = pcall(function()
			local t = state.animator:LoadAnimation(CARRY_WALK_ID)
			t.Priority = Enum.AnimationPriority.Action
			return t
		end)
		if ok then state.walkTrack = track end
	end
	if CARRY_RUN_ID ~= 0 then
		local ok, track = pcall(function()
			local t = state.animator:LoadAnimation(CARRY_RUN_ID)
			t.Priority = Enum.AnimationPriority.Action
			return t
		end)
		if ok then state.runTrack = track end
	end
	return state.walkTrack or state.runTrack
end

local function stopTracks()
	if state.walkTrack then state.walkTrack:Stop(0.15) end
	if state.runTrack then state.runTrack:Stop(0.15) end
end

local function proceduralPose(character, speed, alpha)
	local rShoulder, lShoulder, rElbow, lElbow, rigType = getJoints(character)
	if not rShoulder then return end
	-- Lekkie kołysanie rąk zsynchronizowane z tempem ruchu.
	local sway = math.sin(os.clock() * (4 + speed * 0.6)) * math.rad(4) * alpha
	if rigType == "R15" then
		rShoulder.Transform = CFrame.Angles(ARM_FORWARD + sway, 0, math.rad(6))
		lShoulder.Transform = CFrame.Angles(ARM_FORWARD - sway, 0, -math.rad(6))
		if rElbow and rElbow:IsA("Motor6D") then
			rElbow.Transform = CFrame.Angles(ELBOW_BEND, 0, 0)
		end
		if lElbow and lElbow:IsA("Motor6D") then
			lElbow.Transform = CFrame.Angles(ELBOW_BEND, 0, 0)
		end
	else
		rShoulder.Transform = CFrame.Angles(0, 0, ARM_FORWARD + sway)
		lShoulder.Transform = CFrame.Angles(0, 0, -(ARM_FORWARD - sway))
	end
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then
		if state.active then
			state.active = false
			stopTracks()
		end
		return
	end

	local box = character:FindFirstChild("FlipTagBox")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local carrying = box ~= nil and humanoid ~= nil and humanoid.Health > 0 and root ~= nil

	if not carrying then
		if state.active then
			state.active = false
			stopTracks()
		end
		return
	end
	state.active = true

	local speed = Vector3.new(
		root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z
	).Magnitude

	-- Wariant A: prawdziwe animacje (o ile ID są ustawione).
	if CARRY_WALK_ID ~= 0 or CARRY_RUN_ID ~= 0 then
		local anyTrack = ensureTracks(character, humanoid)
		if not anyTrack then return end

		local moving = speed > 0.5
		local useRun = speed >= RUN_THRESHOLD and state.runTrack ~= nil
		local target = useRun and state.runTrack or state.walkTrack
		if not target then target = state.runTrack or state.walkTrack end
		if not target then return end

		if moving then
			if not target.IsPlaying then
				target:Play(0.15)
			end
			-- Skaluj tempo animacji do faktycznej prędkości postaci.
			target:AdjustSpeed(math.max(0.25, speed / BASE_SPEED))
			local other = useRun and state.walkTrack or state.runTrack
			if other and other ~= target and other.IsPlaying then
				other:Stop(0.15)
			end
		else
			if target.IsPlaying then target:Stop(0.15) end
			local other = useRun and state.walkTrack or state.runTrack
			if other and other.IsPlaying then other:Stop(0.15) end
			-- Stojąc z kartonem, trzymaj ręce w pozie noszenia.
			proceduralPose(character, 0, 0)
		end
		return
	end

	-- Wariant B: fallback proceduralny (ręce + kołysanie).
	proceduralPose(character, speed, math.min(1, speed / 8))
end)