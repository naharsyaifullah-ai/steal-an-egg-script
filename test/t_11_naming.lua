-- ---- t_11_naming.lua ----
-- Keluhan: "saat saya ESP malah 'pet tidak ada di database'".
-- Database sudah 106 pet, jadi masalahnya adalah PENCOCOKAN NAMA: game menyimpan
-- nama pet di tempat yang tidak dibaca v4 (nama induk, nama part anak, atau
-- Attribute). Blok ini menguji semua pola penamaan yang wajar.
local A = SAE
local W = MOCK.Workspace

local function clearEggs()
  for _, e in ipairs(A.scanEggs()) do e.obj.Parent = nil end
end

local function eggByName(n)
  for _, e in ipairs(A.scanEggs()) do
    if e.obj.Name == n then return e end
  end
  return nil
end

sect("54. nama pet di NAMA INDUK, objek sendiri generik")
do
  clearEggs()
  -- pola nyata: Nest "OniTiger" berisi Model "Egg"
  local nest = Instance.new("Model", W)
  nest.Name = "OniTigerNest"
  local egg = Instance.new("Model", nest)
  egg.Name = "Egg"
  local pp = Instance.new("Part", egg)
  pp.Name = "Shell"
  pp.Position = Vector3.new(6000, 5, 0)
  rawget(egg, "_p").PrimaryPart = pp

  local e = eggByName("Egg")
  check("telur bernama 'Egg' terdeteksi", e ~= nil)
  check("rarity diambil dari nama induk (Eternal)", e and e.rar == "Eternal",
    e and tostring(e.rar))
  check("nama pet terbaca Oni Tiger", e and e.pet == "Oni Tiger", e and tostring(e.pet))
  check("income $600M/s", e and e.income == 600000000, e and tostring(e.income))
end

sect("55. nama pet di ATTRIBUTE")
do
  clearEggs()
  local egg = Instance.new("Model", W)
  egg.Name = "Egg_01"
  local pp = Instance.new("Part", egg)
  pp.Position = Vector3.new(6100, 5, 0)
  rawget(egg, "_p").PrimaryPart = pp
  egg:SetAttribute("PetName", "Leviathan")

  local e = eggByName("Egg_01")
  check("telur dengan Attribute terdeteksi", e ~= nil)
  check("attribute dibaca -> Cosmic", e and e.rar == "Cosmic", e and tostring(e.rar))
  check("nama pet dari attribute", e and e.pet == "Leviathan", e and tostring(e.pet))
  check("income $220K/s", e and e.income == 220000, e and tostring(e.income))

  -- attribute pada part anak juga harus terbaca
  clearEggs()
  local egg2 = Instance.new("Model", W)
  egg2.Name = "Egg_02"
  local pp2 = Instance.new("Part", egg2)
  pp2.Name = "Mesh"
  pp2.Position = Vector3.new(6200, 5, 0)
  rawget(egg2, "_p").PrimaryPart = pp2
  pp2:SetAttribute("Pet", "Rhinotaur")
  local e2 = eggByName("Egg_02")
  check("attribute di part anak terbaca", e2 and e2.pet == "Rhinotaur",
    e2 and tostring(e2.pet))
  check("Rhinotaur Cosmic $17.5M/s", e2 and e2.income == 17500000,
    e2 and tostring(e2.income))
end

sect("56. nama pet di NAMA PART ANAK")
do
  clearEggs()
  local egg = Instance.new("Model", W)
  egg.Name = "Egg"
  local pp = Instance.new("Part", egg)
  pp.Name = "KitsuneMesh"          -- nama pet menempel di part
  pp.Position = Vector3.new(6300, 5, 0)
  rawget(egg, "_p").PrimaryPart = pp

  local e = eggByName("Egg")
  check("nama part anak dipakai untuk mencocokkan", e and e.pet == "Kitsune",
    e and tostring(e.pet))
  check("rarity Divine", e and e.rar == "Divine", e and tostring(e.rar))
  check("income $1.8B/s", e and e.income == 1800000000, e and tostring(e.income))
end

sect("57. nama pet di StringValue / TextLabel")
do
  clearEggs()
  local egg = Instance.new("Model", W)
  egg.Name = "Nest_Egg"
  local pp = Instance.new("Part", egg)
  pp.Position = Vector3.new(6400, 5, 0)
  rawget(egg, "_p").PrimaryPart = pp
  local sv = Instance.new("StringValue", egg)
  sv.Name = "Pet"
  sv.Value = "Mutant Shark"

  local e = eggByName("Nest_Egg")
  check("StringValue terbaca -> Mutant Shark", e and e.pet == "Mutant Shark",
    e and tostring(e.pet))
  check("Secret $215M/s", e and e.rar == "Secret" and e.income == 215000000,
    e and tostring(e.income))

  clearEggs()
  local egg2 = Instance.new("Model", W)
  egg2.Name = "Egg"
  local pp2 = Instance.new("Part", egg2)
  pp2.Position = Vector3.new(6500, 5, 0)
  rawget(egg2, "_p").PrimaryPart = pp2
  local bb = Instance.new("BillboardGui", egg2)
  local tl = Instance.new("TextLabel", bb)
  tl.Text = "Golden Gorilla King  ·  1,250,000 kg"

  local e2 = eggByName("Egg")
  check("TextLabel terbaca -> Gorilla King", e2 and e2.pet == "Gorilla King",
    e2 and tostring(e2.pet))
  check("mutasi Golden dari label", e2 and e2.mut == "Golden", e2 and tostring(e2.mut))
  check("berat dari label (1.25Mkg)", e2 and e2.wt == 1250000, e2 and tostring(e2.wt))
  check("income terkali mutasi 2x di ESP-siap", e2 and e2.mult == 2, e2 and tostring(e2.mult))
end

sect("58. variasi penulisan nama objek")
do
  local variants = {
    "Egg_Kitsune", "Kitsune_Egg", "EGG KITSUNE", "kitsune egg",
    "Egg-Kitsune", "KitsuneEgg01", "Kitsune Egg (Divine)",
  }
  local ok = 0
  for i, name in ipairs(variants) do
    clearEggs()
    local egg = Instance.new("Model", W)
    egg.Name = name
    local pp = Instance.new("Part", egg)
    pp.Position = Vector3.new(6600 + i * 10, 5, 0)
    rawget(egg, "_p").PrimaryPart = pp
    local e = eggByName(name)
    if e and e.pet == "Kitsune" then ok = ok + 1
    else print("      gagal: " .. name .. " -> " .. tostring(e and e.pet)) end
  end
  check("7/7 variasi penulisan tercocokkan", ok == 7, ok .. "/7")
end

sect("59. nama pet dengan angka / ukuran menempel")
do
  local cases = {
    { "HugeKitsuneEgg", "Kitsune" },
    { "MonstrousTRexEgg", "T-Rex" },
    { "GiantLeviathanEgg", "Leviathan" },
    { "Egg_Mantaris_Large", "Mantaris" },
  }
  local ok = 0
  for i, c in ipairs(cases) do
    clearEggs()
    local egg = Instance.new("Model", W)
    egg.Name = c[1]
    local pp = Instance.new("Part", egg)
    pp.Position = Vector3.new(6800 + i * 10, 5, 0)
    rawget(egg, "_p").PrimaryPart = pp
    local e = eggByName(c[1])
    if e and e.pet == c[2] then ok = ok + 1
    else print("      gagal: " .. c[1] .. " -> " .. tostring(e and e.pet)) end
  end
  check("4/4 nama dengan awalan ukuran tercocokkan", ok == 4, ok .. "/4")
end

sect("60. tombol diagnosa nama")
do
  clearEggs()
  -- satu telur cocok, satu benar-benar asing
  local a = Instance.new("Model", W)
  a.Name = "KoiEgg"
  local ap = Instance.new("Part", a); ap.Position = Vector3.new(7000, 5, 0)
  rawget(a, "_p").PrimaryPart = ap

  local b = Instance.new("Model", W)
  b.Name = "ZZZUnknownThingEgg"
  local bp = Instance.new("Part", b); bp.Position = Vector3.new(7010, 5, 0)
  rawget(b, "_p").PrimaryPart = bp
  b:SetAttribute("InternalId", "xyz123")

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(7000, 5, 0)

  local btn
  for _, c in ipairs(A.pages.ESP:GetDescendants()) do
    if c.ClassName == "TextButton" and c.Text == "Lihat nama asli telur" then btn = c end
  end
  check("tombol diagnosa ada", btn ~= nil)
  if btn then
    rawget(btn, "_p").MouseButton1Click:Fire()
    local t = A.diagTxt.Text
    check("laporan memuat telur yang cocok", t:find("OK koi") ~= nil, t:sub(1, 200))
    check("laporan menandai yang TAK COCOK",
      t:find("TAK COCOK") ~= nil, t:sub(1, 200))
    check("laporan memuat nama mentah objek asing",
      t:find("ZZZUnknownThingEgg") ~= nil, t:sub(1, 250))
    check("laporan menampilkan attribute objek asing",
      t:find("InternalId") ~= nil, t:sub(1, 320))
    check("laporan menghitung jumlah tak cocok",
      t:find("nama tak cocok: 1 dari 2") ~= nil, t:sub(-90))
  end
end

sect("61. objek bukan telur tetap tidak diklaim")
do
  clearEggs()
  makePart("BearTrap", W, Vector3.new(7100, 5, 0))
  makePart("TigerStatueDecor", W, Vector3.new(7110, 5, 0))
  makeHostile(W, "SpiderGuardian", Vector3.new(7120, 5, 0))
  local eggs = A.scanEggs()
  check("trap/dekor/musuh tidak masuk daftar telur", #eggs == 0, #eggs)
  for _, n in ipairs({ "BearTrap", "TigerStatueDecor", "SpiderGuardian" }) do
    local o = W:FindFirstChild(n); if o then o.Parent = nil end
  end
end

sect("62. blob teks memuat semua sumber")
do
  clearEggs()
  local nest = Instance.new("Model", W)
  nest.Name = "ParentNest"
  local egg = Instance.new("Model", nest)
  egg.Name = "TheEgg"
  local pp = Instance.new("Part", egg); pp.Name = "ChildPart"
  pp.Position = Vector3.new(7200, 5, 0)
  rawget(egg, "_p").PrimaryPart = pp
  egg:SetAttribute("MyAttr", "AttrValue")
  local sv = Instance.new("StringValue", egg); sv.Name = "SV"; sv.Value = "SVValue"

  local blob = A.textBlob(egg)
  check("blob memuat nama objek", blob:find("TheEgg") ~= nil)
  check("blob memuat nama induk", blob:find("ParentNest") ~= nil, blob:sub(1, 120))
  check("blob memuat nama part anak", blob:find("ChildPart") ~= nil, blob:sub(1, 160))
  check("blob memuat attribute", blob:find("AttrValue") ~= nil, blob:sub(1, 200))
  check("blob memuat StringValue", blob:find("SVValue") ~= nil, blob:sub(1, 240))
end
