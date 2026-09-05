-- ============ TAB: STEAL ============
makeTab("STEAL", 74)
makeTab("FARM", 66)
makeTab("PLAYER", 78)
makeTab("ESP", 62)

local pSteal  = makePage("STEAL")
local pFarm   = makePage("FARM")
local pPlayer = makePage("PLAYER")
local pEsp    = makePage("ESP")

-- --- STEAL ---
toggle(pSteal, "Auto Steal Egg", "gerak halus, tanpa teleport",
  function() return S.stealOn end,
  function(v) S.stealOn = v; if not v then stopGlide() end end)

toggle(pSteal, "Bawa pulang ke base", "otomatis setor telur",
  function() return S.returnBase end, function(v) S.returnBase = v end)

toggle(pSteal, "Prioritas telur mutasi", "Spirit Bloom > Rainbow > Golden",
  function() return S.preferMutasi end, function(v) S.preferMutasi = v end)

section(pSteal, "pilih rarity")

-- grid rarity 2 kolom
local rgrid = Instance.new("Frame")
rgrid.Size = UDim2.new(1, 0, 0, 0)
rgrid.AutomaticSize = Enum.AutomaticSize.Y
rgrid.BackgroundTransparency = 1
rgrid.Parent = pSteal

local gl = Instance.new("UIGridLayout")
gl.CellSize = UDim2.new(0.5, -4, 0, 36)
gl.CellPadding = UDim2.new(0, 7, 0, 7)
gl.Parent = rgrid

local rarityBtns = {}
for _, r in ipairs(RARITY) do
  local b = Instance.new("TextButton")
  b.BackgroundColor3 = T.panel
  b.Text = r
  b.Font = Enum.Font.GothamBold
  b.TextSize = 11
  b.AutoButtonColor = false
  b.Parent = rgrid
  corner(b, 8)
  local st = stroke(b, T.line, 1)

  local function paint()
    local on = S.rarityPick[r]
    b.BackgroundColor3 = on and T.panel2 or T.panel
    b.TextColor3 = on and RCOLOR[r] or T.txt2
    st.Color = on and RCOLOR[r] or T.line
    st.Thickness = on and 1.6 or 1
  end
  b.MouseButton1Click:Connect(function()
    S.rarityPick[r] = not S.rarityPick[r]; paint()
  end)
  paint()
  rarityBtns[r] = paint
end

local rowQuick = Instance.new("Frame")
rowQuick.Size = UDim2.new(1, 0, 0, 34)
rowQuick.BackgroundTransparency = 1
rowQuick.Parent = pSteal
local qll = Instance.new("UIListLayout")
qll.FillDirection = Enum.FillDirection.Horizontal
qll.Padding = UDim.new(0, 6)
qll.Parent = rowQuick

local function quick(text, fn)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0.333, -4, 1, 0)
  b.BackgroundColor3 = T.panel2
  b.Text = text
  b.Font = Enum.Font.GothamBold
  b.TextSize = 11
  b.TextColor3 = T.txt
  b.AutoButtonColor = false
  b.Parent = rowQuick
  corner(b, 8)
  b.MouseButton1Click:Connect(function()
    fn()
    for r, paint in pairs(rarityBtns) do paint() end
  end)
end
quick("Semua", function() for _, r in ipairs(RARITY) do S.rarityPick[r] = true end end)
quick("Kosong", function() for _, r in ipairs(RARITY) do S.rarityPick[r] = false end end)
quick("Top 3", function()
  for _, r in ipairs(RARITY) do S.rarityPick[r] = false end
  S.rarityPick.Secret = true; S.rarityPick.Eternal = true; S.rarityPick.Divine = true
end)

section(pSteal, "filter berat")
slider(pSteal, "Berat minimum", 0, 5000000,
  function() return S.minWeight end, function(v) S.minWeight = v end,
  function(v) return v <= 0 and "abaikan" or string.format("%d kg", v) end)

slider(pSteal, "Jeda antar steal", 0, 30,
  function() return math.floor(S.stealDelay * 10) end,
  function(v) S.stealDelay = v / 10 end,
  function(v) return string.format("%.1f s", v / 10) end)

-- --- FARM ---
section(pFarm, "otomatis")
toggle(pFarm, "Auto Hatch", "tetaskan telur begitu siap",
  function() return S.autoHatch end, function(v) S.autoHatch = v end)
toggle(pFarm, "Auto Claim uang", "ambil income pet",
  function() return S.autoClaim end, function(v) S.autoClaim = v end)
toggle(pFarm, "Auto Treadmill", "latih Speed saat idle",
  function() return S.autoTrain end, function(v) S.autoTrain = v end)
toggle(pFarm, "Auto Upgrade", "beli upgrade base bila mampu",
  function() return S.autoUpgrade end, function(v) S.autoUpgrade = v end)
toggle(pFarm, "Auto Sell pet", "jual pet duplikat",
  function() return S.autoSell end, function(v) S.autoSell = v end)

section(pFarm, "manual")
action(pFarm, "Hatch sekarang", function() fireMatch({ "hatch", "openegg", "incubat" }) end)
action(pFarm, "Claim semua uang", function() fireMatch({ "claim", "collectcash", "collectincome" }) end)
action(pFarm, "Tekan prompt terdekat", function() pressPromptsNear(30) end)

-- --- PLAYER ---
section(pPlayer, "gerak")
toggle(pPlayer, "Speed custom", "batas aman 1000 stud",
  function() return S.speedOn end, function(v) S.speedOn = v end)
slider(pPlayer, "Kecepatan", 16, 1000,
  function() return S.speed end, function(v) S.speed = v end,
  function(v) return v .. " stud" end)
toggle(pPlayer, "Gerak halus (glide)", "mendekat mulus, bukan teleport",
  function() return S.glide end, function(v) S.glide = v end)

section(pPlayer, "keamanan")
toggle(pPlayer, "Anti Trap", "hindari trap/spike/net otomatis",
  function() return S.antiTrap end, function(v) S.antiTrap = v end)
toggle(pPlayer, "Anti Bat / Guard", "menjauh saat musuh mendekat",
  function() return S.antiBat end, function(v) S.antiBat = v end)
toggle(pPlayer, "Anti Stun / Ragdoll", "tolak state jatuh & duduk",
  function() return S.antiStun end, function(v) S.antiStun = v end)
toggle(pPlayer, "No Fall Damage", "redam kecepatan jatuh",
  function() return S.noFall end, function(v) S.noFall = v end)
slider(pPlayer, "Radius hindar", 10, 80,
  function() return S.avoidRadius end, function(v) S.avoidRadius = v end,
  function(v) return v .. " stud" end)

section(pPlayer, "darurat")
action(pPlayer, "STOP semua", function()
  S.stealOn = false; S.autoHatch = false; S.autoClaim = false
  S.autoTrain = false; S.autoSell = false; S.autoUpgrade = false
  stopGlide()
  local h = hum(); if h then h.WalkSpeed = 16; h.PlatformStand = false end
  S.status = "semua dimatikan"
end, "gold")
action(pPlayer, "Reset karakter", function()
  local h = hum(); if h then h.Health = 0 end
end)

-- --- ESP ---
section(pEsp, "tampilkan")
toggle(pEsp, "ESP Telur", "warna sesuai rarity + berat + jarak",
  function() return S.espEgg end, function(v) S.espEgg = v end)
toggle(pEsp, "ESP Trap", "tandai semua trap merah",
  function() return S.espTrap end, function(v) S.espTrap = v end)
toggle(pEsp, "ESP Bat / Guard", "musuh penjaga nest",
  function() return S.espGuard end, function(v) S.espGuard = v end)
toggle(pEsp, "ESP Pemain", "nama + jarak pemain lain",
  function() return S.espPlayer end, function(v) S.espPlayer = v end)

section(pEsp, "info")
local infoBox = Instance.new("Frame")
infoBox.Size = UDim2.new(1, 0, 0, 96)
infoBox.BackgroundColor3 = T.panel
infoBox.BorderSizePixel = 0
infoBox.Parent = pEsp
corner(infoBox, 9)
local infoTxt = Instance.new("TextLabel")
infoTxt.Size = UDim2.new(1, -20, 1, -16)
infoTxt.Position = UDim2.new(0, 10, 0, 8)
infoTxt.BackgroundTransparency = 1
infoTxt.Text = "memindai..."
infoTxt.Font = Enum.Font.Code
infoTxt.TextSize = 11
infoTxt.TextColor3 = T.txt2
infoTxt.TextXAlignment = Enum.TextXAlignment.Left
infoTxt.TextYAlignment = Enum.TextYAlignment.Top
infoTxt.Parent = infoBox

action(pEsp, "Scan ulang remote", function()
  local n = indexRemotes()
  S.status = "remote terindeks: " .. n
end)

showPage("STEAL")

-- ============ STATUS TICKER ============
task.spawn(function()
  while true do
    task.wait(1)
    pcall(function()
      dot.BackgroundColor3 = S.stealOn and T.jade or T.txt2
      statusTxt.Text = string.format("%s · dicuri: %d · terakhir: %s", S.status, S.stolen, S.lastEgg)
    end)
  end
end)

task.spawn(function()
  while true do
    task.wait(3)
    pcall(function()
      if activePage ~= "ESP" then return end
      local eggs = scanEggs()
      local byR = {}
      for _, e in ipairs(eggs) do
        local k = e.rar or "?"
        byR[k] = (byR[k] or 0) + 1
      end
      local parts = {}
      for _, r in ipairs(RARITY) do
        if byR[r] then parts[#parts + 1] = r .. ":" .. byR[r] end
      end
      if byR["?"] then parts[#parts + 1] = "tanpa label:" .. byR["?"] end
      infoTxt.Text = table.concat({
        "telur di map : " .. #eggs,
        "trap         : " .. #scanTraps(),
        "musuh        : " .. #scanHostiles(),
        "remote       : " .. #remotes,
        "rincian      : " .. (#parts > 0 and table.concat(parts, "  ") or "-"),
      }, "\n")
    end)
  end
end)

print("[SAE v2] loaded · remote=" .. #remotes)
