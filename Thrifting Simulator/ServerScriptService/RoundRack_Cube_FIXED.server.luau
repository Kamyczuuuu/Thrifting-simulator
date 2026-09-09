--[[
    THRIFTING SIMULATOR - ROUND CLOTHING RACK
    Roblox Cube / GenerationService version

    Wklej ten Script do:
        ServerScriptService

    WAŻNE:
    - Ten skrypt używa Roblox Cube przez GenerationService.
    - Cube generuje model na podstawie bardzo szczegółowego promptu.
    - Jeśli chcesz użyć dokładnie zdjęcia referencyjnego, ustaw
      REFERENCE_IMAGE_ASSET_ID na ID obrazu przesłanego do Roblox.
    - Bez obrazu skrypt działa od razu na podstawie promptu.
    - Nie uruchamiaj kilku kopii tego skryptu jednocześnie.

    Dokumentacja:
    Roblox Creator Hub -> GenerationService -> GenerateModelAsync
]]

local GenerationService = game:GetService("GenerationService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

----------------------------------------------------------------
-- USTAWIENIA
----------------------------------------------------------------

local MODEL_NAME = "CubeRoundClothingRack"

-- Ustaw 0, aby używać wyłącznie promptu.
-- Po przesłaniu zdjęcia do Roblox możesz tutaj wpisać jego Asset ID.
local REFERENCE_IMAGE_ASSET_ID = 0

-- Przybliżony rozmiar całego stojaka w studach.
local TARGET_SIZE = Vector3.new(11, 10, 11)

-- Maksymalna liczba trójkątów.
-- 10000 jest rozsądnym punktem startowym dla assetu do Robloxa.
local MAX_TRIANGLES = 10000

-- Miejsce wygenerowania stojaka.
local SPAWN_CFRAME = CFrame.new(0, 0, 0)

----------------------------------------------------------------
-- DOKŁADNY PROMPT DLA ROBLOX CUBE
----------------------------------------------------------------

local PROMPT = [[
A single complete game-ready 3D circular clothing rack for a Roblox thrift
store / thrift shop simulator.

IMPORTANT: create ONE coherent physical object, not a pile of disconnected
floating objects.

REFERENCE DESIGN:
A premium freestanding circular clothes rack like a real retail store rack.
It has a heavy black metal vertical center column, a wide black metal circular
clothing rail around the top, a thin round wooden cap on top, and a wide
black tapered conical metal base.

STRUCTURE:
- one perfectly vertical central black metal pole
- one wide circular black metal rail around the pole
- the rail is continuous and physically connected to the center structure
- one thin round wooden top cap above the pole
- one solid black tapered pedestal base at the bottom
- the base is centered exactly below the pole
- the whole rack is symmetrical around the vertical axis
- no floating parts
- no detached geometry
- no random objects on the floor
- no gaps between parts that should be connected

CLOTHING:
The circular rail contains approximately 14 to 18 realistic clothing hangers.
Every hanger is physically attached to the rail with its hook.
The hangers are evenly distributed around the circular rail.
Clothes hang naturally from the hangers and are aligned with gravity.
No clothing item floats beside a hanger.
No clothing item intersects the floor.
No clothing item is detached from its hanger.

CLOTHING VARIETY:
Use realistic thrift-store clothing:
- black and white t-shirts
- oversized t-shirts
- hoodies
- button-up shirts
- denim jacket
- gray jacket
- beige jacket
- plaid shirt
- dark coat
- light long-sleeve shirt

Clothes should look like actual garments with:
- sleeves
- shoulders
- collars
- natural folds
- slightly uneven fabric silhouettes
- realistic hanging proportions
- visible separation between neighboring garments

HANGERS:
Use simple realistic retail hangers with a thin metal hook and wooden/plastic
hanger body. The hook must visibly pass over and connect to the circular rail.
Hangers must not appear as random floating loops.

STYLE:
Stylized realistic Roblox game asset.
Clean geometry.
Moderate detail.
Readable silhouette from a normal Roblox camera distance.
No photorealistic background.
No room.
No people.
No mannequin.
No text.
No logos.
No signs.
No extra furniture.

MATERIALS:
Black powder-coated metal for the frame and base.
Dark or medium natural wood for the top cap and some hangers.
Fabric materials for clothes with varied neutral colors.

GEOMETRY QUALITY:
Make the model symmetrical, clean, centered, stable and suitable for use
as a static Roblox game prop.
Keep the object optimized and avoid unnecessary tiny geometry.
Do not create loose or floating pieces.
The final output must look like one professionally manufactured retail
clothing rack.
]]

----------------------------------------------------------------
-- WAŻNE: TEN SKRYPT JEST TYLKO GENERATOREM W STUDIO
--
-- Podczas Play/Test NIE WOLNO usuwać modelu z Workspace.
-- Wcześniej skrypt usuwał model tutaj, a dopiero potem sprawdzał
-- IsRunning(), przez co gotowy wieszak znikał przy uruchomieniu gry.
----------------------------------------------------------------

if RunService:IsRunning() then
    warn("[CubeRoundRack] Play/Test: pozostawiam istniejący model w Workspace.")
    return
end

----------------------------------------------------------------
-- USUNIĘCIE STAREJ WERSJI TYLKO W TRYBIE EDYCJI
----------------------------------------------------------------

local oldModel = Workspace:FindFirstChild(MODEL_NAME)

if oldModel then
    oldModel:Destroy()
end

----------------------------------------------------------------
-- PRZYGOTOWANIE INPUTU DLA CUBE
----------------------------------------------------------------

local inputs = {
    TextPrompt = PROMPT,
    Size = TARGET_SIZE,
    MaxTriangles = MAX_TRIANGLES,
    GenerateTextures = true,
}

-- Jeśli podasz Asset ID zdjęcia, Cube dostanie również obraz referencyjny.
if REFERENCE_IMAGE_ASSET_ID and REFERENCE_IMAGE_ASSET_ID > 0 then
    inputs.Image = Content.fromAssetId(REFERENCE_IMAGE_ASSET_ID)
end

----------------------------------------------------------------
-- BODY1 = JEDEN SPÓJNY MESH
--
-- Dla tego stojaka celowo używamy Body1 zamiast Car5.
-- Dzięki temu Cube traktuje całość jako jeden spójny obiekt,
-- zamiast próbować tworzyć niepasujące do siebie części.
----------------------------------------------------------------

local schema = {
    PredefinedSchema = "Body1",
}

----------------------------------------------------------------
-- GENEROWANIE
----------------------------------------------------------------

print("[CubeRoundRack] Generowanie stojaka przez Roblox Cube...")

local success, result, metadata = pcall(function()
    return GenerationService:GenerateModelAsync(inputs, schema)
end)

if not success then
    warn("[CubeRoundRack] Nie udało się wygenerować modelu:")
    warn(result)
    return
end

if not result then
    warn("[CubeRoundRack] Cube nie zwrócił modelu.")
    return
end

----------------------------------------------------------------
-- OBRÓBKA MODELU
----------------------------------------------------------------

result.Name = MODEL_NAME

-- Skala na podstawie rzeczywistego rozmiaru wygenerowanego modelu.
local generatedSize = result:GetExtentsSize()

if generatedSize.X > 0 and generatedSize.Y > 0 and generatedSize.Z > 0 then
    local scaleX = TARGET_SIZE.X / generatedSize.X
    local scaleY = TARGET_SIZE.Y / generatedSize.Y
    local scaleZ = TARGET_SIZE.Z / generatedSize.Z

    -- Zachowujemy proporcje zamiast rozciągać model osobno w każdej osi.
    local scaleFactor = math.min(scaleX, scaleY, scaleZ)

    result:ScaleTo(scaleFactor)
end

-- Ustawiamy model tak, żeby jego dół znajdował się na poziomie 0.
local finalSize = result:GetExtentsSize()
result:PivotTo(
    CFrame.new(
        SPAWN_CFRAME.Position.X,
        SPAWN_CFRAME.Position.Y + finalSize.Y / 2,
        SPAWN_CFRAME.Position.Z
    ) * SPAWN_CFRAME.Rotation
)

-- Zakotwicz wszystko, żeby stojak nie rozpadł się ani nie spadł.
for _, descendant in result:GetDescendants() do
    if descendant:IsA("BasePart") then
        descendant.Anchored = true
        descendant.CanCollide = true
        descendant.CanTouch = false
        descendant.CanQuery = true

        -- MeshPart nie powinien generować ciężkich kolizji trójkąt po trójkącie.
        if descendant:IsA("MeshPart") then
            descendant.CollisionFidelity = Enum.CollisionFidelity.Hull
        end
    end
end

result.Parent = Workspace

print("[CubeRoundRack] Gotowe!")
print("[CubeRoundRack] Model:", result:GetFullName())

if metadata then
    print("[CubeRoundRack] Cube metadata otrzymane.")
end
