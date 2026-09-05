-- ---- t_03_move.lua ----
local A = SAE

sect("5. jalan di tanah — TIDAK terbang")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  hrp.Position = Vector3.new(0, 5, 0)      -- Y = 5, harus tetap 5
  local startY = hrp.Position.Y

  A.S.speed = 200
  A.S.antiTrap = false
  A.S.antiBat = false

  local target = Vector3.new(380, 5, 0)
  local samples = { hrp.Position.X }
  local ys = { hrp.Position.Y }
  local co = coroutine.create(function() A.walkTo(target, 40) end)
  for _ = 1, 500 do
    if coroutine.status(co) == "dead" then break end
    local ok, err = coroutine.resume(co)
    if not ok then print("   [walk error] " .. tostring(err)); break end
    PHYSICS_STEP(0.12)
    samples[#samples + 1] = hrp.Position.X
    ys[#ys + 1] = hrp.Position.Y
  end

  check("karakter mendekat ke target", math.abs(hrp.Position.X - 380) < 12, hrp.Position.X)

  -- inti keluhan "kok terbang": Y tidak boleh berubah sama sekali
  local maxYDrift = 0
  for _, y in ipairs(ys) do maxYDrift = math.max(maxYDrift, math.abs(y - startY)) end
  check("ketinggian TIDAK berubah (tidak terbang)", maxYDrift < 0.01, maxYDrift)

  local maxJump = 0
  for i = 2, #samples do
    maxJump = math.max(maxJump, math.abs(samples[i] - samples[i - 1]))
  end
  check("tidak ada lompatan teleport", maxJump <= (200 * 0.12) + 1.5, maxJump)
  check("perjalanan bertahap (>15 langkah)", #samples > 15, #samples)

  -- gerak lewat MoveTo, bukan gaya fisika
  check("memakai Humanoid:MoveTo", rawget(hum, "_p")._moveCount > 3,
    rawget(hum, "_p")._moveCount)
  check("TIDAK ada BodyVelocity (penyebab terbang)",
    hrp:FindFirstChildOfClass("BodyVelocity") == nil)
  check("TIDAK ada BodyGyro", hrp:FindFirstChildOfClass("BodyGyro") == nil)

  -- inti keluhan "jatuh-jatuh": PlatformStand mematikan kaki
  check("PlatformStand TIDAK pernah dinyalakan", hum.PlatformStand == false,
    hum.PlatformStand)

  A.stopGlide()
  check("stopGlide melepas PlatformStand", hum.PlatformStand == false)
  check("stopGlide bersih dari sisa gaya",
    hrp:FindFirstChildOfClass("BodyVelocity") == nil
    and hrp:FindFirstChildOfClass("BodyGyro") == nil)
end

sect("6. kecepatan steal punya slider sendiri")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  hrp.Position = Vector3.new(0, 5, 0)

  -- kecepatan jalan biasa 60, kecepatan steal 300 → walkTo harus pakai 300
  A.S.speed = 60
  A.S.stealSpeed = 300
  local co = coroutine.create(function() A.walkTo(Vector3.new(900, 5, 0), 5, A.S.stealSpeed) end)
  coroutine.resume(co)
  check("override kecepatan steal dipakai", hum.WalkSpeed == 300, hum.WalkSpeed)
  A.stopGlide()

  -- tanpa override → pakai S.speed
  hrp.Position = Vector3.new(0, 5, 0)
  local co2 = coroutine.create(function() A.walkTo(Vector3.new(900, 5, 0), 5) end)
  coroutine.resume(co2)
  check("tanpa override pakai kecepatan jalan biasa", hum.WalkSpeed == 60, hum.WalkSpeed)
  A.stopGlide()

  -- batas atas 1000
  hrp.Position = Vector3.new(0, 5, 0)
  local co3 = coroutine.create(function() A.walkTo(Vector3.new(900, 5, 0), 5, 99999) end)
  coroutine.resume(co3)
  check("kecepatan dibatasi 1000 stud", hum.WalkSpeed == 1000, hum.WalkSpeed)
  A.stopGlide()

  A.S.speed = 200
end

sect("7. anti trap & anti bat menggeser TUJUAN, bukan mendorong badan")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local hum = CHR:FindFirstChildOfClass("Humanoid")

  local function goalAfterOneStep(antiTrap, antiBat, from, to)
    hrp.Position = from
    A.S.antiTrap = antiTrap
    A.S.antiBat = antiBat
    A.S.avoidRadius = 26
    rawget(hum, "_p")._moveTarget = nil
    local co = coroutine.create(function() A.walkTo(to, 5) end)
    coroutine.resume(co)
    local g = rawget(hum, "_p")._moveTarget
    A.stopGlide()
    return g
  end

  -- trap di (150,0,0); berjalan dari 145 ke 200
  local plain = goalAfterOneStep(false, false, Vector3.new(145, 5, 0), Vector3.new(200, 5, 0))
  local avoid = goalAfterOneStep(true,  false, Vector3.new(145, 5, 0), Vector3.new(200, 5, 0))
  check("tanpa anti-trap: tujuan = target apa adanya",
    plain and math.abs(plain.X - 200) < 0.01 and math.abs(plain.Z) < 0.01,
    plain and (plain.X .. "," .. plain.Z))
  check("anti-trap menggeser tujuan menjauh dari trap",
    avoid and (math.abs(avoid.X - 200) > 1 or math.abs(avoid.Z) > 1),
    avoid and (avoid.X .. "," .. avoid.Y .. "," .. avoid.Z))
  check("geseran anti-trap TIDAK menambah ketinggian (tetap di tanah)",
    avoid and math.abs(avoid.Y - 5) < 0.01, avoid and avoid.Y)

  -- bat di (310,0,5)
  local bat = goalAfterOneStep(false, true, Vector3.new(305, 5, 0), Vector3.new(340, 5, 0))
  check("anti-bat menggeser tujuan",
    bat and (math.abs(bat.X - 340) > 0.5 or math.abs(bat.Z) > 0.5),
    bat and (bat.X .. "," .. bat.Z))
  check("anti-bat juga tidak menaikkan Y", bat and math.abs(bat.Y - 5) < 0.01,
    bat and bat.Y)

  A.S.antiTrap = false
  A.S.antiBat = false
end
