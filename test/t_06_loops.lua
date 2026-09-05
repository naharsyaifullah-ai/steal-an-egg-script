-- ---- t_06_loops.lua ----
local A = SAE

sect("16. loop auto steal end-to-end")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(0, 0, 0)

  -- reset counters
  for _, r in pairs(R) do rawget(r, "_p")._fired = nil end
  A.S.stolen = 0
  A.S.antiTrap = false
  A.S.antiBat = false
  A.S.speed = 400
  A.S.stealDelay = 0.1
  A.S.returnBase = true
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = false end
  A.S.rarityPick.Divine = true      -- KitsuneEgg di (380,0,0)

  A.S.stealOn = true
  stepScheduler(700, 0.05)
  A.S.stealOn = false
  A.stopGlide()

  check("counter telur dicuri bertambah", A.S.stolen >= 1, A.S.stolen)
  check("remote steal ditembak saat loop", rawget(R.steal, "_p")._fired ~= nil,
    rawget(R.steal, "_p")._fired)
  check("remote deposit ditembak (bawa pulang)", rawget(R.deposit, "_p")._fired ~= nil,
    rawget(R.deposit, "_p")._fired)
  check("status terakhir mencatat rarity", tostring(A.S.lastEgg):find("Divine") ~= nil,
    A.S.lastEgg)
  check("status bukan error", tostring(A.S.status):find("error") == nil, A.S.status)
  check("karakter sempat bergerak jauh dari titik awal",
    math.abs(hrp.Position.X) > 50 or A.S.stolen >= 1, hrp.Position.X)
end

sect("17. loop farm menembak remote yang benar")
do
  for _, r in pairs(R) do rawget(r, "_p")._fired = nil end

  A.S.autoHatch = true
  A.S.autoClaim = true
  A.S.autoUpgrade = true
  A.S.autoSell = true
  A.S.autoTrain = false
  A.S.stealOn = false

  stepScheduler(120, 0.1)

  A.S.autoHatch = false; A.S.autoClaim = false
  A.S.autoUpgrade = false; A.S.autoSell = false

  local f = function(r) return rawget(r, "_p")._fired end
  check("auto hatch menembak HatchEgg", f(R.hatch) ~= nil, f(R.hatch))
  check("auto claim menembak ClaimMoney", f(R.claim) ~= nil, f(R.claim))
  check("auto upgrade menembak BuyUpgrade", f(R.upgrade) ~= nil, f(R.upgrade))
  check("auto sell menembak SellPet", f(R.sell) ~= nil, f(R.sell))
  check("remote tak relevan tetap tidak tertembak", f(R.noise) == nil, f(R.noise))
  check("steal TIDAK tertembak saat autoSteal off", f(R.steal) == nil, f(R.steal))
end

sect("18. loop player: speed & anti stun")
do
  local hum = CHR:FindFirstChildOfClass("Humanoid")

  A.S.speedOn = true
  A.S.speed = 750
  stepScheduler(20, 0.1)
  check("WalkSpeed mengikuti slider (750)", hum.WalkSpeed == 750, hum.WalkSpeed)

  A.S.speed = 99999
  stepScheduler(20, 0.1)
  check("WalkSpeed dibatasi 1000", hum.WalkSpeed == 1000, hum.WalkSpeed)

  A.S.speedOn = false
  stepScheduler(20, 0.1)
  check("speed off → kembali 16", hum.WalkSpeed == 16, hum.WalkSpeed)

  A.S.antiStun = true
  hum.Sit = true
  stepScheduler(20, 0.1)
  check("anti stun mematikan state Ragdoll",
    hum:GetStateEnabled(Enum.HumanoidStateType.Ragdoll) == false)
  check("anti stun mematikan state FallingDown",
    hum:GetStateEnabled(Enum.HumanoidStateType.FallingDown) == false)
  check("anti stun melepas Sit", hum.Sit == false, hum.Sit)
  A.S.antiStun = false

  A.S.noFall = true
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Velocity = Vector3.new(0, -400, 0)
  stepScheduler(20, 0.1)
  check("no fall meredam kecepatan jatuh", hrp.Velocity.Y > -100, hrp.Velocity.Y)
  A.S.noFall = false
end

sect("19. ketahanan: karakter mati / hilang")
do
  local savedChr = rawget(MOCK.LocalPlayer, "_p").Character
  rawget(MOCK.LocalPlayer, "_p").Character = nil

  A.S.stealOn = true
  A.S.autoHatch = true
  local ok = pcall(function() stepScheduler(60, 0.1) end)
  check("tanpa karakter, loop tidak crash", ok == true)
  check("status tidak berisi error fatal",
    tostring(A.S.status):find("attempt to index") == nil, A.S.status)

  rawget(MOCK.LocalPlayer, "_p").Character = savedChr
  local hum = savedChr:FindFirstChildOfClass("Humanoid")
  hum.Health = 0
  local ok2 = pcall(function() stepScheduler(40, 0.1) end)
  check("karakter mati (HP 0), loop tidak crash", ok2 == true)
  hum.Health = 100

  A.S.stealOn = false
  A.S.autoHatch = false

  -- map kosong: hapus semua telur
  local removed = {}
  for _, e in ipairs(A.scanEggs()) do
    removed[#removed + 1] = e.obj
    e.obj.Parent = nil
  end
  check("map dikosongkan dari telur", #A.scanEggs() == 0, #A.scanEggs())
  A.S.stealOn = true
  local ok3 = pcall(function() stepScheduler(40, 0.1) end)
  A.S.stealOn = false
  check("tanpa telur, loop tidak crash", ok3 == true)
  check("status melaporkan nunggu telur",
    tostring(A.S.status):find("nunggu") ~= nil, A.S.status)
  for _, o in ipairs(removed) do o.Parent = MOCK.Workspace end
  check("telur dikembalikan untuk uji lain", #A.scanEggs() == 7, #A.scanEggs())
end

sect("20. status bar hidup")
do
  stepScheduler(20, 0.1)
  local txt = A.statusTxt.Text
  check("status bar terisi", type(txt) == "string" and #txt > 0, txt)
  check("status bar memuat jumlah dicuri", tostring(txt):find("dicuri") ~= nil, txt)
end
