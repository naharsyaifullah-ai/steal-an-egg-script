-- ============ UI: komponen ============
local pages, tabs = {}, {}
local activePage = nil

local function makePage(name)
  local sc = Instance.new("ScrollingFrame")
  sc.Size = UDim2.new(1, 0, 1, 0)
  sc.BackgroundTransparency = 1
  sc.BorderSizePixel = 0
  sc.ScrollBarThickness = 3
  sc.ScrollBarImageColor3 = T.line
  sc.CanvasSize = UDim2.new(0, 0, 0, 0)
  sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
  sc.Visible = false
  sc.Parent = content

  local ll = Instance.new("UIListLayout")
  ll.Padding = UDim.new(0, 7)
  ll.SortOrder = Enum.SortOrder.LayoutOrder
  ll.Parent = sc

  local pd = Instance.new("UIPadding")
  pd.PaddingRight = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 10)
  pd.Parent = sc

  pages[name] = sc
  return sc
end

local function showPage(name)
  for n, p in pairs(pages) do p.Visible = (n == name) end
  for n, b in pairs(tabs) do
    local on = (n == name)
    b.BackgroundColor3 = on and T.panel2 or T.panel
    b.TextColor3 = on and T.gold or T.txt2
  end
  activePage = name
end

local function makeTab(name, w)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0, w, 1, 0)
  b.BackgroundColor3 = T.panel
  b.Text = name
  b.Font = Enum.Font.GothamBold
  b.TextSize = 12
  b.TextColor3 = T.txt2
  b.AutoButtonColor = false
  b.Parent = tabbar
  corner(b, 8)
  tabs[name] = b
  b.MouseButton1Click:Connect(function() showPage(name) end)
  return b
end

-- baris toggle
local function toggle(page, text, sub, get, set)
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0, sub and 50 or 42)
  row.BackgroundColor3 = T.panel
  row.BorderSizePixel = 0
  row.Parent = page
  corner(row, 9)

  local t = Instance.new("TextLabel")
  t.Size = UDim2.new(1, -70, 0, sub and 20 or 42)
  t.Position = UDim2.new(0, 12, 0, sub and 7 or 0)
  t.BackgroundTransparency = 1
  t.Text = text
  t.Font = Enum.Font.GothamMedium
  t.TextSize = 13
  t.TextColor3 = T.txt
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.Parent = row

  if sub then
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, -70, 0, 16)
    s.Position = UDim2.new(0, 12, 0, 26)
    s.BackgroundTransparency = 1
    s.Text = sub
    s.Font = Enum.Font.Gotham
    s.TextSize = 10
    s.TextColor3 = T.txt2
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Parent = row
  end

  local sw = Instance.new("TextButton")
  sw.Size = UDim2.new(0, 44, 0, 24)
  sw.Position = UDim2.new(1, -56, 0.5, -12)
  sw.BackgroundColor3 = T.panel2
  sw.Text = ""
  sw.AutoButtonColor = false
  sw.Parent = row
  corner(sw, 12)

  local knob = Instance.new("Frame")
  knob.Size = UDim2.new(0, 18, 0, 18)
  knob.Position = UDim2.new(0, 3, 0.5, -9)
  knob.BackgroundColor3 = T.txt2
  knob.BorderSizePixel = 0
  knob.Parent = sw
  corner(knob, 9)

  local function paint()
    local on = get()
    TweenService:Create(sw, TweenInfo.new(0.16), {
      BackgroundColor3 = on and T.jade or T.panel2 }):Play()
    TweenService:Create(knob, TweenInfo.new(0.16), {
      Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
      BackgroundColor3 = on and Color3.fromRGB(6, 24, 16) or T.txt2 }):Play()
  end
  sw.MouseButton1Click:Connect(function() set(not get()); paint() end)
  paint()
  return row
end

-- slider
local function slider(page, text, min, max, get, set, fmt)
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0, 58)
  row.BackgroundColor3 = T.panel
  row.BorderSizePixel = 0
  row.Parent = page
  corner(row, 9)

  local t = Instance.new("TextLabel")
  t.Size = UDim2.new(1, -24, 0, 20)
  t.Position = UDim2.new(0, 12, 0, 8)
  t.BackgroundTransparency = 1
  t.Text = text
  t.Font = Enum.Font.GothamMedium
  t.TextSize = 12
  t.TextColor3 = T.txt
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.Parent = row

  local val = Instance.new("TextLabel")
  val.Size = UDim2.new(0, 90, 0, 20)
  val.Position = UDim2.new(1, -102, 0, 8)
  val.BackgroundTransparency = 1
  val.Text = ""
  val.Font = Enum.Font.Code
  val.TextSize = 12
  val.TextColor3 = T.gold
  val.TextXAlignment = Enum.TextXAlignment.Right
  val.Parent = row

  local track = Instance.new("Frame")
  track.Size = UDim2.new(1, -24, 0, 8)
  track.Position = UDim2.new(0, 12, 0, 38)
  track.BackgroundColor3 = T.panel2
  track.BorderSizePixel = 0
  track.Parent = row
  corner(track, 4)

  local fill = Instance.new("Frame")
  fill.Size = UDim2.new(0, 0, 1, 0)
  fill.BackgroundColor3 = T.gold
  fill.BorderSizePixel = 0
  fill.Parent = track
  corner(fill, 4)

  local grab = Instance.new("TextButton")
  grab.Size = UDim2.new(1, 0, 0, 30)
  grab.Position = UDim2.new(0, 0, 0, -11)
  grab.BackgroundTransparency = 1
  grab.Text = ""
  grab.Parent = track

  local function paint()
    local v = get()
    local a = (v - min) / (max - min)
    fill.Size = UDim2.new(math.clamp(a, 0, 1), 0, 1, 0)
    val.Text = fmt and fmt(v) or tostring(math.floor(v))
  end

  local dragging = false
  local function setFromX(x)
    local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
    set(math.floor(min + a * (max - min)))
    paint()
  end
  grab.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      dragging = true; setFromX(i.Position.X)
    end
  end)
  grab.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      dragging = false
    end
  end)
  game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
      setFromX(i.Position.X)
    end
  end)
  paint()
  return row
end

-- judul seksi
local function section(page, text)
  local l = Instance.new("TextLabel")
  l.Size = UDim2.new(1, 0, 0, 24)
  l.BackgroundTransparency = 1
  l.Text = string.upper(text)
  l.Font = Enum.Font.GothamBold
  l.TextSize = 10
  l.TextColor3 = T.txt2
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.Parent = page
  return l
end

-- tombol aksi
local function action(page, text, fn, tone)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1, 0, 0, 40)
  b.BackgroundColor3 = tone == "gold" and T.gold or T.panel2
  b.Text = text
  b.Font = Enum.Font.GothamBold
  b.TextSize = 12
  b.TextColor3 = tone == "gold" and Color3.fromRGB(20, 14, 4) or T.txt
  b.AutoButtonColor = false
  b.Parent = page
  corner(b, 9)
  b.MouseButton1Click:Connect(function() pcall(fn) end)
  return b
end
