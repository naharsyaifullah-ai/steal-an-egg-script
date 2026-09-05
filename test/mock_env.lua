--[[ Mock Roblox environment so the Delta script can be executed and asserted
     with the real Luau interpreter. Only the APIs the script touches are
     implemented — enough to prove the logic, not a Roblox reimplementation. ]]

-- ---------- Vector3 ----------
local V3 = {}
V3.__index = V3
local function vec(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end
function V3.__add(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function V3.__sub(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function V3.__mul(a, b)
  if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
  if type(a) == "number" then return vec(b.X * a, b.Y * a, b.Z * a) end
  return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
function V3.__index(t, k)
  if k == "Magnitude" then
    return math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
  elseif k == "Unit" then
    local m = math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
    if m == 0 then return vec(0, 0, 0) end
    return vec(t.X / m, t.Y / m, t.Z / m)
  end
  return V3[k]
end
Vector3 = { new = function(x, y, z) return vec(x, y, z) end, zero = vec(0, 0, 0) }

-- ---------- Color3 / UDim / CFrame ----------
Color3 = {
  fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255, __c3 = true } end,
  new = function(r, g, b) return { R = r, G = g, B = b, __c3 = true } end,
}
UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = { new = function(xs, xo, ys, yo)
  return { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo } }
end }
CFrame = { new = function(p) return { Position = p, __cf = true } end }
TweenInfo = { new = function(...) return { ... } end }

-- ---------- Enum ----------
local function enumSet(names)
  local t = {}
  for _, n in ipairs(names) do t[n] = { Name = n, __enum = true } end
  return t
end
Enum = {
  Font = enumSet({ "Gotham", "GothamMedium", "GothamBold", "GothamBlack", "Code" }),
  TextXAlignment = enumSet({ "Left", "Center", "Right" }),
  TextYAlignment = enumSet({ "Top", "Center", "Bottom" }),
  TextTruncate = enumSet({ "None", "AtEnd" }),
  FillDirection = enumSet({ "Horizontal", "Vertical" }),
  VerticalAlignment = enumSet({ "Top", "Center", "Bottom" }),
  SortOrder = enumSet({ "LayoutOrder", "Name" }),
  AutomaticSize = enumSet({ "None", "X", "Y", "XY" }),
  ApplyStrokeMode = enumSet({ "Contextual", "Border" }),
  HighlightDepthMode = enumSet({ "AlwaysOnTop", "Occluded" }),
  HumanoidStateType = enumSet({ "Ragdoll", "FallingDown", "Seated", "Freefall", "Running" }),
  UserInputType = enumSet({ "MouseButton1", "MouseMovement", "Touch", "Keyboard" }),
  ZIndexBehavior = enumSet({ "Sibling", "Global" }),
}

-- ---------- Signal ----------
local function newSignal()
  local s = { _fns = {} }
  function s:Connect(fn) table.insert(self._fns, fn); return { Disconnect = function() end } end
  function s:Fire(...) for _, fn in ipairs(self._fns) do fn(...) end end
  return s
end

-- ---------- Instance ----------
local CLASS_PARENTS = {
  BasePart = "PVInstance", Part = "BasePart", MeshPart = "BasePart",
  SpawnLocation = "BasePart", Model = "PVInstance",
  TextLabel = "GuiObject", TextButton = "GuiObject", TextBox = "GuiObject",
  Frame = "GuiObject", ScrollingFrame = "Frame", ImageLabel = "GuiObject",
  GuiObject = "GuiBase2d", ScreenGui = "LayerCollector", BillboardGui = "LayerCollector",
  Humanoid = "Instance", Folder = "Instance", Highlight = "Instance",
  RemoteEvent = "Instance", RemoteFunction = "Instance", ProximityPrompt = "Instance",
  StringValue = "ValueBase", NumberValue = "ValueBase", IntValue = "ValueBase",
  BoolValue = "ValueBase", ObjectValue = "ValueBase",
  UICorner = "Instance", UIStroke = "Instance", UIPadding = "Instance",
  UIListLayout = "Instance", UIGridLayout = "Instance",
  BodyVelocity = "Instance", BodyGyro = "Instance",
}

local INST = {}
INST.__index = function(t, k)
  local raw = rawget(t, "_p")[k]
  if raw ~= nil then return raw end
  return INST[k]
end
INST.__newindex = function(t, k, v)
  if k == "Parent" then
    local old = rawget(t, "_p").Parent
    if old then
      for i, c in ipairs(rawget(old, "_kids")) do
        if c == t then table.remove(rawget(old, "_kids"), i); break end
      end
    end
    rawget(t, "_p").Parent = v
    if v then table.insert(rawget(v, "_kids"), t) end
    return
  end
  rawget(t, "_p")[k] = v
end

local ALL = {}

function Instance_new(class, parent)
  local o = setmetatable({ _kids = {}, _p = {} }, INST)
  local p = rawget(o, "_p")
  p.ClassName = class
  p.Name = class
  p.Enabled = true
  p.Text = ""
  p.Visible = true
  p.Value = nil
  if class == "BasePart" or class == "Part" or class == "MeshPart" or class == "SpawnLocation" then
    p.Position = vec(0, 0, 0)
    p.CFrame = CFrame.new(vec(0, 0, 0))
    p.Velocity = vec(0, 0, 0)
  end
  if class == "Humanoid" then
    p.Health = 100
    p.WalkSpeed = 16
    p.PlatformStand = false
    p.Sit = false
    p._states = {}
  end
  if class == "TextButton" then
    p.MouseButton1Click = newSignal()
    p.InputBegan = newSignal()
    p.InputEnded = newSignal()
    p.AbsolutePosition = vec(0, 0, 0)
    p.AbsoluteSize = vec(100, 10, 0)
  end
  if class == "Frame" or class == "ScrollingFrame" then
    p.AbsolutePosition = vec(0, 0, 0)
    p.AbsoluteSize = vec(200, 40, 0)
  end
  if class == "RemoteEvent" then
    -- real RemoteEvents expose OnClientEvent; the prediction hook connects to it
    p.OnClientEvent = newSignal()
  end
  table.insert(ALL, o)
  if parent then o.Parent = parent end
  return o
end
Instance = { new = Instance_new }

function INST:IsA(cls)
  local c = rawget(self, "_p").ClassName
  while c do
    if c == cls then return true end
    c = CLASS_PARENTS[c]
  end
  return cls == "Instance"
end
function INST:GetChildren() return rawget(self, "_kids") end
function INST:GetDescendants()
  local out = {}
  local function walk(n)
    for _, c in ipairs(rawget(n, "_kids")) do
      out[#out + 1] = c
      walk(c)
    end
  end
  walk(self)
  return out
end
function INST:FindFirstChild(n)
  for _, c in ipairs(rawget(self, "_kids")) do
    if rawget(c, "_p").Name == n then return c end
  end
  return nil
end
function INST:FindFirstChildOfClass(cls)
  for _, c in ipairs(rawget(self, "_kids")) do
    if rawget(c, "_p").ClassName == cls then return c end
  end
  return nil
end
function INST:FindFirstChildWhichIsA(cls)
  for _, c in ipairs(rawget(self, "_kids")) do
    if c:IsA(cls) then return c end
  end
  return nil
end
function INST:Destroy()
  -- must go through __newindex so the parent's child list is actually updated;
  -- rawsetting Parent first made destroyed objects linger and be re-found by
  -- FindFirstChildOfClass, which faked five test failures.
  self.Parent = nil
  rawset(self, "_destroyed", true)
end
function INST:ClearAllChildren()
  for _, c in ipairs({ table.unpack(rawget(self, "_kids")) }) do c:Destroy() end
end
function INST:GetPivot()
  local pp = rawget(self, "_p").PrimaryPart or self:FindFirstChildWhichIsA("BasePart")
  return CFrame.new(pp and pp.Position or vec(0, 0, 0))
end
function INST:SetStateEnabled(state, on)
  rawget(self, "_p")._states[state.Name] = on
end
function INST:GetStateEnabled(state)
  return rawget(self, "_p")._states[state.Name]
end
function INST:FireServer(...)
  local p = rawget(self, "_p")
  p._fired = (p._fired or 0) + 1
  p._lastArgs = table.pack(...)
end
function INST:InvokeServer(...)
  local p = rawget(self, "_p")
  p._fired = (p._fired or 0) + 1
  p._lastArgs = table.pack(...)
  return true
end
-- OnClientEvent: the prediction module hooks server announcements
function INST:_ensureClientEvent()
  local p = rawget(self, "_p")
  if not p.OnClientEvent then p.OnClientEvent = newSignal() end
  return p.OnClientEvent
end
