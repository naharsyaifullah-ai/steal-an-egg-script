-- ---------- services ----------
do -- scope register harness
local Workspace   = Instance.new("Folder"); Workspace.Name = "Workspace"
local RS          = Instance.new("Folder"); RS.Name = "ReplicatedStorage"
local CoreGui     = Instance.new("Folder"); CoreGui.Name = "CoreGui"
local PlayersSvc  = Instance.new("Folder"); PlayersSvc.Name = "Players"

local playerList = {}
PlayersSvc.GetPlayers = function() return playerList end
PlayersSvc.GetPlayerFromCharacter = function(_, chr)
  for _, pl in ipairs(playerList) do
    if rawget(pl, "_p").Character == chr then return pl end
  end
  return nil
end

local LocalPlayer = Instance.new("Folder")
LocalPlayer.Name = "TesterPalz"
table.insert(playerList, LocalPlayer)
PlayersSvc.LocalPlayer = LocalPlayer
-- real Roblox players own a PlayerGui; the remote indexer walks it
local playerGui = Instance.new("Folder", LocalPlayer)
playerGui.Name = "PlayerGui"

local TweenService = {
  Create = function(_, obj, info, props)
    return { Play = function()
      for k, v in pairs(props) do pcall(function() obj[k] = v end) end
    end }
  end,
}

local RunService = { Heartbeat = newSignal(), RenderStepped = newSignal() }
local UIS = { InputChanged = newSignal(), InputBegan = newSignal(), TouchEnabled = true }

local SERVICES = {
  Players = PlayersSvc,
  Workspace = Workspace,
  ReplicatedStorage = RS,
  CoreGui = CoreGui,
  TweenService = TweenService,
  RunService = RunService,
  UserInputService = UIS,
}

game = {
  GetService = function(_, n)
    local s = SERVICES[n]
    if not s then error("mock: service missing " .. n) end
    return s
  end,
}
workspace = Workspace

-- executor globals
PROMPT_FIRED, TOUCH_FIRED = 0, 0
-- SIM_PICKUP: when true, firing a prompt / touching a part that belongs to an
-- egg model reparents that egg onto the character — i.e. the mock behaves like a
-- server that actually grants the pickup. Without this the steal loop can never
-- be verified end to end, because v4 only counts a steal after it confirms the
-- egg is really held.
SIM_PICKUP = false

local function eggAncestor(inst)
  local n = inst
  while n and n ~= MOCK_WS_SENTINEL do
    local nm = tostring(rawget(n, "_p") and rawget(n, "_p").Name or "")
    if nm:lower():find("egg") then return n end
    n = rawget(n, "_p") and rawget(n, "_p").Parent
  end
  return nil
end

function SIM_GRANT(inst)
  if not SIM_PICKUP then return end
  local egg = eggAncestor(inst)
  if not egg then return end
  local chr = rawget(MOCK.LocalPlayer, "_p").Character
  if chr then egg.Parent = chr end
end

function fireproximityprompt(p)
  PROMPT_FIRED = PROMPT_FIRED + 1
  rawget(p, "_p")._fired = true
  SIM_GRANT(p)
end
function firetouchinterest(a, b, s)
  TOUCH_FIRED = TOUCH_FIRED + 1
  if s == 1 then SIM_GRANT(b) end
end

-- ---------- fake executor filesystem + loadstring ----------
-- Dipakai menguji persistensi resep AJARI (writefile/readfile/isfile).
MOCKFS = {}
function writefile(name, data) MOCKFS[name] = tostring(data) return true end
function readfile(name) return MOCKFS[name] end
function isfile(name) return MOCKFS[name] ~= nil end
if type(loadstring) ~= "function" then
  local _load = load or loadstring
  loadstring = function(src, name) return _load(src, name or "=recipe") end
end

-- ---------- fake scheduler: run task.spawn bodies on demand ----------
local SPAWNED = {}
local CLOCK = 0
task = {
  spawn = function(fn) table.insert(SPAWNED, coroutine.create(fn)) end,
  wait = function(t) coroutine.yield(t or 0) end,
  delay = function(_, fn) table.insert(SPAWNED, coroutine.create(fn)) end,
}
function tick() return CLOCK end
local realTick = os.clock

-- step every spawned loop N times, advancing the fake clock
function stepScheduler(rounds, dt)
  dt = dt or 0.1
  for _ = 1, rounds do
    CLOCK = CLOCK + dt
    for _, co in ipairs(SPAWNED) do
      if coroutine.status(co) == "suspended" then
        local ok, err = coroutine.resume(co)
        if not ok then
          print("  [scheduler error] " .. tostring(err))
        end
      end
    end
    -- crude physics so BodyVelocity actually moves the character,
    -- otherwise glideTo could never converge in the mock
    if PHYSICS_STEP then PHYSICS_STEP(dt) end
  end
end
function spawnedCount() return #SPAWNED end

-- ---------- world builder ----------
function makePart(name, parent, pos)
  local p = Instance.new("Part", parent)
  p.Name = name
  p.Position = pos or vec(0, 0, 0)
  return p
end

function makeEgg(parent, name, pos, rarityText, mutationText, weightKg)
  local m = Instance.new("Model", parent)
  m.Name = name
  local pp = Instance.new("Part", m)
  pp.Name = "Shell"
  pp.Position = pos
  rawget(m, "_p").PrimaryPart = pp

  local bb = Instance.new("BillboardGui", m)
  local tl = Instance.new("TextLabel", bb)
  local txt = rarityText or ""
  if mutationText then txt = mutationText .. " " .. txt end
  if weightKg then txt = txt .. " " .. tostring(weightKg) .. " kg" end
  tl.Text = txt
  return m
end

function makeHostile(parent, name, pos)
  local m = Instance.new("Model", parent)
  m.Name = name
  local h = Instance.new("Humanoid", m)
  local pp = Instance.new("Part", m)
  pp.Name = "Torso"
  pp.Position = pos
  rawget(m, "_p").PrimaryPart = pp
  return m
end

function makeRemote(parent, name, kind)
  local r = Instance.new(kind or "RemoteEvent", parent)
  r.Name = name
  return r
end

function makeCharacter(owner, pos)
  local chr = Instance.new("Model")
  chr.Name = owner
  local hrp = Instance.new("Part", chr)
  hrp.Name = "HumanoidRootPart"
  hrp.Position = pos
  local hum = Instance.new("Humanoid", chr)
  rawget(chr, "_p").PrimaryPart = hrp
  return chr
end

function attachCharacter(pos)
  local chr = makeCharacter(LocalPlayer.Name, pos)
  chr.Parent = Workspace
  rawget(LocalPlayer, "_p").Character = chr
  return chr
end

function addOtherPlayer(name, pos)
  local pl = Instance.new("Folder")
  pl.Name = name
  local chr = makeCharacter(name, pos)
  chr.Parent = Workspace
  rawget(pl, "_p").Character = chr
  table.insert(playerList, pl)
  return pl
end

-- expose
MOCK = {
  Workspace = Workspace, RS = RS, CoreGui = CoreGui,
  Players = PlayersSvc, LocalPlayer = LocalPlayer,
  UIS = UIS,
}

end -- mock_services scope
