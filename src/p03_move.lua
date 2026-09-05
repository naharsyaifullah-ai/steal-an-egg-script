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

-- ============ GERAK HALUS (glide, bukan TP) ============
local flyBV, flyBG
local moving = false

local function stopGlide()
  moving = false
  if flyBV then flyBV:Destroy(); flyBV = nil end
  if flyBG then flyBG:Destroy(); flyBG = nil end
  local h = hum()
  if h then h.PlatformStand = false end
end

-- gerak ke target dengan kecepatan S.speed stud/detik, menghindari trap & musuh
local function glideTo(target, timeout)
  local h = hrp(); local hu = hum()
  if not (h and hu) then return false end
  timeout = timeout or 25
  moving = true

  if not flyBV then
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.P = 8000
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = h
  end

  local t0 = tick()
  while moving and alive() and tick() - t0 < timeout do
    local cur = hrp(); if not cur then break end
    local d = target - cur.Position
    if d.Magnitude < 6 then break end

    local dir = d.Unit

    -- hindari trap & musuh: dorong arah menjauh
    if S.antiTrap then
      for _, t in ipairs(scanTraps()) do
        local dd = t.pos - cur.Position
        if dd.Magnitude < S.avoidRadius then
          dir = (dir - dd.Unit * 1.4)
          if dir.Magnitude > 0 then dir = dir.Unit end
        end
      end
    end
    if S.antiBat then
      for _, m in ipairs(scanHostiles()) do
        local dd = m.pos - cur.Position
        if dd.Magnitude < S.avoidRadius then
          dir = (dir - dd.Unit * 1.6) + Vector3.new(0, 0.35, 0)
          if dir.Magnitude > 0 then dir = dir.Unit end
        end
      end
    end

    local spd = math.clamp(S.speed, 16, 1000)
    flyBV.Velocity = dir * spd
    hu.PlatformStand = true
    task.wait(0.05)
  end

  if flyBV then flyBV.Velocity = Vector3.zero end
  local hu2 = hum(); if hu2 then hu2.PlatformStand = false end
  moving = false
  return true
end

-- ============ PILIH TELUR SESUAI FILTER ============
local function anyRarityPicked()
  for _, v in pairs(S.rarityPick) do if v then return true end end
  return false
end

local function eggScore(e)
  local idx = 0
  if e.rar then
    for i, r in ipairs(RARITY) do if r == e.rar then idx = i break end end
  end
  local s = idx * 1000
  if S.preferMutasi and e.mut then
    local mi = 0
    for i, m in ipairs(MUTATION) do if m == e.mut then mi = (#MUTATION - i + 1) break end end
    s = s + mi * 300
  end
  s = s + math.min(e.wt / 1000, 500)
  return s
end

local function pickEgg()
  local h = hrp(); if not h then return nil end
  local filter = anyRarityPicked()
  local best, bestScore = nil, -1
  for _, e in ipairs(scanEggs()) do
    local okRar = true
    if filter then
      okRar = (e.rar ~= nil) and S.rarityPick[e.rar] == true
    end
    local okWt = (S.minWeight <= 0) or (e.wt >= S.minWeight)
    if okRar and okWt then
      local sc = eggScore(e) - dist(h.Position, e.pos) * 0.05
      if sc > bestScore then bestScore, best = sc, e end
    end
  end
  return best
end
