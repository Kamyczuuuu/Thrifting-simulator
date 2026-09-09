-- SprintSystem.client.luau
-- SHIFT = sprint. R15/R6 compatible.
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local WALK_SPEED = 16
local SPRINT_SPEED = 25
local ACCELERATION_TIME = 0.16
local DECELERATION_TIME = 0.20

-- Roblox's standard R15 running animation. Replace with your own uploaded
-- animation ID later if you want a completely custom sprint animation.
local SPRINT_ANIMATION_ID = "rbxassetid://507767714"

local character: Model? = nil
local humanoid: Humanoid? = nil
local animator: Animator? = nil
local sprintTrack: AnimationTrack? = nil
local sprinting = false
local shiftHeld = false

local function stopSprintAnimation(fadeTime: number?)
	if sprintTrack then
		sprintTrack:Stop(fadeTime or 0.15)
		sprintTrack = nil
	end
end

local function setupCharacter(newCharacter: Model)
	stopSprintAnimation(0)

	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	humanoid.WalkSpeed = WALK_SPEED
	sprinting = false
	shiftHeld = false

	local animation = Instance.new("Animation")
	animation.Name = "CustomSprintAnimation"
	animation.AnimationId = SPRINT_ANIMATION_ID

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if ok and track then
		sprintTrack = track
		sprintTrack.Priority = Enum.AnimationPriority.Movement
		sprintTrack.Looped = true
	end
end

local function setSprint(active: boolean)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if active and not sprinting then
		sprinting = true

		TweenService:Create(
			humanoid,
			TweenInfo.new(ACCELERATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{WalkSpeed = SPRINT_SPEED}
		):Play()

		if sprintTrack and humanoid.MoveDirection.Magnitude > 0.05 then
			if not sprintTrack.IsPlaying then
				sprintTrack:Play(0.12, 1, 1.12)
			end
			sprintTrack:AdjustSpeed(1.12)
		end

	elseif not active and sprinting then
		sprinting = false

		TweenService:Create(
			humanoid,
			TweenInfo.new(DECELERATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{WalkSpeed = WALK_SPEED}
		):Play()

		stopSprintAnimation(0.15)
	end
end

local function updateSprintAnimation()
	if not humanoid or not sprinting then
		return
	end

	local moving = humanoid.MoveDirection.Magnitude > 0.05

	if moving then
		if sprintTrack and not sprintTrack.IsPlaying then
			sprintTrack:Play(0.12, 1, 1.12)
		end
		if sprintTrack then
			sprintTrack:AdjustSpeed(1.12)
		end
	else
		if sprintTrack and sprintTrack.IsPlaying then
			sprintTrack:Stop(0.12)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		shiftHeld = true
		setSprint(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		shiftHeld = false
		setSprint(false)
	end
end)

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
	setupCharacter(player.Character)
end

task.spawn(function()
	while true do
		task.wait(0.05)

		if humanoid and humanoid.Health > 0 then
			if shiftHeld then
				if not sprinting then
					setSprint(true)
				end
				updateSprintAnimation()
			elseif sprinting then
				setSprint(false)
			end
		end
	end
end)
