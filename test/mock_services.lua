-- ---------- services ----------
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
function fireproximityprompt(p) PROMPT_FIRED = PROMPT_FIRED + 1; rawget(p, "_p")._fired = true end
function firetouchinterest(a, b, s) TOUCH_FIRED = TOUCH_FIRED + 1 end

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
