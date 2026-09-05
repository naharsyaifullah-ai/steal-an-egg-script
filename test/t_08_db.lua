-- ---- t_08_db.lua ----
-- Inti perbaikan v3: rarity & income datang dari DATABASE nama pet, jadi telur
-- TANPA label teks apa pun tetap terbaca. Dulu semuanya nil dan filter menolak
-- hampir semua telur — itu sebab "cuma Uncommon yang kena".
local A = SAE

local function bareEgg(name, pos)
  -- model telur polos: tidak ada BillboardGui, tidak ada teks rarity sama sekali
  local m = Instance.new("Model", MOCK.Workspace)
  m.Name = name
  local pp = Instance.new("Part", m)
  pp.Name = "Shell"
  pp.Position = pos or Vector3.new(600, 5, 0)
  rawget(m, "_p").PrimaryPart = pp
  return m
end

local function clearAll()
  for _, e in ipairs(A.scanEggs()) do e.obj.Parent = nil end
end

sect("31. database pet: rarity & income tanpa label teks")
do
  clearAll()
  local cases = {
    { "LeviathanEgg",  "Cosmic",    220000,     "Leviathan" },
    { "KitsuneEgg",    "Divine",    1800000000, "Kitsune" },
    { "StagEgg",       "Secret",    145000000,  "Stag" },
    { "ChickenEgg",    "Common",    1,          "Chicken" },
    { "BirdEgg",       "Uncommon",  8,          "Bird" },
    { "CraneEgg",      "Epic",      4000,       "Crane" },
    { "OniTigerEgg",   "Eternal",   600000000,  "Oni Tiger" },
    { "AnkylosaurusEgg", "Mythic",  120000,     "Ankylosaurus" },
    { "SnakeEgg",      "Legendary", 3600,       "Snake" },
    { "DodoEgg",       "Rare",      280,        "Dodo" },
  }
  for i, c in ipairs(cases) do bareEgg(c[1], Vector3.new(600 + i * 8, 5, 0)) end

  local eggs = A.scanEggs()
  check("10 telur polos terdeteksi", #eggs == 10, #eggs)

  local byName = {}
  for _, e in ipairs(eggs) do byName[e.obj.Name] = e end

  local okR, okI, okP = 0, 0, 0
  for _, c in ipairs(cases) do
    local e = byName[c[1]]
    if e and e.rar == c[2] then okR = okR + 1 end
    if e and e.income == c[3] then okI = okI + 1 end
    if e and e.pet == c[4] then okP = okP + 1 end
  end
  check("rarity benar untuk 10/10 telur polos", okR == 10, okR .. "/10")
  check("income benar untuk 10/10", okI == 10, okI .. "/10")
  check("nama pet benar untuk 10/10", okP == 10, okP .. "/10")

  check("Leviathan = Cosmic $220K/s (contoh yang diminta)",
    byName.LeviathanEgg and byName.LeviathanEgg.rar == "Cosmic"
    and A.money(byName.LeviathanEgg.income) == "$220K/s",
    byName.LeviathanEgg and A.money(byName.LeviathanEgg.income))
  check("biome ikut terbaca",
    byName.KitsuneEgg and byName.KitsuneEgg.biome == "Cherry",
    byName.KitsuneEgg and byName.KitsuneEgg.biome)
end

sect("32. jebakan nama: substring tidak boleh salah cocok")
do
  clearAll()
  bareEgg("KingMammothEgg", Vector3.new(700, 5, 0))
  bareEgg("MammothEgg",     Vector3.new(710, 5, 0))
  bareEgg("IceDragonEgg",   Vector3.new(720, 5, 0))
  bareEgg("LavaDragonEgg",  Vector3.new(730, 5, 0))
  bareEgg("SandSpiderEgg",  Vector3.new(740, 5, 0))
  bareEgg("SpiderEgg",      Vector3.new(750, 5, 0))
  bareEgg("KingSnakeEgg",   Vector3.new(760, 5, 0))
  bareEgg("SnakeEgg",       Vector3.new(770, 5, 0))

  local byName = {}
  for _, e in ipairs(A.scanEggs()) do byName[e.obj.Name] = e end

  check("KingMammoth = Cosmic (bukan Mythic-nya Mammoth)",
    byName.KingMammothEgg and byName.KingMammothEgg.rar == "Cosmic",
    byName.KingMammothEgg and byName.KingMammothEgg.rar)
  check("Mammoth tetap Mythic", byName.MammothEgg and byName.MammothEgg.rar == "Mythic",
    byName.MammothEgg and byName.MammothEgg.rar)
  check("IceDragon = Eternal $65M/s",
    byName.IceDragonEgg and byName.IceDragonEgg.income == 65000000,
    byName.IceDragonEgg and byName.IceDragonEgg.income)
  check("LavaDragon = Eternal $100M/s (beda dari IceDragon)",
    byName.LavaDragonEgg and byName.LavaDragonEgg.income == 100000000,
    byName.LavaDragonEgg and byName.LavaDragonEgg.income)
  check("SandSpider = Mythic $16K/s (bukan Spider $22K)",
    byName.SandSpiderEgg and byName.SandSpiderEgg.income == 16000,
    byName.SandSpiderEgg and byName.SandSpiderEgg.income)
  check("Spider tetap $22K/s", byName.SpiderEgg and byName.SpiderEgg.income == 22000,
    byName.SpiderEgg and byName.SpiderEgg.income)
  check("KingSnake = Secret $3.5M/s (bukan Legendary-nya Snake)",
    byName.KingSnakeEgg and byName.KingSnakeEgg.rar == "Secret",
    byName.KingSnakeEgg and byName.KingSnakeEgg.rar)
  check("Snake tetap Legendary", byName.SnakeEgg and byName.SnakeEgg.rar == "Legendary",
    byName.SnakeEgg and byName.SnakeEgg.rar)
end

sect("33. objek bukan telur tidak boleh dianggap telur")
do
  clearAll()
  -- "BearTrap" memuat "Bear" (pet Forest) tapi ini trap, bukan telur
  makePart("BearTrap", MOCK.Workspace, Vector3.new(800, 5, 0))
  makePart("SpiderWebDecor", MOCK.Workspace, Vector3.new(810, 5, 0))
  makeHostile(MOCK.Workspace, "TigerGuardian", Vector3.new(820, 5, 0))
  local eggs = A.scanEggs()
  check("trap/dekor/musuh tidak masuk daftar telur", #eggs == 0, #eggs)
  check("BearTrap tetap terdaftar sebagai trap",
    (function()
      for _, t in ipairs(A.scanTraps()) do
        if t.obj.Name == "BearTrap" then return true end
      end
      return false
    end)())

  -- bersihkan
  for _, n in ipairs({ "BearTrap", "SpiderWebDecor", "TigerGuardian" }) do
    local o = MOCK.Workspace:FindFirstChild(n)
    if o then o.Parent = nil end
  end
end

sect("34. filter rarity sekarang benar-benar kena semua tier")
do
  clearAll()
  local all = {
    { "ChickenEgg", "Common" }, { "BirdEgg", "Uncommon" }, { "DodoEgg", "Rare" },
    { "CraneEgg", "Epic" }, { "SnakeEgg", "Legendary" }, { "TigerEgg", "Mythic" },
    { "LeviathanEgg", "Cosmic" }, { "StagEgg", "Secret" },
    { "OniTigerEgg", "Eternal" }, { "KitsuneEgg", "Divine" },
  }
  for i, c in ipairs(all) do bareEgg(c[1], Vector3.new(500 + i * 6, 5, 0)) end

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(500, 5, 0)
  A.S.minWeight = 0
  A.S.minIncome = 0
  A.S.maxRange = 5000

  local hits = 0
  for _, c in ipairs(all) do
    for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = false end
    A.S.rarityPick[c[2]] = true
    local e = A.pickEgg()
    if e and e.obj.Name == c[1] then hits = hits + 1
    else print("      (filter " .. c[2] .. " -> " .. tostring(e and e.obj.Name)) end
  end
  check("10/10 tier memilih telur yang tepat", hits == 10, hits .. "/10")

  -- semua aktif → yang dipilih harus yang paling mahal
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = true end
  local top = A.pickEgg()
  check("semua tier aktif → pilih income tertinggi (Kitsune)",
    top and top.obj.Name == "KitsuneEgg", top and top.obj.Name)
end

sect("35. filter income minimum")
do
  A.S.minIncome = 1000000        -- $1M/s
  local e = A.pickEgg()
  check("hanya telur ≥$1M/s dipilih", e and e.income >= 1000000,
    e and A.money(e.income))

  A.S.minIncome = 2000000000     -- $2B/s: tidak ada
  local none = A.pickEgg()
  check("ambang mustahil → nil (tidak memaksa ambil)", none == nil,
    none and none.obj.Name)
  A.S.minIncome = 0
end

sect("36. jarak maksimum dihormati")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(0, 5, 0)
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = true end

  A.S.maxRange = 100            -- semua telur uji ada di x≈500+
  local far = A.pickEgg()
  check("telur di luar jangkauan diabaikan", far == nil, far and far.obj.Name)

  A.S.maxRange = 5000
  local near = A.pickEgg()
  check("jangkauan luas → telur ditemukan lagi", near ~= nil, near and near.obj.Name)
end

sect("37. mutasi: pengali & prioritas")
do
  clearAll()
  -- nama objek memuat mutasi, seperti di game: "Rainbow Kitsune Egg"
  bareEgg("Rainbow Kitsune Egg", Vector3.new(900, 5, 0))
  bareEgg("Kitsune Egg",         Vector3.new(910, 5, 0))
  bareEgg("Spirit Bloom Stag Egg", Vector3.new(920, 5, 0))

  local byName = {}
  for _, e in ipairs(A.scanEggs()) do byName[e.obj.Name] = e end

  local rk = byName["Rainbow Kitsune Egg"]
  check("mutasi Rainbow terbaca dari nama objek", rk and rk.mut == "Rainbow",
    rk and rk.mut)
  check("pengali Rainbow = 2.5", rk and rk.mult == 2.5, rk and rk.mult)
  check("rarity tetap Divine walau ada prefix mutasi", rk and rk.rar == "Divine",
    rk and rk.rar)
  check("income dasar tetap $1.8B/s", rk and rk.income == 1800000000, rk and rk.income)

  local sb = byName["Spirit Bloom Stag Egg"]
  check("Spirit Bloom terbaca (bukan 'Bloom')", sb and sb.mut == "Spirit Bloom",
    sb and sb.mut)
  check("pengali Spirit Bloom = 3", sb and sb.mult == 3, sb and sb.mult)

  A.S.preferMutasi = true
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(905, 5, 0)
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = true end
  local pick = A.pickEgg()
  check("Kitsune bermutasi dipilih di atas Kitsune biasa",
    pick and pick.obj.Name == "Rainbow Kitsune Egg", pick and pick.obj.Name)
end

sect("38. format uang & berat")
do
  check("$1/s", A.money(1) == "$1/s", A.money(1))
  check("$220K/s", A.money(220000) == "$220K/s", A.money(220000))
  check("$1.8B/s", A.money(1800000000) == "$1.8B/s", A.money(1800000000))
  check("$145M/s", A.money(145000000) == "$145M/s", A.money(145000000))
  check("nil → '?'", A.money(nil) == "?", A.money(nil))
  check("berat 3.24Mkg", A.kg(3240000) == "3.24Mkg", A.kg(3240000))
  check("berat 0 → nil", A.kg(0) == nil, A.kg(0))
end

sect("39. ESP menampilkan rarity + pet + income")
do
  clearAll()
  bareEgg("LeviathanEgg", Vector3.new(1000, 5, 0))
  bareEgg("Rainbow KitsuneEgg", Vector3.new(1010, 5, 0))
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(1000, 5, 0)

  A.S.espEgg = true
  A.S.espMinRarity = 1
  A.S.espRange = 3000
  A.S.espTrap = false; A.S.espGuard = false; A.S.espPlayer = false
  stepScheduler(40, 0.1)

  local texts = {}
  for _, k in ipairs(A.espFolder:GetChildren()) do
    if k.ClassName == "BillboardGui" then
      for _, tl in ipairs(k:GetChildren()) do
        if tl.ClassName == "TextLabel" then texts[#texts + 1] = tl.Text end
      end
    end
  end
  local blob = table.concat(texts, " ~ ")

  check("label memuat rarity", blob:find("Cosmic") ~= nil, blob:sub(1, 120))
  check("label memuat nama pet", blob:find("Leviathan") ~= nil, blob:sub(1, 120))
  check("label memuat income $/s", blob:find("%$220K/s") ~= nil, blob:sub(1, 120))
  check("label memuat biome", blob:find("Lake") ~= nil, blob:sub(1, 160))
  check("label memuat jarak", blob:find("%d+m") ~= nil)
  check("mutasi + income terkali muncul",
    blob:find("Rainbow") ~= nil and blob:find("4.5B") ~= nil, blob:sub(1, 220))

  -- saringan rarity minimum
  A.S.espMinRarity = 10        -- hanya Divine
  stepScheduler(40, 0.1)
  local t2 = {}
  for _, k in ipairs(A.espFolder:GetChildren()) do
    if k.ClassName == "BillboardGui" then
      for _, tl in ipairs(k:GetChildren()) do
        if tl.ClassName == "TextLabel" then t2[#t2 + 1] = tl.Text end
      end
    end
  end
  local b2 = table.concat(t2, " ~ ")
  check("saringan Divine menyembunyikan Cosmic", b2:find("Leviathan") == nil, b2:sub(1, 120))
  check("Divine tetap tampil", b2:find("Kitsune") ~= nil, b2:sub(1, 120))

  A.S.espEgg = false
  A.S.espMinRarity = 1
  stepScheduler(30, 0.1)
end

sect("40. tombol 'Perbaiki karakter'")
do
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  -- simulasi kondisi rusak seperti bug lama
  hum.PlatformStand = true
  hum.Sit = true
  local bv = Instance.new("BodyVelocity", CHR:FindFirstChild("HumanoidRootPart"))
  bv.Velocity = Vector3.new(50, 0, 0)

  local btn
  for _, c in ipairs(A.pages.PLAYER:GetDescendants()) do
    if c.ClassName == "TextButton" and c.Text == "Perbaiki karakter" then btn = c end
  end
  check("tombol Perbaiki karakter ada", btn ~= nil)
  if btn then
    rawget(btn, "_p").MouseButton1Click:Fire()
    check("PlatformStand dilepas", hum.PlatformStand == false, hum.PlatformStand)
    check("Sit dilepas", hum.Sit == false, hum.Sit)
    check("sisa BodyVelocity dibersihkan",
      CHR:FindFirstChild("HumanoidRootPart"):FindFirstChildOfClass("BodyVelocity") == nil)
    check("state GettingUp dipanggil",
      (function()
        for _, s in ipairs(rawget(hum, "_p")._stateChanges) do
          if s == "GettingUp" then return true end
        end
        return false
      end)(), table.concat(rawget(hum, "_p")._stateChanges, ","))
  end
end
