-- ============ TAB: STEAL / FARM / PLAYER / ESP ============
-- Lebar ini menjaga seluruh lima tab tetap terlihat di jendela 330 px.
makeTab("STEAL", 52)
makeTab("FARM", 46)
makeTab("PLAYER", 56)
makeTab("ESP", 40)

local pSteal  = makePage("STEAL")
local pFarm   = makePage("FARM")
local pPlayer = makePage("PLAYER")
local pEsp    = makePage("ESP")

-- --- STEAL ---
toggle(pSteal, "Auto Steal Egg", "terbang datar, ambil, baru pulang",
  function() return S.stealOn end,
  function(v) S.stealOn = v; if not v then stopGlide() end end)

toggle(pSteal, "Bawa pulang ke base", "matikan kalau mau kumpul dulu",
  function() return S.returnBase end, function(v) S.returnBase = v end)

toggle(pSteal, "Ambil telur tak dikenal", "telur di luar database tetap diambil",
  function() return S.takeUnknown end, function(v) S.takeUnknown = v end)

toggle(pSteal, "Prioritas telur mutasi", "Spirit Bloom 3x > Rainbow 2.5x > Golden 2x",
  function() return S.preferMutasi end, function(v) S.preferMutasi = v end)

section(pSteal, "cara ambil (penting)")
-- Kalau auto steal tidak pernah berhasil, ini yang harus dipakai: script
-- merekam cara ambil yang BENAR dari tanganmu sendiri, lalu memutarnya ulang.
local learnBox = Instance.new("Frame")
learnBox.Size = UDim2.new(1, 0, 0, 132)
learnBox.BackgroundColor3 = T.panel
learnBox.BorderSizePixel = 0
learnBox.Parent = pSteal
corner(learnBox, 9)

local learnScroll = Instance.new("ScrollingFrame")
learnScroll.Size = UDim2.new(1, -14, 1, -12)
learnScroll.Position = UDim2.new(0, 8, 0, 6)
learnScroll.BackgroundTransparency = 1
learnScroll.BorderSizePixel = 0
learnScroll.ScrollBarThickness = 3
learnScroll.ScrollBarImageColor3 = T.line
learnScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
learnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
learnScroll.Parent = learnBox

local learnTxt = Instance.new("TextLabel")
learnTxt.Size = UDim2.new(1, 0, 0, 0)
learnTxt.AutomaticSize = Enum.AutomaticSize.Y
learnTxt.BackgroundTransparency = 1
learnTxt.Text = "belum merekam.\ntekan tombol di bawah, lalu ambil SATU telur pakai tanganmu sendiri."
learnTxt.Font = Enum.Font.Code
learnTxt.TextSize = 10
learnTxt.TextColor3 = T.txt2
learnTxt.TextXAlignment = Enum.TextXAlignment.Left
learnTxt.TextYAlignment = Enum.TextYAlignment.Top
learnTxt.TextWrapped = true
learnTxt.Parent = learnScroll

action(pSteal, "AJARI: ambil 1 telur manual", function()
  S.stealOn = false
  stopGlide()
  local ok = startLearning()
  learnTxt.Text = (ok
    and "MEREKAM. Sekarang ambil SATU telur seperti biasa (jalan ke telur,\ntekan tombol ambil di game).\n\nBegitu telur terbawa, cara ambilnya langsung dipelajari."
    or  "Executor tidak mendukung hook remote.\nMasih bisa belajar dari prompt/sentuhan: ambil satu telur manual sekarang.")
end, "gold")

action(pSteal, "Berhenti merekam", function()
  stopLearning()
  learnTxt.Text = SPY.summary()
end)

action(pSteal, "Lihat cara ambil terpelajari", function()
  learnTxt.Text = SPY.summary()
  pcall(function() setclipboard(SPY.summary()) end)
end)

toggle(pSteal, "Tembak remote tebakan", "HANYA kalau belum pernah diajari",
  function() return S.blindFire end, function(v) S.blindFire = v end)

slider(pSteal, "Jarak mendekat sebelum ambil", 3, 20,
  function() return S.approachDist end, function(v) S.approachDist = v end,
  function(v) return v .. " stud" end)

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
slider(pSteal, "Usaha ambil per telur", 1, 8,
  function() return S.grabTries end, function(v) S.grabTries = v end,
  function(v) return v .. "x" end)
slider(pSteal, "Radius abaikan base", 0, 200,
  function() return S.baseGuard end, function(v) S.baseGuard = v end,
  function(v) return v <= 0 and "mati" or (v .. " stud") end)

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
local function manualRemote(label, words)
  indexRemotes()
  local n = fireMatch(words)
  S.status = n > 0 and (label .. ": " .. n .. " remote dikirim")
    or (label .. ": remote tidak ditemukan")
end

action(pFarm, "Hatch sekarang", function()
  manualRemote("hatch", { "hatch", "openegg", "incubat" })
end)
action(pFarm, "Claim semua uang", function()
  manualRemote("claim", { "claim", "collectcash", "collectincome" })
end)
action(pFarm, "Tekan prompt terdekat", function()
  local n = pressPromptsNear(30)
  S.status = n > 0 and ("prompt: " .. n .. " ditekan") or "prompt: tidak ada di dekatmu"
end)

-- --- PLAYER ---
section(pPlayer, "gerak")
toggle(pPlayer, "Mode jalan kaki", "matikan = terbang datar (lebih cepat)",
  function() return S.walkMode end,
  function(v) S.walkMode = v; stopGlide() end)
toggle(pPlayer, "Speed custom", "kecepatan gerak umum",
  function() return S.speedOn end, function(v) S.speedOn = v end)
slider(pPlayer, "Kecepatan", 16, 1000,
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
toggle(pEsp, "Tampilkan telur tak dikenal", "pet di luar database tetap ditandai",
  function() return S.espUnknown end, function(v) S.espUnknown = v end)
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

-- ============ DIAGNOSA NAMA TELUR ============
-- Kalau ESP bilang "pet belum ada di database", masalahnya bukan datanya
-- kurang — tapi nama objek di game tidak cocok dengan pola yang dicari.
-- Tombol ini menampilkan nama MENTAH objek telur di sekitar (dan menyalinnya
-- ke clipboard) supaya nama aslinya bisa ditambahkan ke database.
section(pEsp, "diagnosa nama")
local diagBox = Instance.new("Frame")
diagBox.Size = UDim2.new(1, 0, 0, 150)
diagBox.BackgroundColor3 = T.panel
diagBox.BorderSizePixel = 0
diagBox.Parent = pEsp
corner(diagBox, 9)

local diagScroll = Instance.new("ScrollingFrame")
diagScroll.Size = UDim2.new(1, -14, 1, -12)
diagScroll.Position = UDim2.new(0, 8, 0, 6)
diagScroll.BackgroundTransparency = 1
diagScroll.BorderSizePixel = 0
diagScroll.ScrollBarThickness = 3
diagScroll.ScrollBarImageColor3 = T.line
diagScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
diagScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
diagScroll.Parent = diagBox

local diagTxt = Instance.new("TextLabel")
diagTxt.Size = UDim2.new(1, 0, 0, 0)
diagTxt.AutomaticSize = Enum.AutomaticSize.Y
diagTxt.BackgroundTransparency = 1
diagTxt.Text = "tekan 'Lihat nama asli telur' di bawah"
diagTxt.Font = Enum.Font.Code
diagTxt.TextSize = 10
diagTxt.TextColor3 = T.txt2
diagTxt.TextXAlignment = Enum.TextXAlignment.Left
diagTxt.TextYAlignment = Enum.TextYAlignment.Top
diagTxt.TextWrapped = true
diagTxt.Parent = diagScroll

action(pEsp, "Lihat nama asli telur", function()
  local eggs = scanEggs()
  local lines = {}
  local unknown = {}
  for i, e in ipairs(eggs) do
    if i > 14 then break end
    local mark = e.key and ("OK " .. e.key) or "?? TAK COCOK"
    lines[#lines + 1] = mark .. "  <- " .. tostring(e.obj.Name)
      .. "  [" .. tostring(e.obj.ClassName) .. "]"
    if not e.key then
      unknown[#unknown + 1] = tostring(e.obj.Name)
      -- tampilkan juga nama induk & anak: nama pet sering ada di sana
      local kids = {}
      for _, d in ipairs(e.obj:GetChildren()) do
        kids[#kids + 1] = d.Name
        if #kids >= 5 then break end
      end
      lines[#lines + 1] = "     induk: " .. tostring(e.obj.Parent and e.obj.Parent.Name)
      if #kids > 0 then lines[#lines + 1] = "     anak : " .. table.concat(kids, ", ") end
      local ok, attrs = pcall(function() return e.obj:GetAttributes() end)
      if ok and type(attrs) == "table" then
        local a = {}
        for k, v in pairs(attrs) do a[#a + 1] = k .. "=" .. tostring(v) end
        if #a > 0 then lines[#lines + 1] = "     attr : " .. table.concat(a, ", ") end
      end
    end
  end
  if #eggs == 0 then
    diagTxt.Text = "tidak ada objek telur terdeteksi di sekitar.\n"
      .. "berarti nama objeknya tidak memuat kata 'egg' DAN bukan nama pet.\n"
      .. "pakai tombol di bawah untuk melihat objek apa saja yang dekat."
  else
    diagTxt.Text = table.concat(lines, "\n")
      .. "\n\nnama tak cocok: " .. #unknown .. " dari " .. #eggs
      .. "\n(disalin ke clipboard kalau executor mendukung)"
  end
  local blob = table.concat(unknown, "\n")
  pcall(function() setclipboard(blob) end)
  S.status = "diagnosa: " .. #eggs .. " telur, " .. #unknown .. " tak cocok"
end, "gold")

action(pEsp, "Lihat objek terdekat (semua)", function()
  local h = hrp()
  if not h then diagTxt.Text = "karakter tidak ada"; return end
  local near = {}
  for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("Model") or v:IsA("BasePart") then
      local p = posOf(v)
      if p then
        local d = dist(h.Position, p)
        if d < 90 then near[#near + 1] = { n = v.Name, c = v.ClassName, d = d } end
      end
    end
  end
  table.sort(near, function(a, b) return a.d < b.d end)
  local lines = {}
  for i = 1, math.min(24, #near) do
    lines[#lines + 1] = string.format("%3dm  %s  [%s]",
      math.floor(near[i].d), near[i].n, near[i].c)
  end
  diagTxt.Text = (#lines > 0 and table.concat(lines, "\n") or "tidak ada objek dekat")
    .. "\n\ntotal " .. #near .. " objek dalam 90 stud"
  pcall(function()
    local blob = {}
    for i = 1, math.min(40, #near) do blob[#blob + 1] = near[i].n end
    setclipboard(table.concat(blob, "\n"))
  end)
  S.status = "diagnosa objek: " .. #near .. " dalam 90 stud"
end)

showPage("STEAL")

-- ============ STATUS TICKER ============
task.spawn(function()
  while true do
    task.wait(1)
    pcall(function()
      dot.BackgroundColor3 = S.stealOn and T.jade or T.txt2
      statusTxt.Text = string.format("%s · ok:%d gagal:%d · %s",
        S.status, S.stolen, S.fails, S.lastGrab)
    end)
  end
end)

task.spawn(function()
  while true do
    task.wait(2.5)
    pcall(function()
      if activePage ~= "ESP" then return end
      local eggs = scanEggs()
      local byR, known, best, mine = {}, 0, nil, 0
      for _, e in ipairs(eggs) do
        local k = e.rar or "?"
        byR[k] = (byR[k] or 0) + 1
        if e.mine then mine = mine + 1 end
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
          .. " " .. (money(best.income * (best.mult or 1)) or "?")
      end

      infoTxt.Text = table.concat({
        "telur     : " .. #eggs .. "  (income diketahui: " .. known .. ")",
        "milikku   : " .. mine .. "  (diabaikan saat steal)",
        "rincian   : " .. (#parts > 0 and table.concat(parts, " ") or "-"),
        "termahal  : " .. bestLine,
        "trap/musuh: " .. #scanTraps() .. " / " .. #scanHostiles(),
        "remote    : " .. #remotes .. "  · database: " .. DB_COUNT .. " pet",
      }, "\n")
    end)
  end
end)

-- ticker: perbarui panel belajar supaya hasilnya terlihat tanpa menekan apa pun
task.spawn(function()
  local last = ""
  while true do
    task.wait(1)
    pcall(function()
      if activePage ~= "STEAL" then return end
      local s = SPY.summary()
      if s ~= last then last = s; learnTxt.Text = s end
    end)
  end
end)

print("[SAE v5] loaded · remote=" .. #remotes .. " · db=" .. DB_COUNT)
