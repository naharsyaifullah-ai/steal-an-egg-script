-- ---- t_10_v4.lua ----
-- Menguji tiga keluhan v3 secara langsung:
--   1. "hop itu terbang tapi lurus, ga terbang ke atas" -> Y dijaga, gerak datar
--   2. "malah jalan bego sekali"                        -> default terbang, cepat
--   3. "mundar mandir di base, steal ga ke-steal"       -> telur base diabaikan,
--                                                          gagal ambil diakui
local A = SAE

local function bareEgg(name, pos)
  local m = Instance.new("Model", MOCK.Workspace)
  m.Name = name
  local pp = Instance.new("Part", m)
  pp.Name = "Shell"
  pp.Position = pos
  rawget(m, "_p").PrimaryPart = pp
  return m
end
local function clearEggs()
  for _, e in ipairs(A.scanEggs()) do e.obj.Parent = nil end
end

sect("44. hop = terbang DATAR, bukan naik ke langit")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  A.S.walkMode = false
  A.S.antiTrap = false
  A.S.antiBat = false
  A.S.speed = 300

  hrp.Position = Vector3.new(0, 40, 0)     -- mulai di ketinggian 40
  local target = Vector3.new(400, 40, 0)   -- target ketinggian sama

  local ys, xs = { hrp.Position.Y }, { hrp.Position.X }
  local co = coroutine.create(function() A.hopTo(target, 30) end)
  for _ = 1, 400 do
    if coroutine.status(co) == "dead" then break end
    coroutine.resume(co)
    PHYSICS_STEP(0.06)
    ys[#ys + 1] = hrp.Position.Y
    xs[#xs + 1] = hrp.Position.X
  end

  local maxUp, maxDown = 0, 0
  for _, y in ipairs(ys) do
    maxUp = math.max(maxUp, y - 40)
    maxDown = math.max(maxDown, 40 - y)
  end
  check("sampai di target (horizontal)", math.abs(hrp.Position.X - 400) < 15,
    hrp.Position.X)
  check("TIDAK naik ke atas (drift ke atas < 1 stud)", maxUp < 1, maxUp)
  check("TIDAK jatuh (drift ke bawah < 1 stud)", maxDown < 1, maxDown)
  check("banyak langkah kecil, bukan lompat", #xs > 15, #xs)

  -- kecepatan vertikal harus nol saat ketinggian sudah sama
  hrp.Position = Vector3.new(0, 40, 0)
  local co2 = coroutine.create(function() A.hopTo(Vector3.new(400, 40, 0), 5) end)
  coroutine.resume(co2)
  local bv = hrp:FindFirstChildOfClass("BodyVelocity")
  check("BodyVelocity dipakai untuk terbang", bv ~= nil)
  check("komponen Y kecepatan = 0", bv and math.abs(bv.Velocity.Y) < 0.001,
    bv and bv.Velocity.Y)
  check("kecepatan horizontal sesuai slider", bv and
    math.abs(math.sqrt(bv.Velocity.X ^ 2 + bv.Velocity.Z ^ 2) - 300) < 1,
    bv and bv.Velocity.X)
  A.stopGlide()
  check("stopGlide melepas BodyVelocity", hrp:FindFirstChildOfClass("BodyVelocity") == nil)
  check("PlatformStand tidak pernah true (bukan ragdoll)", hum.PlatformStand == false)
end

sect("45. beda ketinggian: naik pelan & terbatas")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(0, 5, 0)
  local co = coroutine.create(function() A.hopTo(Vector3.new(300, 200, 0), 5) end)
  coroutine.resume(co)
  local bv = hrp:FindFirstChildOfClass("BodyVelocity")
  check("naik hanya kalau target lebih tinggi", bv and bv.Velocity.Y > 0,
    bv and bv.Velocity.Y)
  check("kecepatan naik dibatasi 18 stud/s", bv and bv.Velocity.Y <= 18.001,
    bv and bv.Velocity.Y)
  A.stopGlide()
end

sect("46. mode jalan kaki masih tersedia sebagai pilihan")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  A.S.walkMode = true
  hrp.Position = Vector3.new(0, 5, 0)
  rawget(hum, "_p")._moveCount = 0

  local co = coroutine.create(function() A.moveTo(Vector3.new(200, 5, 0), 5) end)
  coroutine.resume(co)
  check("walkMode memakai Humanoid:MoveTo", rawget(hum, "_p")._moveCount > 0,
    rawget(hum, "_p")._moveCount)
  check("walkMode tidak membuat BodyVelocity",
    hrp:FindFirstChildOfClass("BodyVelocity") == nil)
  A.stopGlide()

  A.S.walkMode = false
  hrp.Position = Vector3.new(0, 5, 0)
  local co2 = coroutine.create(function() A.moveTo(Vector3.new(200, 5, 0), 5) end)
  coroutine.resume(co2)
  check("default (walkMode off) memakai terbang datar",
    hrp:FindFirstChildOfClass("BodyVelocity") ~= nil)
  A.stopGlide()
end

sect("47. telur di base sendiri diabaikan (stop mundar-mandir)")
do
  clearEggs()
  local base = A.myBase()
  check("base terdeteksi", base ~= nil, base and base.X)

  -- satu telur PERSIS di base, satu jauh di lapangan
  bareEgg("KitsuneEgg", Vector3.new(base.X + 5, base.Y + 2, base.Z + 5))
  bareEgg("StagEgg", Vector3.new(base.X + 900, base.Y, base.Z))

  local eggs = A.scanEggs()
  local atBase, far = nil, nil
  for _, e in ipairs(eggs) do
    if e.obj.Name == "KitsuneEgg" then atBase = e end
    if e.obj.Name == "StagEgg" then far = e end
  end
  check("telur di base ditandai milikku", atBase and atBase.mine == true,
    atBase and atBase.mine)
  check("telur jauh TIDAK ditandai milikku", far and far.mine == false,
    far and far.mine)

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(base.X, base.Y, base.Z)
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = true end
  A.S.maxRange = 5000
  A.S.minIncome = 0
  A.S.minWeight = 0

  local pick = A.pickEgg()
  check("Kitsune di base TIDAK dipilih walau paling mahal",
    pick and pick.obj.Name == "StagEgg", pick and pick.obj.Name)

  -- matikan penjagaan base: sekarang boleh
  A.S.baseGuard = 0
  local pick2 = A.pickEgg()
  check("baseGuard=0 mengizinkan telur di base lagi",
    pick2 and pick2.obj.Name == "KitsuneEgg", pick2 and pick2.obj.Name)
  A.S.baseGuard = 60
end

sect("48. telur di tangan sendiri tidak dipilih ulang")
do
  clearEggs()
  local egg = bareEgg("OniTigerEgg", Vector3.new(2000, 5, 0))
  local eggs = A.scanEggs()
  check("telur di lapangan bukan milikku", eggs[1] and eggs[1].mine == false,
    eggs[1] and eggs[1].mine)

  egg.Parent = CHR          -- sekarang dibawa
  local eggs2 = A.scanEggs()
  local held = nil
  for _, e in ipairs(eggs2) do if e.obj == egg then held = e end end
  check("telur yang dibawa ditandai milikku", held and held.mine == true,
    held and held.mine)

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(2000, 5, 0)
  local pick = A.pickEgg()
  check("telur yang dibawa tidak dipilih lagi", pick == nil, pick and pick.obj.Name)
  egg.Parent = nil
end

sect("49. usaha ambil: prompt di dalam telur + semua part disentuh")
do
  clearEggs()
  local egg = bareEgg("LeviathanEgg", Vector3.new(3000, 5, 0))
  -- dua part tambahan + satu prompt di dalam model telur
  local p2 = Instance.new("Part", egg); p2.Name = "Top"; p2.Position = Vector3.new(3000, 7, 0)
  local p3 = Instance.new("Part", egg); p3.Name = "Base"; p3.Position = Vector3.new(3000, 3, 0)
  local prompt = Instance.new("ProximityPrompt", egg)
  prompt.HoldDuration = 5          -- game sering pasang tahan-tekan
  prompt.MaxActivationDistance = 5

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(3000, 5, 0)

  local touchBefore = TOUCH_FIRED
  local promptBefore = PROMPT_FIRED
  local n = A.promptsInside(egg, 26)
  check("prompt di dalam telur ditekan", n >= 1, n)
  check("HoldDuration dinolkan agar tekan berhasil", prompt.HoldDuration == 0,
    prompt.HoldDuration)
  check("MaxActivationDistance dinaikkan", prompt.MaxActivationDistance >= 80,
    prompt.MaxActivationDistance)
  check("RequiresLineOfSight dimatikan", prompt.RequiresLineOfSight == false)
  check("counter prompt executor naik", PROMPT_FIRED > promptBefore)

  local t = A.touchAllParts(egg)
  check("SEMUA part telur disentuh (3 part)", t == 3, t)
  check("counter touch executor naik", TOUCH_FIRED > touchBefore)
end

sect("50. heldByMe: kedekatan saja bukan bukti")
do
  clearEggs()
  local egg = bareEgg("KoiEgg", Vector3.new(4000, 5, 0))
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(4000, 5, 0)     -- berdiri PERSIS di telur

  check("berdiri di sebelah telur ≠ sudah memegang",
    A.heldByMe(egg, 0) == false, A.heldByMe(egg, 0))

  egg.Parent = CHR
  check("telur jadi anak karakter = terbawa", A.heldByMe(egg, 0) == true)

  egg.Parent = MOCK.Workspace
  check("dikembalikan ke Workspace = tidak terbawa", A.heldByMe(egg, 0) == false)

  -- telur hilang saat kita jauh: bukan keberhasilan kita
  egg.Parent = nil
  check("telur hilang & kita jauh (500 stud) = BUKAN terbawa",
    A.heldByMe(egg, 500) == false, A.heldByMe(egg, 500))
  check("telur hilang saat kita di sisinya = terbawa",
    A.heldByMe(egg, 3) == true, A.heldByMe(egg, 3))
  check("telur hilang tanpa data jarak = tidak diklaim",
    A.heldByMe(egg, nil) == false, A.heldByMe(egg, nil))
end

sect("51. ESP tidak lagi menulis 'belum diketahui' untuk pet dikenal")
do
  clearEggs()
  bareEgg("MantarisEgg", Vector3.new(5000, 5, 0))     -- Titan Temple, Cosmic
  bareEgg("GorillaKingEgg", Vector3.new(5010, 5, 0))  -- Titan Temple, Eternal
  bareEgg("NightflameEgg", Vector3.new(5020, 5, 0))   -- Divine, income nil
  bareEgg("WeirdThingEgg", Vector3.new(5030, 5, 0))   -- benar-benar tak dikenal

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(5000, 5, 0)
  A.S.espEgg = true
  A.S.espMinRarity = 1
  A.S.espUnknown = true
  A.S.espRange = 3000
  A.S.espTrap = false; A.S.espGuard = false; A.S.espPlayer = false
  stepScheduler(40, 0.1)

  local lines = {}
  for _, k in ipairs(A.espFolder:GetChildren()) do
    if k.ClassName == "BillboardGui" then
      for _, tl in ipairs(k:GetChildren()) do
        if tl.ClassName == "TextLabel" then lines[#lines + 1] = tl.Text end
      end
    end
  end
  local blob = table.concat(lines, " ~ ")

  check("Mantaris Cosmic $11M/s tampil",
    blob:find("Mantaris") ~= nil and blob:find("%$11M/s") ~= nil, blob:sub(1, 200))
  check("Gorilla King Eternal $880M/s tampil",
    blob:find("Gorilla King") ~= nil and blob:find("%$880M/s") ~= nil, blob:sub(1, 260))
  check("Nightflame: rarity tampil, income diakui tak dipublikasikan",
    blob:find("Nightflame") ~= nil and blob:find("tak dipublikasikan") ~= nil,
    blob:sub(1, 300))
  check("pet dikenal TIDAK ditulis 'belum diketahui'",
    blob:find("income belum diketahui") == nil, blob:sub(1, 200))
  check("telur tak dikenal pakai nama objeknya, bukan teks kosong",
    blob:find("WeirdThing") ~= nil, blob:sub(1, 320))
  check("biome Titan tampil", blob:find("Titan") ~= nil, blob:sub(1, 200))

  A.S.espEgg = false
  stepScheduler(30, 0.1)
end

sect("52. database v4: 106 pet, Titan Temple & Monster Egg masuk")
do
  check("jumlah pet >= 100", A.DB_COUNT >= 100, A.DB_COUNT)
  local titan = { "crustacia", "spideron", "bladehide", "mantaris",
                  "rhinotaur", "mutantshark", "gorillaking", "nightflame" }
  local ok = 0
  for _, k in ipairs(titan) do if A.DB[k] then ok = ok + 1 end end
  check("8 pet Titan Temple ada", ok == 8, ok)

  check("Mutant Shark Secret $215M/s",
    A.DB.mutantshark[1] == "Secret" and A.DB.mutantshark[2] == 215000000,
    A.DB.mutantshark[2])
  check("Gorilla King Eternal $880M/s",
    A.DB.gorillaking[1] == "Eternal" and A.DB.gorillaking[2] == 880000000,
    A.DB.gorillaking[2])
  check("Rhinotaur Cosmic $17.5M/s", A.DB.rhinotaur[2] == 17500000, A.DB.rhinotaur[2])
  check("Nightflame Divine, income nil (belum diindeks)",
    A.DB.nightflame[1] == "Divine" and A.DB.nightflame[2] == nil,
    tostring(A.DB.nightflame[2]))

  local monster = { "scorpio", "froggo", "crawler", "crocodon", "krakenoid",
                    "dreadscale", "mechascorpio", "mechafroggo", "mechacrawler",
                    "mechacrocodon", "mechakrakenoid", "mechadreadscale" }
  local m = 0
  for _, k in ipairs(monster) do if A.DB[k] then m = m + 1 end end
  check("12 pet Monster Egg ada", m == 12, m)
  check("Dreadscale Divine ~$8B/s", A.DB.dreadscale[2] == 8000000000,
    A.DB.dreadscale[2])
  check("Monster Egg lain income nil (tidak dikarang)",
    A.DB.scorpio[2] == nil and A.DB.crawler[2] == nil, "ok")

  -- Mecha tidak boleh tertukar dengan versi biasa
  check("MechaDreadscale beda entri dari Dreadscale",
    A.dbExact("MechaDreadscaleEgg") == "mechadreadscale",
    A.dbExact("MechaDreadscaleEgg"))
  check("DreadscaleEgg tetap dreadscale",
    A.dbExact("DreadscaleEgg") == "dreadscale", A.dbExact("DreadscaleEgg"))
end

sect("53. awalan mutasi tidak merusak pencocokan nama")
do
  local cases = {
    { "RainbowKitsuneEgg", "kitsune" },
    { "GoldenMantarisEgg", "mantaris" },
    { "SpiritBloomStagEgg", "stag" },
    { "SilverGorillaKingEgg", "gorillaking" },
    { "BloomKoiEgg", "koi" },
  }
  local ok = 0
  for _, c in ipairs(cases) do
    local k = A.dbStripMutation(c[1]) or A.dbExact(c[1])
    if k == c[2] then ok = ok + 1
    else print("      " .. c[1] .. " -> " .. tostring(k) .. " (harusnya " .. c[2] .. ")") end
  end
  check("5/5 nama bermutasi tercocokkan benar", ok == 5, ok .. "/5")
end
