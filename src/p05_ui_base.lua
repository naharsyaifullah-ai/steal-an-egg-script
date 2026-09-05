-- ============ UI: tema & helper ============
local T = {
  bg      = Color3.fromRGB(13, 15, 21),
  panel   = Color3.fromRGB(19, 22, 30),
  panel2  = Color3.fromRGB(25, 29, 39),
  line    = Color3.fromRGB(38, 44, 58),
  txt     = Color3.fromRGB(232, 238, 247),
  txt2    = Color3.fromRGB(146, 160, 182),
  gold    = Color3.fromRGB(232, 163, 61),
  jade    = Color3.fromRGB(62, 207, 154),
  red     = Color3.fromRGB(217, 117, 95),
}

local function corner(o, r)
  local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c
end
local function stroke(o, col, th)
  local s = Instance.new("UIStroke")
  s.Color = col or T.line; s.Thickness = th or 1
  s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s
end
local function pad(o, v)
  local p = Instance.new("UIPadding")
  p.PaddingTop = UDim.new(0, v); p.PaddingBottom = UDim.new(0, v)
  p.PaddingLeft = UDim.new(0, v); p.PaddingRight = UDim.new(0, v)
  p.Parent = o; return p
end
local function label(parent, text, size, color, bold)
  local l = Instance.new("TextLabel")
  l.BackgroundTransparency = 1
  l.Size = UDim2.new(1, 0, 0, size + 8)
  l.Text = text
  l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
  l.TextSize = size
  l.TextColor3 = color or T.txt
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.Parent = parent
  return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "SAE_Hub_v2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- tombol bulat pembuka (kalau hub disembunyikan)
local orb = Instance.new("TextButton")
orb.Size = UDim2.new(0, 52, 0, 52)
orb.Position = UDim2.new(0, 14, 0.42, 0)
orb.BackgroundColor3 = T.gold
orb.Text = "EGG"
orb.Font = Enum.Font.GothamBlack
orb.TextSize = 13
orb.TextColor3 = Color3.fromRGB(20, 14, 4)
orb.Visible = false
orb.Active = true
orb.Draggable = true
orb.Parent = gui
corner(orb, 26)

-- jendela utama
local win = Instance.new("Frame")
win.Size = UDim2.new(0, 330, 0, 412)
win.Position = UDim2.new(0, 18, 0.5, -206)
win.BackgroundColor3 = T.bg
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = gui
corner(win, 14)
stroke(win, T.line, 1)

-- header
local head = Instance.new("Frame")
head.Size = UDim2.new(1, 0, 0, 46)
head.BackgroundTransparency = 1
head.Parent = win

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 16, 0, 19)
dot.BackgroundColor3 = T.jade
dot.BorderSizePixel = 0
dot.Parent = head
corner(dot, 4)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1, -110, 1, 0)
ttl.Position = UDim2.new(0, 32, 0, 0)
ttl.BackgroundTransparency = 1
ttl.Text = "STEAL AN EGG"
ttl.Font = Enum.Font.GothamBlack
ttl.TextSize = 14
ttl.TextColor3 = T.txt
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.Parent = head

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(0, 40, 1, 0)
ver.Position = UDim2.new(1, -86, 0, 0)
ver.BackgroundTransparency = 1
ver.Text = "v2"
ver.Font = Enum.Font.Code
ver.TextSize = 11
ver.TextColor3 = T.txt2
ver.Parent = head

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 34, 0, 34)
hideBtn.Position = UDim2.new(1, -44, 0, 6)
hideBtn.BackgroundColor3 = T.panel2
hideBtn.Text = "—"
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 16
hideBtn.TextColor3 = T.txt2
hideBtn.Parent = head
corner(hideBtn, 9)

-- tab bar
local tabbar = Instance.new("Frame")
tabbar.Size = UDim2.new(1, -24, 0, 38)
tabbar.Position = UDim2.new(0, 12, 0, 44)
tabbar.BackgroundColor3 = T.panel
tabbar.BorderSizePixel = 0
tabbar.Parent = win
corner(tabbar, 10)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabbar
pad(tabbar, 4)

-- area konten
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -132)
content.Position = UDim2.new(0, 12, 0, 90)
content.BackgroundTransparency = 1
content.Parent = win

-- status bar bawah
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 34)
statusBar.Position = UDim2.new(0, 12, 1, -40)
statusBar.BackgroundColor3 = T.panel
statusBar.BorderSizePixel = 0
statusBar.Parent = win
corner(statusBar, 9)

local statusTxt = Instance.new("TextLabel")
statusTxt.Size = UDim2.new(1, -16, 1, 0)
statusTxt.Position = UDim2.new(0, 10, 0, 0)
statusTxt.BackgroundTransparency = 1
statusTxt.Text = "siap"
statusTxt.Font = Enum.Font.Code
statusTxt.TextSize = 11
statusTxt.TextColor3 = T.txt2
statusTxt.TextXAlignment = Enum.TextXAlignment.Left
statusTxt.TextTruncate = Enum.TextTruncate.AtEnd
statusTxt.Parent = statusBar

hideBtn.MouseButton1Click:Connect(function()
  win.Visible = false; orb.Visible = true
end)
orb.MouseButton1Click:Connect(function()
  win.Visible = true; orb.Visible = false
end)
