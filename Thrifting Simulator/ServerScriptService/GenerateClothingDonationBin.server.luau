local ServerScriptService = game:GetService("ServerScriptService")

local old = ServerScriptService:FindFirstChild("GenerateClothingDonationBin")
if old then old:Destroy() end

local scriptObject = Instance.new("Script")
scriptObject.Name = "GenerateClothingDonationBin"

scriptObject.Source = [=[
local GenerationService = game:GetService("GenerationService")
local Workspace = game:GetService("Workspace")

local MODEL_NAME = "CubeClothingDonationBin"
local TARGET_SIZE = Vector3.new(8, 9, 5)
local MAX_TRIANGLES = 12000
local POSITION = CFrame.new(0, 4.5, -20)

local prompt = [=[
A realistic standalone outdoor CLOTHING DONATION BIN for a Roblox thrift store.

Create ONLY the physical 3D object.

ABSOLUTELY NO TEXT, LETTERS, WORDS, NUMBERS, LOGOS, SYMBOLS, SIGNS, DECALS, LABELS, ADVERTISEMENTS, GRAPHICS, ICONS OR WRITING.

Every exterior panel must be completely blank. Do not generate fake or unreadable writing.

Create a realistic commercial clothing donation and recycling container based on a real-world outdoor clothes recycling bin.

Shape:
- tall rectangular industrial metal container
- approximately 8 studs wide, 9 studs tall and 5 studs deep
- large heavy metal cabinet
- slightly wider than deep
- realistic industrial proportions
- reinforced corners
- thick metal panels
- realistic bevels and seams

Material:
- bright vivid lime green painted steel
- slightly rough painted metal
- subtle realistic wear
- darker green structural frame
- realistic metal reflections and shadows
- no plastic appearance
- no futuristic materials

Roof:
- flat metal roof
- slight overhang
- thick metal edges
- reinforced construction
- completely blank

Front:
- large rectangular recessed metal door
- thick metal door frame
- realistic hinges
- large horizontal metal handle
- reinforced edges
- completely blank

Upper clothing drop:
- large horizontal rectangular opening near the upper front
- deep dark interior cavity
- visible interior walls
- slanted metal chute leading inside
- thick metal frame around the opening
- metal safety lip
- horizontal metal grab bar below the opening
- realistic depth
- opening large enough to insert clothes

Interior:
- dark gray metal
- deep cavity
- realistic shadows
- real 3D geometry
- not a flat black decal

Sides:
- large flat green metal panels
- subtle seams
- reinforced vertical edges
- completely blank

Back:
- plain green metal panel
- reinforced corners
- subtle seams
- completely blank

Bottom:
- sturdy industrial metal base
- four small metal support feet
- slightly raised from the ground
- no wheels

Style:
- realistic commercial clothing donation container
- real-world outdoor clothes recycling bin
- realistic painted steel
- realistic industrial construction
- Roblox-ready 3D asset
- detailed but optimized
- clean silhouette
- realistic proportions
- not cartoonish
- not futuristic
- not sci-fi
- not a normal garbage dumpster
- not a household trash can

FINAL REQUIREMENT:
Generate ONLY the physical 3D object.
Every panel must remain completely blank.
ZERO text, letters, numbers, logos, decals, signs, advertisements, symbols or graphics.
]=]

local inputs = {
	TextPrompt = prompt,
	Size = TARGET_SIZE,
	MaxTriangles = MAX_TRIANGLES,
	GenerateTextures = true,
}

local schema = {
	PredefinedSchema = "Body1"
}

print("CUBE: ROZPOCZYNAM GENEROWANIE KOSZA...")

local success, model, metadata = pcall(function()
	return GenerationService:GenerateModelAsync(inputs, schema)
end)

if not success then
	warn("CUBE ERROR:")
	warn(model)
	return
end

if not model then
	warn("Cube nie zwrócił modelu.")
	return
end

model.Name = MODEL_NAME

local currentSize = model:GetExtentsSize()

if currentSize.X > 0 and currentSize.Y > 0 and currentSize.Z > 0 then
	local scaleX = TARGET_SIZE.X / currentSize.X
	local scaleY = TARGET_SIZE.Y / currentSize.Y
	local scaleZ = TARGET_SIZE.Z / currentSize.Z
	local scaleFactor = math.min(scaleX, scaleY, scaleZ)
	model:ScaleTo(scaleFactor)
end

model:PivotTo(POSITION)

for _, object in ipairs(model:GetDescendants()) do
	if object:IsA("BasePart") then
		object.Anchored = true
		object.CanCollide = true
	end
end

model.Parent = Workspace

print("CUBE: KOSZ ZOSTAŁ UTWORZONY!")
print("Nazwa:", model.Name)
print("Rozmiar:", model:GetExtentsSize())
]=]

scriptObject.Parent = ServerScriptService

print("Gotowe! Kliknij PLAY, aby Cube wygenerował kosz.")
