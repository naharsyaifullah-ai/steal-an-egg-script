-- ---- t_13_game.lua ----
-- Inti v6: struktur game nyata, diselidiki dari script autofarm publik yang
-- masih berfungsi (Agu-Sep 2026):
--   · telur = slot di workspace.AreaEggSlotsClient (anak "Plane"),
--     telur event = model Workspace dengan anak "Hitbox",
--     telur langka bertanda "RareAreaEggHighlight", parasit "MonsterParasiteVisual"
--   · prompt ambil DIPUSATKAN di workspace.SmartPromptPart
--   · base pemain = workspace.Plots (plot dengan penanda nama pemain)
--   · resep AJARI tersimpan ke berkas (writefile) dan dimuat ulang otomatis
-- Semua objek dibuat di sini dan dibersihkan lagi di akhir blok supaya
-- assertion lain tidak terganggu.
local A = SAE
local W = MOCK.Workspace
local LPn = tostring(MOCK.LocalPlayer.Name)

sect("74. struktur nyata: Plots = base pemain")
do
  local plots = Instance.new("Folder", W)
  plots.Name = "Plots"

  local minePlot = Instance.new("Model", plots)
  minePlot.Name = "Plot3"
  local mineFloor = makePart("Floor", minePlot, Vector3.new(540, 0, -360))
  rawget(minePlot, "_p").PrimaryPart = mineFloor
  local own = Instance.new("StringValue", minePlot)
  own.Name = "Owner"
  own.Value = LPn

  local rivalPlot = Instance.new("Model", plots)
  rivalPlot.Name = "Plot7"
  local rivalFloor = makePart("Floor", rivalPlot, Vector3.new(541, 0, -300))
  rawget(rivalPlot, "_p").PrimaryPart = rivalFloor
  local own2 = Instance.new("StringValue", rivalPlot)
  own2.Name = "Owner"
  own2.Value = "RivalOne"

  A.flushBaseCache()
  local b = A.myBase()
  check("myBase memakai workspace.Plots", b ~= nil
    and math.abs(b.X - 540) < 1 and math.abs(b.Z + 360) < 1,
    b and tostring(b.X) .. "," .. tostring(b.Z))
  check("plot pemain lain tidak terpilih", b ~= nil and math.abs(b.Z + 300) > 1)

  sect("75. struktur nyata: telur = slot AreaEggSlotsClient")
  local slf = Instance.new("Folder", W)
  slf.Name = "AreaEggSlotsClient"

  local slot = Instance.new("Model", slf)
  slot.Name = "Slot_07"
  local plane = makePart("Plane", slot, Vector3.new(600, 0, -350))
  rawget(slot, "_p").PrimaryPart = plane
  slot:SetAttribute("PetName", "Kitsune")
  local hl = makePart("RareAreaEggHighlight", slot, Vector3.new(600, 0, -350))

  local evg = Instance.new("Model", W)
  evg.Name = "MonsterEggEvent"
  local eplane = makePart("Plane", evg, Vector3.new(700, 0, -360))
  local hb = makePart("Hitbox", evg, Vector3.new(700, 0, -360))
  rawget(evg, "_p").PrimaryPart = eplane

  -- pet di luar database: biome harus jatuh ke deteksi zona koordinat
  local slotU = Instance.new("Model", slf)
  slotU.Name = "Slot_12"
  local planeU = makePart("Plane", slotU, Vector3.new(600, 0, -350))
  rawget(slotU, "_p").PrimaryPart = planeU
  slotU:SetAttribute("PetName", "Zorblokus")

  local eggs = A.scanEggs()
  local slotEgg, eventEgg, slotUEgg
  for _, e in ipairs(eggs) do
    if e.obj == slot then slotEgg = e end
    if e.obj == evg then eventEgg = e end
    if e.obj == slotU then slotUEgg = e end
  end
  check("slot dengan Plane terdeteksi sebagai telur", slotEgg ~= nil)
  check("pet dikenal dari attribute PetName", slotEgg and slotEgg.key == "kitsune",
    slotEgg and tostring(slotEgg.key))
  check("rarity Divine terbaca", slotEgg and slotEgg.rar == "Divine",
    slotEgg and tostring(slotEgg.rar))
  check("income database terpasang", slotEgg and slotEgg.income == 1800000000)
  check("penanda RareAreaEggHighlight terbaca", slotEgg and slotEgg.rare == true)
  check("biome database tetap diutamakan", slotEgg and slotEgg.biome == "Cherry",
    slotEgg and tostring(slotEgg.biome))
  check("pet tak dikenal: biome dari koordinat zona",
    slotUEgg and slotUEgg.biome == "Forest" and slotUEgg.rar == nil,
    slotUEgg and tostring(slotUEgg.biome) .. "/" .. tostring(slotUEgg.rar))
  check("telur event (anak Hitbox) terdeteksi", eventEgg ~= nil
    and eventEgg.kind == "event")
  check("slot tidak diduplikasi oleh deteksi nama generik",
    (function()
      local n = 0
      for _, e in ipairs(eggs) do if e.obj == slot then n = n + 1 end end
      return n == 1
    end)())

  sect("76. SmartPromptPart: pusat prompt ambil")
  local sp = makePart("SmartPromptPart", W, Vector3.new(5000, 0, 0))
  local pr = Instance.new("ProximityPrompt", sp)
  pr.HoldDuration = 1.3
  pr.MaxActivationDistance = 5
  local n = A.fireSmartPrompts()
  check("prompt di SmartPromptPart ditembak", n == 1 and rawget(pr, "_p")._fired == true)
  check("HoldDuration dinolkan", pr.HoldDuration == 0)
  check("MaxActivationDistance dinaikkan", (pr.MaxActivationDistance or 0) >= 18)

  check("telur rare diprioritaskan skor",
    slotEgg and A.eggScore(slotEgg) > A.eggScore(EGGS[1]))

  sect("77. resep AJARI tersimpan & dimuat ulang (v6)")
  A.SPY.learned = nil
  A.SPY.learnedFrom = nil
  A.SPY.note = "belum merekam"
  A.SPY.onDisk = false
  MOCKFS = {}

  local remote = A.findRemoteByName("StealEgg")
  check("remote game ditemukan lewat nama", remote ~= nil)

  local eggRef = EGGS[1]
  A.SPY.recording = true
  A.SPY.recordForTest(remote, "FireServer", table.pack(remote, eggRef, "pickup"))
  local okLearn = A.SPY.learnFrom(eggRef, tick() - 1)
  check("belajar remote berhasil", okLearn == true and A.SPY.learned ~= nil)
  A.SPY.saveRecipe()
  check("resep ditulis ke berkas executor", MOCKFS["SAE_Recipe.lua"] ~= nil)

  -- simulasikan sesi baru: state memori hilang, berkas tetap ada
  A.SPY.learned = nil
  A.SPY.learnedFrom = nil
  A.SPY.note = "belum merekam"
  A.SPY.onDisk = false
  local okLoad = A.SPY.loadRecipe()
  check("resep dimuat ulang dari berkas", okLoad == true and A.SPY.learned ~= nil)
  check("remote tersambung lagi lewat nama",
    A.SPY.learned and A.SPY.learned.remote == remote)
  check("template telur dipertahankan", A.SPY.learned ~= nil
    and A.SPY.learned.template[1] ~= nil and A.SPY.learned.template[1].kind == "egg")

  local before = rawget(remote, "_p")._fired or 0
  local other = EGGS[2]
  A.SPY.replay(other)
  local st = rawget(remote, "_p")
  check("resep terpasang memutar ulang panggilan dengan telur lain",
    (st._fired or 0) > before and st._lastArgs ~= nil
      and st._lastArgs[1] == other and st._lastArgs[2] == "pickup")

  -- bersihkan: dunia kembali seperti sebelum blok ini
  A.SPY.learned = nil
  A.SPY.learnedFrom = nil
  A.SPY.onDisk = false
  MOCKFS = {}
  plots:Destroy()
  slf:Destroy()
  evg:Destroy()
  sp:Destroy()
  A.flushBaseCache()
end
