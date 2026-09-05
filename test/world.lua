-- ================= WORLD + RUNNER SCAFFOLD =================
PASS, FAIL = 0, 0
function check(name, cond, detail)
  if cond then
    PASS = PASS + 1
    print("  ok   " .. name)
  else
    FAIL = FAIL + 1
    print("  FAIL " .. name .. (detail ~= nil and ("  <<< " .. tostring(detail)) or ""))
  end
end
function sect(t) print("\n=== " .. t .. " ===") end
function REPORT()
  print("\n==============================================")
  print(string.format("PASS %d   FAIL %d", PASS, FAIL))
  print("==============================================")
end

-- physics: BodyVelocity moves HumanoidRootPart, so glideTo can converge
PHYSICS_STEP = function(dt)
  local chr = rawget(MOCK.LocalPlayer, "_p").Character
  if not chr then return end
  local hrp = chr:FindFirstChild("HumanoidRootPart")
  if not hrp then return end
  local bv = hrp:FindFirstChildOfClass("BodyVelocity")
  if bv and bv.Velocity then
    hrp.Position = hrp.Position + bv.Velocity * dt
  end
end

local W = MOCK.Workspace
local RSf = MOCK.RS

-- my base, tagged with my name
local baseModel = Instance.new("Model", W)
baseModel.Name = "PlayerBase"
local basePart = makePart("BaseFloor", baseModel, Vector3.new(0, 0, 0))
rawget(baseModel, "_p").PrimaryPart = basePart
local ownerTag = Instance.new("StringValue", baseModel)
ownerTag.Name = "Owner"
ownerTag.Value = MOCK.LocalPlayer.Name

-- someone else's base must NOT be picked
local rivalBase = Instance.new("Model", W)
rivalBase.Name = "PlayerBase"
local rivalPart = makePart("BaseFloor", rivalBase, Vector3.new(999, 0, 999))
rawget(rivalBase, "_p").PrimaryPart = rivalPart
local rivalTag = Instance.new("StringValue", rivalBase)
rivalTag.Name = "Owner"
rivalTag.Value = "RivalOne"

-- eggs: rarity / mutation / weight spread
EGGS = {
  makeEgg(W, "ChickenEgg",    Vector3.new(120, 0, 0), "Common",    nil,            120),
  makeEgg(W, "DodoEgg",       Vector3.new(200, 0, 0), "Rare",      nil,            4000),
  makeEgg(W, "LavaIguanaEgg", Vector3.new(260, 0, 0), "Legendary", "Silver",       25000),
  makeEgg(W, "StagEgg",       Vector3.new(300, 0, 0), "Secret",    nil,            900000),
  makeEgg(W, "OniTigerEgg",   Vector3.new(340, 0, 0), "Eternal",   "Bloom",        1500000),
  makeEgg(W, "KitsuneEgg",    Vector3.new(380, 0, 0), "Divine",    "Spirit Bloom", 3240000),
  makeEgg(W, "MysteryEgg",    Vector3.new(410, 0, 0), nil,         nil,            nil),
}

-- traps + hostiles
makePart("SpikeTrap", W, Vector3.new(150, 0, 0))
makePart("BearTrap",  W, Vector3.new(280, 0, 10))
makeHostile(W, "Bat",            Vector3.new(310, 0, 5))
makeHostile(W, "ForestGuardian", Vector3.new(250, 0, 20))
makeHostile(W, "VolcanoBoss",    Vector3.new(700, 0, 0))

makePart("Treadmill", W, Vector3.new(20, 0, 20))

-- a prompt right next to the divine egg
local promptHost = makePart("PromptHost", W, Vector3.new(381, 0, 0))
Instance.new("ProximityPrompt", promptHost)
-- and one far away that must not fire
local farHost = makePart("FarPromptHost", W, Vector3.new(5000, 0, 0))
Instance.new("ProximityPrompt", farHost)

-- remotes
R = {
  steal   = makeRemote(RSf, "StealEgg"),
  hatch   = makeRemote(RSf, "HatchEgg"),
  claim   = makeRemote(RSf, "ClaimMoney"),
  train   = makeRemote(RSf, "TrainTreadmill"),
  deposit = makeRemote(RSf, "DepositEgg"),
  upgrade = makeRemote(RSf, "BuyUpgrade"),
  sell    = makeRemote(RSf, "SellPet", "RemoteFunction"),
  noise   = makeRemote(RSf, "UnrelatedPing"),
}

addOtherPlayer("RivalOne", Vector3.new(90, 0, 30))
addOtherPlayer("RivalTwo", Vector3.new(500, 0, 60))

CHR = attachCharacter(Vector3.new(0, 0, 0))
