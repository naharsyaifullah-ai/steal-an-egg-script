-- ============ TAB: STEAL / FARM / PLAYER / ESP ============
makeTab("STEAL", 70)
makeTab("FARM", 62)
makeTab("PLAYER", 74)
makeTab("ESP", 56)

local pSteal  = makePage("STEAL")
local pFarm   = makePage("FARM")
local pPlayer = makePage("PLAYER")
local pEsp    = makePage("ESP")

-- --- STEAL ---
toggle(pSteal, "Auto Steal Egg", "jalan di tanah, tidak terbang",
  function() return S.stealOn end,
  function(v) S.stealOn = v; if not v then stopGlide() end end)

toggle(pSteal, "Bawa pulang ke base", "otomatis setor telur",
  function() return S.returnBase end, function(v) S.returnBase = v end)

toggle(pSteal, "Prioritas telur mutasi", "Spirit Bloom 3x > Rainbow 2.5x > Golden 2x",
  function() return S.preferMutasi end, function(v) S.preferMutasi = v end)

section(pSteal, "kecepatan steal")
slider(pSteal, "Kecepatan saat steal", 16, 1000,
  function() return S.stealSpeed end, function(v) S.stealSpeed = v end,
  function(v) return v .. " stud" end)
slider(pSteal, "Jeda antar steal", 0, 30,
  function() return math.floor(S.stealDelay * 10) end,
  function(v) S.stealDelay = v / 10 end,
  function(v) return string.format("%.1f s", v / 10) end)
slider(pSteal, "Jarak maksimum telur", 100, 5000,
  function() return S.maxRange end, function(v) S.maxRange = v end,
  function(v) return v .. " stud" end)

section(pSteal, "pilih rarity")

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
  b.Size = UDim2.new(0.25, -5, 1, 0)
  b.BackgroundColor3 = T.panel2
  b.Text = text
  b.Font = Enum.Font.GothamBold
  b.TextSize = 10
  b.TextColor3 = T.txt
  b.AutoButtonColor = false
  b.Parent = rowQuick
  corner(b, 8)
  b.MouseButton1Click:Connect(function()
    fn()
    for _, paint in pairs(rarityBtns) do paint() end
  end)
end
quick("Semua", function() for _, r in ipairs(RARITY) do S.rarityPick[r] = true end end)
quick("Kosong", function() for _, r in ipairs(RARITY) do S.rarityPick[r] = false end end)
quick("Top 3", function()
  for _, r in ipairs(RARITY) do S.rarityPick[r] = false end
  S.rarityPick.Secret = true; S.rarityPick.Eternal = true; S.rarityPick.Divine = true
end)
quick("Cosmic+", function()
  for _, r in ipairs(RARITY) do S.rarityPick[r] = false end
  S.rarityPick.Cosmic = true; S.rarityPick.Secret = true
  S.rarityPick.Eternal = true; S.rarityPick.Divine = true
end)

section(pSteal, "filter nilai")
slider(pSteal, "Income minimum", 0, 100,
  function()
    -- slider 0..100 dipetakan ke skala log $0 .. $1B
    if S.minIncome <= 0 then return 0 end
    return math.floor(math.log(S.minIncome) / math.log(10) * 100 / 9)
  end,
  function(v)
    if v <= 0 then S.minIncome = 0
    else S.minIncome = math.floor(10 ^ (v * 9 / 100)) end
  end,
  function(v)
    if v <= 0 then return "abaikan" end
    return money(math.floor(10 ^ (v * 9 / 100)))
  end)
slider(pSteal, "Berat minimum", 0, 5000000,
  function() return S.minWeight end, function(v) S.minWeight = v end,
  function(v) return v <= 0 and "abaikan" or (kg(v) or tostring(v)) end)

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
toggle(pPlayer, "Speed custom", "kecepatan jalan biasa",
  function() return S.speedOn end, function(v) S.speedOn = v end)
slider(pPlayer, "Kecepatan jalan", 16, 1000,
  function() return S.speed end, function(v) S.speed = v end,
  function(v) return v .. " stud" end)

section(pPlayer, "keamanan")
toggle(pPlayer, "Anti Trap", "geser jalur menjauh dari trap",
  function() return S.antiTrap end, function(v) S.antiTrap = v end)
toggle(pPlayer, "Anti Bat / Guard", "geser jalur menjauh dari musuh",
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
action(pPlayer, "Perbaiki karakter", function()
  -- lepas semua sisa gaya + PlatformStand: obat kalau karakter terhuyung
  stopGlide()
  local h = hum()
  if h then
    h.PlatformStand = false
    h.Sit = false
    h:ChangeState(Enum.HumanoidStateType.GettingUp)
    h.WalkSpeed = S.speedOn and S.speed or 16
  end
  S.status = "karakter dibereskan"
end)
action(pPlayer, "Reset karakter", function()
  local h = hum(); if h then h.Health = 0 end
end)

-- --- ESP ---
section(pEsp, "tampilkan")
toggle(pEsp, "ESP Telur", "rarity + nama pet + income $/s",
  function() return S.espEgg end, function(v) S.espEgg = v end)
toggle(pEsp, "ESP Trap", "tandai semua trap merah",
  function() return S.espTrap end, function(v) S.espTrap = v end)
toggle(pEsp, "ESP Bat / Guard", "musuh penjaga nest",
  function() return S.espGuard end, function(v) S.espGuard = v end)
toggle(pEsp, "ESP Pemain", "nama + jarak pemain lain",
  function() return S.espPlayer end, function(v) S.espPlayer = v end)

section(pEsp, "saringan tampilan")
slider(pEsp, "Rarity minimum", 1, 10,
  function() return S.espMinRarity end, function(v) S.espMinRarity = v end,
  function(v) return RARITY[math.clamp(v, 1, 10)] or "?" end)
slider(pEsp, "Jarak ESP", 200, 5000,
  function() return S.espRange end, function(v) S.espRange = v end,
  function(v) return v .. " stud" end)

section(pEsp, "isi map sekarang")
local infoBox = Instance.new("Frame")
infoBox.Size = UDim2.new(1, 0, 0, 138)
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
      statusTxt.Text = string.format("%s · dicuri: %d · %s", S.status, S.stolen, S.lastEgg)
    end)
  end
end)

task.spawn(function()
  while true do
    task.wait(2.5)
    pcall(function()
      if activePage ~= "ESP" then return end
      local eggs = scanEggs()
      local byR, known, best = {}, 0, nil
      for _, e in ipairs(eggs) do
        local k = e.rar or "?"
        byR[k] = (byR[k] or 0) + 1
        if e.income then
          known = known + 1
          local val = e.income * (e.mult or 1)
          if not best or val > (best.income * (best.mult or 1)) then best = e end
        end
      end
      local parts = {}
      for _, r in ipairs(RARITY) do
        if byR[r] then parts[#parts + 1] = r:sub(1, 3) .. ":" .. byR[r] end
      end
      if byR["?"] then parts[#parts + 1] = "??:" .. byR["?"] end

      local bestLine = "-"
      if best then
        bestLine = (best.mut and (best.mut .. " ") or "") .. (best.pet or "?")
          .. " " .. money(best.income * (best.mult or 1))
      end

      infoTxt.Text = table.concat({
        "telur     : " .. #eggs .. "  (dikenali: " .. known .. ")",
        "rincian   : " .. (#parts > 0 and table.concat(parts, " ") or "-"),
        "termahal  : " .. bestLine,
        "trap      : " .. #scanTraps(),
        "musuh     : " .. #scanHostiles(),
        "remote    : " .. #remotes,
      }, "\n")
    end)
  end
end)

print("[SAE v3] loaded · remote=" .. #remotes)
