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

-- cari remote berdasar nama persis — dipakai memuat resep tersimpan
local function findRemoteByName(name)
  if not name then return nil end
  indexRemotes()
  for _, r in ipairs(remotes) do
    if r.Name == name then return r end
  end
  return nil
end

-- SmartPromptPart: game ini MEMUSATKAN prompt ambil di sini (bukan prompt di
-- dalam telur). Tanpa menembaknya, mendekat + sentuh saja tidak pernah
-- mengambil apa pun. HoldDuration dinolkan dulu: dengan nilai bawaan,
-- fireproximityprompt sering tidak berefek.
local function fireSmartPrompts()
  local n = 0
  for _, c in ipairs(Workspace:GetChildren()) do
    if c.Name == "SmartPromptPart" then
      for _, p in ipairs(c:GetChildren()) do
        if p:IsA("ProximityPrompt") then
          pcall(function()
            p.Enabled = true
            p.MaxActivationDistance = math.max(p.MaxActivationDistance or 0, 60)
            p.RequiresLineOfSight = false
            p.HoldDuration = 0
            fireproximityprompt(p)
          end)
          n = n + 1
        end
      end
    end
  end
  return n
end

-- tekan prompt: HoldDuration harus dinolkan dulu, kalau tidak
-- fireproximityprompt sering tidak menghasilkan apa pun
local function pressPromptsNear(radius)
  local h = hrp(); if not h then return 0 end
  local n = 0
  for _, p in ipairs(Workspace:GetDescendants()) do
    if p:IsA("ProximityPrompt") then
      local pp = partOf(p.Parent)
      if pp and dist(h.Position, pp.Position) <= (radius or 24) then
        pcall(function()
          p.Enabled = true
          p.MaxActivationDistance = math.max(p.MaxActivationDistance or 0, 60)
          p.RequiresLineOfSight = false
          p.HoldDuration = 0
          fireproximityprompt(p)
        end)
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
    task.wait(0.03)
    firetouchinterest(h, part, 1)
    task.wait(0.03)
    firetouchinterest(h, part, 0)
    task.wait(0.03)
    firetouchinterest(h, part, 1)
  end)
end

-- ============ GERAK: HOP = TERBANG DATAR (Y TERKUNCI) ============
-- Koreksi: pengguna memang mau melayang, tapi LURUS/datar — bukan naik ke
-- langit, dan bukan jalan kaki lambat seperti v3.
-- BodyVelocity dengan Y = 0 membuat karakter meluncur horizontal di ketinggian
-- yang sama. PlatformStand tidak dipakai (itu penyebab ragdoll di v2), dan saat
-- berhenti kecepatan dinolkan lebih dulu supaya tidak terhuyung.

local moving = false
local flyBV = nil

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
  flyBV = nil
end

local function stopGlide()
  moving = false
  clearMoveHelpers()
  local h = hrp()
  if h then h.Velocity = Vector3.new(0, 0, 0) end
  local hu = hum()
  if hu then
    hu.PlatformStand = false
    hu.AutoRotate = true
  end
end

-- pergeseran hindar: selalu horizontal, tidak pernah menambah ketinggian
local function avoidOffset(from)
  local off = Vector3.new(0, 0, 0)
  local r = S.avoidRadius
  if S.antiTrap then
    for _, t in ipairs(scanTraps()) do
      local d = from - t.pos
      local m = d.Magnitude
      if m < r and m > 0.1 then off = off + d.Unit * (r - m) end
    end
  end
  if S.antiBat then
    for _, mo in ipairs(scanHostiles()) do
      local d = from - mo.pos
      local m = d.Magnitude
      if m < r and m > 0.1 then off = off + d.Unit * (r - m) * 1.3 end
    end
  end
  return Vector3.new(off.X, 0, off.Z)
end

-- terbang datar ke target
local function hopTo(target, timeout, speedOverride)
  local h = hrp()
  local hu = hum()
  if not (h and hu) then return false end
  timeout = timeout or 25
  moving = true

  local spd = math.clamp(speedOverride or S.speed, 16, 1000)
  hu.PlatformStand = false

  if not (flyBV and flyBV.Parent) then
    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "SAE_Fly"
    flyBV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
    flyBV.P = 12500
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = h
  end

  local t0 = tick()
  local lastPos, lastCheck = h.Position, tick()

  while moving and alive() and tick() - t0 < timeout do
    local cur = hrp()
    if not cur then break end

    local flat = Vector3.new(target.X - cur.Position.X, 0, target.Z - cur.Position.Z)
    local dy = target.Y - cur.Position.Y
    if flat.Magnitude < 4 and math.abs(dy) < 10 then break end

    local dir = (flat.Magnitude > 0.1) and flat.Unit or Vector3.new(0, 0, 0)
    local push = avoidOffset(cur.Position)
    if push.Magnitude > 0.1 then
      dir = dir + push.Unit * 0.8
      if dir.Magnitude > 0 then dir = dir.Unit end
    end

    -- vertikal HANYA untuk menyamakan ketinggian target, dibatasi 18 stud/s
    -- supaya tidak pernah melesat ke atas
    local vy = 0
    if math.abs(dy) > 8 then vy = math.clamp(dy, -18, 18) end

    if flyBV and flyBV.Parent then
      flyBV.Velocity = Vector3.new(dir.X * spd, vy, dir.Z * spd)
    end

    -- nyangkut: 2 detik hampir tak bergerak → naik sedikit sekali untuk lewat
    if tick() - lastCheck > 2 then
      if (cur.Position - lastPos).Magnitude < 6 and flyBV and flyBV.Parent then
        flyBV.Velocity = Vector3.new(dir.X * spd, 16, dir.Z * spd)
      end
      lastPos, lastCheck = cur.Position, tick()
    end

    task.wait(0.06)
  end

  moving = false
  if flyBV and flyBV.Parent then flyBV.Velocity = Vector3.new(0, 0, 0) end
  clearMoveHelpers()
  local h2 = hrp()
  if h2 then h2.Velocity = Vector3.new(0, 0, 0) end
  local hu2 = hum()
  if hu2 then hu2.PlatformStand = false end
  return true
end

-- mode jalan kaki: pilihan, bukan default
local function walkTo(target, timeout, speedOverride)
  local hu = hum()
  local h = hrp()
  if not (hu and h) then return false end
  timeout = timeout or 25
  moving = true
  local spd = math.clamp(speedOverride or S.speed, 8, 1000)
  hu.PlatformStand = false
  local t0 = tick()
  while moving and alive() and tick() - t0 < timeout do
    local cur = hrp(); if not cur then break end
    local flat = Vector3.new(target.X - cur.Position.X, 0, target.Z - cur.Position.Z)
    if flat.Magnitude < 5 then break end
    hu.WalkSpeed = spd
    hu:MoveTo(target + avoidOffset(cur.Position))
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

-- satu pintu masuk: default terbang datar, jalan kaki kalau S.walkMode
local function moveTo(target, timeout, speedOverride)
  if S.walkMode then return walkTo(target, timeout, speedOverride) end
  return hopTo(target, timeout, speedOverride)
end
local glideTo = moveTo

-- ============ PILIH TELUR ============
local function anyRarityPicked()
  for _, v in pairs(S.rarityPick) do if v then return true end end
  return false
end

local function eggScore(e)
  local mult = e.mult or (e.mut and MUT_MULT[e.mut]) or 1
  local s = 0
  if e.income then
    s = math.log(math.max(e.income, 1) * mult) * 1000
  else
    local idx = 0
    if e.rar then
      for i, r in ipairs(RARITY) do if r == e.rar then idx = i break end end
    end
    s = idx * 1000
  end
  if S.preferMutasi and e.mut then s = s + (mult - 1) * 900 end
  -- telur bertanda RareAreaEggHighlight / parasit diprioritaskan walau
  -- rarity-nya belum terbaca database
  if e.rare then s = s + 50000 end
  if e.kind == "parasite" then s = s + 10000 end
  s = s + math.min((e.wt or 0) / 100000, 400)
  return s
end

-- Telur yang sudah ada di base sendiri BUKAN sasaran. Ini penyebab
-- "mundar-mandir di base": telur yang sudah disetor terus dipilih lagi.
local function nearOwnBase(pos)
  local b = myBase()
  if not b then return false end
  return dist(pos, b) < S.baseGuard
end

local function pickEgg()
  local h = hrp(); if not h then return nil end
  local filter = anyRarityPicked()
  local best, bestScore = nil, -math.huge
  for _, e in ipairs(scanEggs()) do
    local okRar = true
    if filter then
      -- telur belum dikenal tetap boleh kalau S.takeUnknown menyala
      if e.rar == nil then okRar = S.takeUnknown
      else okRar = S.rarityPick[e.rar] == true end
    end
    local okWt = (S.minWeight <= 0) or ((e.wt or 0) >= S.minWeight)
    local okInc = (S.minIncome <= 0) or ((e.income or 0) >= S.minIncome)
    -- telur di base pemain lain hanya kalau pengguna menyalakannya sendiri:
    -- default hanya telur liar di zona (laporan nyata: steal kabur ke base orang)
    local okPlot = S.takePlots or not e.owned
    if okRar and okWt and okInc and okPlot and not e.mine and not nearOwnBase(e.pos) then
      local d = dist(h.Position, e.pos)
      if d <= S.maxRange then
        local sc = eggScore(e) - d * 0.08
        if sc > bestScore then bestScore, best = sc, e end
      end
    end
  end
  return best
end
