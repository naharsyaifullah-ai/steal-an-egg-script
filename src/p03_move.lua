-- ============ REMOTE ============
local remotes = {}
local function indexRemotes()
  remotes = {}
  local roots = { RS, Workspace }
  local pg = LP:FindFirstChild("PlayerGui"); if pg then roots[#roots + 1] = pg end
  for _, root in ipairs(roots) do
    for _, r in ipairs(root:GetDescendants()) do
      if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
        remotes[#remotes + 1] = r
      end
    end
  end
  return #remotes
end
indexRemotes()

local function fireMatch(words, ...)
  -- pack args: '...' tidak bisa dipakai di dalam closure pcall
  local args = table.pack(...)
  local n = 0
  for _, r in ipairs(remotes) do
    local nm = lower(r.Name)
    for _, w in ipairs(words) do
      if nm:find(w, 1, true) then
        pcall(function()
          if r:IsA("RemoteEvent") then
            r:FireServer(table.unpack(args, 1, args.n))
          else
            r:InvokeServer(table.unpack(args, 1, args.n))
          end
        end)
        n = n + 1
        break
      end
    end
  end
  return n
end

local function pressPromptsNear(radius)
  local h = hrp(); if not h then return 0 end
  local n = 0
  for _, p in ipairs(Workspace:GetDescendants()) do
    if p:IsA("ProximityPrompt") and p.Enabled then
      local pp = partOf(p.Parent)
      if pp and dist(h.Position, pp.Position) <= (radius or 24) then
        pcall(function() fireproximityprompt(p) end)
        n = n + 1
      end
    end
  end
  return n
end

local function touchPart(part)
  local h = hrp(); if not (h and part) then return end
  pcall(function()
    firetouchinterest(h, part, 0)
    task.wait(0.05)
    firetouchinterest(h, part, 1)
  end)
end

-- ============ GERAK: JALAN DI TANAH, TIDAK TERBANG ============
-- Versi lama memakai BodyVelocity + PlatformStand. Itu penyebab dua keluhan:
-- karakter melayang/terbang, dan begitu BodyVelocity dilepas karakter jatuh
-- terhuyung karena PlatformStand mematikan kaki. Sekarang gerak memakai
-- Humanoid:MoveTo() — animasi jalan normal, fisika normal, tidak ada terbang.

local moving = false
local moveConn = nil

local function clearMoveHelpers()
  local h = hrp()
  if h then
    for _, c in ipairs(h:GetChildren()) do
      if c:IsA("BodyVelocity") or c:IsA("BodyGyro") or c:IsA("BodyPosition")
        or c:IsA("AlignPosition") or c:IsA("LinearVelocity") then
        c:Destroy()
      end
    end
  end
end

local function stopGlide()
  moving = false
  if moveConn then pcall(function() moveConn:Disconnect() end); moveConn = nil end
  clearMoveHelpers()
  local hu = hum()
  if hu then
    hu.PlatformStand = false          -- pastikan tidak pernah tertinggal true
    hu.AutoRotate = true
    pcall(function() hu:MoveTo(hrp() and hrp().Position or Vector3.zero) end)
  end
end

-- vektor hindar dari trap & musuh (dipakai untuk MENGGESER titik tujuan,
-- bukan untuk mendorong badan — dorongan itu yang bikin terhuyung)
local function avoidOffset(from)
  local off = Vector3.zero
  local r = S.avoidRadius
  if S.antiTrap then
    for _, t in ipairs(scanTraps()) do
      local d = from - t.pos
      local m = d.Magnitude
      if m < r and m > 0.1 then
        off = off + d.Unit * (r - m)
      end
    end
  end
  if S.antiBat then
    for _, mo in ipairs(scanHostiles()) do
      local d = from - mo.pos
      local m = d.Magnitude
      if m < r and m > 0.1 then
        off = off + d.Unit * (r - m) * 1.3
      end
    end
  end
  return Vector3.new(off.X, 0, off.Z)   -- selalu horizontal: tidak ada naik
end

-- jalan ke target. speedOverride dipakai tab STEAL supaya kecepatan
-- steal bisa beda dari kecepatan jalan biasa.
local function walkTo(target, timeout, speedOverride)
  local hu = hum()
  local h = hrp()
  if not (hu and h) then return false end
  timeout = timeout or 25
  moving = true

  local spd = math.clamp(speedOverride or S.speed, 8, 1000)
  hu.WalkSpeed = spd
  hu.PlatformStand = false

  local t0 = tick()
  local stuckAt, stuckT = h.Position, tick()

  while moving and alive() and tick() - t0 < timeout do
    local cur = hrp()
    if not cur then break end
    local flat = Vector3.new(target.X - cur.Position.X, 0, target.Z - cur.Position.Z)
    if flat.Magnitude < 5 then break end

    local goal = target + avoidOffset(cur.Position)
    hu.WalkSpeed = spd
    hu:MoveTo(goal)

    -- lepas dari nyangkut: kalau 1,5 detik hampir tak bergerak, lompat sekali
    if (tick() - stuckT) > 1.5 then
      if (cur.Position - stuckAt).Magnitude < 4 then
        pcall(function() hu.Jump = true end)
      end
      stuckAt, stuckT = cur.Position, tick()
    end

    task.wait(0.12)
  end

  moving = false
  local hu2 = hum()
  if hu2 then
    hu2.PlatformStand = false
    if not S.speedOn then hu2.WalkSpeed = 16 end
  end
  return true
end

-- nama lama dipertahankan supaya sisa kode & test tetap jalan
local glideTo = walkTo

-- ============ PILIH TELUR SESUAI FILTER ============
local function anyRarityPicked()
  for _, v in pairs(S.rarityPick) do if v then return true end end
  return false
end

-- skor telur: pakai income NYATA dari database kalau ada, bukan cuma indeks
local function eggScore(e)
  -- pengali mutasi: hormati e.mult kalau sudah dihitung, kalau tidak turunkan
  -- dari nama mutasi (bikin fungsi ini aman dipanggil dengan tabel sederhana)
  local mult = e.mult
  if not mult then
    mult = (e.mut and MUT_MULT[e.mut]) or 1
  end

  local s = 0
  if e.income then
    -- log supaya Divine tidak membuat sisanya nol; dikali pengali mutasi
    s = math.log(math.max(e.income, 1) * mult) * 1000
  else
    local idx = 0
    if e.rar then
      for i, r in ipairs(RARITY) do if r == e.rar then idx = i break end end
    end
    s = idx * 1000
  end
  if S.preferMutasi and e.mut then
    s = s + (mult - 1) * 900
  end
  s = s + math.min((e.wt or 0) / 100000, 400)
  return s
end

local function pickEgg()
  local h = hrp(); if not h then return nil end
  local filter = anyRarityPicked()
  local best, bestScore = nil, -math.huge
  for _, e in ipairs(scanEggs()) do
    local okRar = true
    if filter then
      okRar = (e.rar ~= nil) and S.rarityPick[e.rar] == true
    end
    local okWt = (S.minWeight <= 0) or ((e.wt or 0) >= S.minWeight)
    local okInc = (S.minIncome <= 0) or ((e.income or 0) >= S.minIncome)
    if okRar and okWt and okInc then
      local d = dist(h.Position, e.pos)
      if d <= S.maxRange then
        local sc = eggScore(e) - d * 0.08
        if sc > bestScore then bestScore, best = sc, e end
      end
    end
  end
  return best
end
