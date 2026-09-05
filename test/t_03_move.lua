-- ---- t_03_move.lua ----
local A = SAE

sect("5. gerak halus (bukan teleport)")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  hrp.Position = Vector3.new(0, 0, 0)

  A.S.speed = 200
  A.S.antiTrap = false
  A.S.antiBat = false

  local target = Vector3.new(380, 0, 0)
  local samples = { hrp.Position.X }
  local co = coroutine.create(function() A.glideTo(target, 40) end)
  for _ = 1, 500 do
    if coroutine.status(co) == "dead" then break end
    local ok, err = coroutine.resume(co)
    if not ok then print("   [glide error] " .. tostring(err)); break end
    PHYSICS_STEP(0.05)
    samples[#samples + 1] = hrp.Position.X
  end

  local maxJump = 0
  for i = 2, #samples do
    maxJump = math.max(maxJump, math.abs(samples[i] - samples[i - 1]))
  end

  check("karakter mendekat ke target", math.abs(hrp.Position.X - 380) < 12, hrp.Position.X)
  check("TIDAK ada lompatan teleport (langkah ≤ speed×dt)",
    maxJump <= (200 * 0.05) + 1.5, maxJump)
  check("perjalanan bertahap (>20 langkah)", #samples > 20, #samples)
  check("BodyVelocity dipakai, CFrame tidak di-set langsung",
    hrp:FindFirstChildOfClass("BodyVelocity") ~= nil)

  A.stopGlide()
  check("stopGlide membersihkan BodyVelocity",
    hrp:FindFirstChildOfClass("BodyVelocity") == nil)
  check("PlatformStand dilepas setelah berhenti", hum.PlatformStand == false)
end

sect("6. batas kecepatan 1000 stud")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(0, 0, 0)

  A.S.speed = 99999          -- coba lewati batas
  local co = coroutine.create(function() A.glideTo(Vector3.new(5000, 0, 0), 5) end)
  coroutine.resume(co)
  local bv = hrp:FindFirstChildOfClass("BodyVelocity")
  local mag = bv and bv.Velocity.Magnitude or 0
  check("kecepatan glide dibatasi ≤1000 stud", mag <= 1000.5, mag)
  A.stopGlide()

  A.S.speed = 5              -- di bawah minimum
  local hrp2 = CHR:FindFirstChild("HumanoidRootPart")
  hrp2.Position = Vector3.new(0, 0, 0)
  local co2 = coroutine.create(function() A.glideTo(Vector3.new(500, 0, 0), 5) end)
  coroutine.resume(co2)
  local bv2 = hrp2:FindFirstChildOfClass("BodyVelocity")
  local mag2 = bv2 and bv2.Velocity.Magnitude or 0
  check("kecepatan glide minimum 16 stud", mag2 >= 15.5, mag2)
  A.stopGlide()
  A.S.speed = 200
end

sect("7. anti trap & anti bat mengubah jalur")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")

  -- trap tepat di depan (150,0,0), target di 200
  local function firstDir(antiTrap, antiBat)
    hrp.Position = Vector3.new(145, 0, 0)
    A.S.antiTrap = antiTrap
    A.S.antiBat = antiBat
    A.S.avoidRadius = 26
    local co = coroutine.create(function() A.glideTo(Vector3.new(200, 0, 0), 5) end)
    coroutine.resume(co)
    local bv = hrp:FindFirstChildOfClass("BodyVelocity")
    local v = bv and bv.Velocity or Vector3.new(0, 0, 0)
    A.stopGlide()
    return v
  end

  local plain = firstDir(false, false)
  local avoid = firstDir(true, false)
  check("tanpa anti-trap: lurus ke target (X positif dominan)",
    plain.X > 0 and math.abs(plain.X) > math.abs(plain.Z), plain.X)
  check("anti-trap mengubah vektor arah",
    math.abs(avoid.X - plain.X) > 1 or math.abs(avoid.Z - plain.Z) > 1,
    avoid.X .. "," .. avoid.Y .. "," .. avoid.Z)

  -- bat di (310,0,5): target di 340 → harus terangkat / menyimpang
  hrp.Position = Vector3.new(305, 0, 0)
  A.S.antiTrap = false
  A.S.antiBat = true
  local co = coroutine.create(function() A.glideTo(Vector3.new(340, 0, 0), 5) end)
  coroutine.resume(co)
  local bv = hrp:FindFirstChildOfClass("BodyVelocity")
  local v = bv and bv.Velocity or Vector3.new(0, 0, 0)
  check("anti-bat memberi komponen naik (Y > 0)", v.Y > 0, v.Y)
  A.stopGlide()

  A.S.antiTrap = false
  A.S.antiBat = false
end
