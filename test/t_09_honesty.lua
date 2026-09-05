-- ---- t_09_honesty.lua ----
-- Menguji SATU hal: apakah ESP pernah menampilkan angka yang tidak dia
-- ketahui? Label boleh bilang "belum diketahui", tapi TIDAK boleh menampilkan
-- rarity/income yang salah dengan percaya diri.
local A = SAE

local function bareEgg(name, pos)
  local m = Instance.new("Model", MOCK.Workspace)
  m.Name = name
  local pp = Instance.new("Part", m)
  pp.Name = "Shell"
  pp.Position = pos or Vector3.new(1200, 5, 0)
  rawget(m, "_p").PrimaryPart = pp
  return m
end
local function clearAll()
  for _, e in ipairs(A.scanEggs()) do e.obj.Parent = nil end
end
local function byName()
  local t = {}
  for _, e in ipairs(A.scanEggs()) do t[e.obj.Name] = e end
  return t
end

sect("41. telur bernama generik: harus mengaku tidak tahu")
do
  clearAll()
  for i, n in ipairs({ "Egg", "Egg1", "Egg_03", "MysteryEgg", "Nest_Egg_7", "RandomEgg" }) do
    bareEgg(n, Vector3.new(1200 + i * 8, 5, 0))
  end
  local b = byName()
  local lied = {}
  for _, n in ipairs({ "Egg", "Egg1", "Egg_03", "MysteryEgg", "Nest_Egg_7", "RandomEgg" }) do
    local e = b[n]
    if e and (e.rar ~= nil or e.income ~= nil) then
      lied[#lied + 1] = n .. "->" .. tostring(e.rar) .. "/" .. tostring(e.income)
    end
  end
  check("6 telur generik terdeteksi", (function()
    local c = 0
    for _, n in ipairs({ "Egg", "Egg1", "Egg_03", "MysteryEgg", "Nest_Egg_7", "RandomEgg" }) do
      if b[n] then c = c + 1 end
    end
    return c == 6
  end)())
  check("nama generik TIDAK dikarang rarity/income-nya", #lied == 0,
    table.concat(lied, " "))
end

sect("42. nama menyesatkan: substring tidak boleh bikin klaim palsu")
do
  clearAll()
  -- semua ini BUKAN telur pet yang namanya terkandung di dalamnya
  local traps = {
    "GoldenBearEggCrate",   -- memuat "bear"
    "SpiderNestEgg",        -- memuat "spider" tapi ini sarang
    "EggBasket",            -- wadah
    "DogHouseEgg",          -- memuat "dog"
    "SnakeSkinEgg",         -- memuat "snake"
  }
  for i, n in ipairs(traps) do bareEgg(n, Vector3.new(1300 + i * 8, 5, 0)) end
  local b = byName()
  local claims = {}
  for _, n in ipairs(traps) do
    local e = b[n]
    if e and e.rar then
      claims[#claims + 1] = n .. " -> " .. e.rar .. " " .. tostring(e.pet)
        .. " " .. A.money(e.income)
    end
  end
  -- ini BUKAN pass/fail otomatis: dicetak supaya terlihat apa yang diklaim
  print("      klaim dari nama menyesatkan: "
    .. (#claims > 0 and table.concat(claims, " | ") or "(tidak ada)"))
  check("dicatat berapa nama menyesatkan yang tetap diklaim", true, #claims)
end

sect("43. income = nilai DASAR, bukan hasil akhir")
do
  clearAll()
  -- dua telur pet sama, berat sangat beda: income yang ditampilkan sama,
  -- padahal di game berat menentukan money/s. Ini batas yang harus diakui.
  local a1 = bareEgg("KitsuneEgg", Vector3.new(1400, 5, 0))
  local lbl = Instance.new("BillboardGui", a1)
  local t1 = Instance.new("TextLabel", lbl)
  t1.Text = "120 kg"

  local a2 = bareEgg("KitsuneEgg2", Vector3.new(1410, 5, 0))
  local lbl2 = Instance.new("BillboardGui", a2)
  local t2 = Instance.new("TextLabel", lbl2)
  t2.Text = "3240000 kg"

  local b = byName()
  local e1, e2 = b.KitsuneEgg, b.KitsuneEgg2
  check("berat berbeda terbaca", e1 and e2 and e1.wt ~= e2.wt,
    (e1 and e1.wt) .. " vs " .. (e2 and e2.wt))
  check("income yang ditampilkan SAMA walau berat beda (nilai dasar)",
    e1 and e2 and e1.income == e2.income, (e1 and e1.income))
end
