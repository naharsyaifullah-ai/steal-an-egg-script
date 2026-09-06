-- ============ UTIL ============
local function char()  return LP.Character end
local function hrp()   local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()   local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function alive() local h = hum(); return h and h.Health > 0 end

local function lower(s) return string.lower(tostring(s or "")) end

local function partOf(inst)
  if inst:IsA("BasePart") then return inst end
  if inst:IsA("Model") then
    return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
  end
  return nil
end

local function posOf(inst)
  local p = partOf(inst)
  return p and p.Position or nil
end

local function dist(a, b) return (a - b).Magnitude end

-- cari BasePart pertama secara REKURSIF. FindFirstChildWhichIsA di beberapa
-- executor/game hanya mencari anak langsung, padahal telur event menaruh
-- Plane-nya di dalam Model beberapa lapis.
local function firstPartOf(obj)
  if not obj then return nil end
  if obj:IsA("BasePart") then return obj end
  for _, d in ipairs(obj:GetDescendants()) do
    if d:IsA("BasePart") then return d end
  end
  return nil
end

local function findNamed(obj, name)
  if not obj then return nil end
  if obj.Name == name then return obj end
  for _, d in ipairs(obj:GetDescendants()) do
    if d.Name == name then return d end
  end
  return nil
end

-- Zona peta diukur dari game nyata (dipakai script autofarm publik yang masih
-- berfungsi per Agu 2026): zona tersusun sepanjang sumbu X, pita Z tetap.
-- Dipakai sebagai nama biome cadangan kalau database tidak mengenal pet-nya.
local ZONES = {
  { name = "Forest",         minX = 553.42,  maxX = 646.49  },
  { name = "Lake",           minX = 653.01,  maxX = 793.51  },
  { name = "Desert",         minX = 796.48,  maxX = 1005.04 },
  { name = "Jungle",         minX = 1008.56, maxX = 1240.12 },
  { name = "Snow",           minX = 1244.13, maxX = 1564.18 },
  { name = "Volcano",        minX = 1568.33, maxX = 1949.58 },
  { name = "Abyss Ocean",    minX = 1953.30, maxX = 2378.73 },
  { name = "Prehistoric",    minX = 2382.87, maxX = 2884.09 },
  { name = "Cosmic",         minX = 2888.03, maxX = 3523.51 },
  { name = "Cherry Blossom", minX = 3527.67, maxX = 4263.53 },
  { name = "Titan Temple",   minX = 4268.09, maxX = 5123.06 },
}
local ZONE_MINZ, ZONE_MAXZ = -433.40, -295.05

local function zoneOf(pos)
  if not pos then return nil end
  if pos.Z < ZONE_MINZ or pos.Z > ZONE_MAXZ then return nil end
  for _, z in ipairs(ZONES) do
    if pos.X >= z.minX and pos.X <= z.maxX then return z.name end
  end
  return nil
end

-- Kumpulkan SEMUA teks yang mungkin memuat nama pet: nama objek, nama induk,
-- label, value, DAN Attribute. Attribute adalah yang paling sering dipakai game
-- modern dan tidak dibaca v4 — itulah sebabnya ESP bilang "tidak ada di
-- database" padahal petnya jelas terdaftar.
local function attrBlob(inst)
  local t = {}
  local ok, attrs = pcall(function() return inst:GetAttributes() end)
  if ok and type(attrs) == "table" then
    for k, v in pairs(attrs) do
      t[#t + 1] = tostring(k) .. "=" .. tostring(v)
    end
  end
  return table.concat(t, " | ")
end

local function textBlob(inst)
  local t = { inst.Name }

  -- rantai induk sampai 3 tingkat: sering "Nest > OniTiger > Egg"
  local p = inst.Parent
  local hops = 0
  while p and hops < 3 and p ~= Workspace do
    t[#t + 1] = p.Name
    p = p.Parent
    hops = hops + 1
  end

  t[#t + 1] = attrBlob(inst)

  for _, d in ipairs(inst:GetDescendants()) do
    if d:IsA("TextLabel") or d:IsA("TextBox") then
      t[#t + 1] = d.Text
    elseif d:IsA("StringValue") then
      t[#t + 1] = d.Name .. "=" .. tostring(d.Value)
    elseif d:IsA("NumberValue") or d:IsA("IntValue") then
      t[#t + 1] = d.Name .. "=" .. tostring(d.Value)
    elseif d:IsA("BasePart") or d:IsA("Model") or d:IsA("MeshPart") then
      -- nama part anak kadang memuat nama pet ("KitsuneMesh")
      t[#t + 1] = d.Name
      local ab = attrBlob(d)
      if ab ~= "" then t[#t + 1] = ab end
    end
  end
  return table.concat(t, " | ")
end

-- Rarity & pet: cari nama pet di SEMUA sumber, dari yang paling tepat ke yang
-- paling longgar. Urutan penting supaya "KingMammoth" tidak jadi "Mammoth".
local function rarityOf(inst)
  local blob = textBlob(inst)

  -- 1. nama objek: persis -> tanpa awalan mutasi -> longgar
  local key = dbExact(inst.Name) or dbStripMutation(inst.Name) or dbLookup(inst.Name)
  -- 2. kalau nama objek generik ("Egg", "Egg1"), cari di seluruh blob
  if not key then key = dbLookup(blob) end
  if key then return DB[key][1], key end

  -- 3. cadangan: kata rarity eksplisit di teks.
  -- "Uncommon" wajib diuji sebelum "Common" (substring!).
  local lb = lower(blob)
  local order = { "Divine", "Eternal", "Secret", "Cosmic", "Mythic",
                  "Legendary", "Uncommon", "Common", "Epic", "Rare" }
  for _, r in ipairs(order) do
    local pat = "%f[%a]" .. lower(r) .. "%f[%A]"
    if lb:find(pat) then return r, nil end
  end
  return nil, nil
end

-- income per detik dari database (nil kalau pet tidak dikenal)
local function incomeOf(inst, key)
  if not key then
    key = dbExact(inst.Name) or dbStripMutation(inst.Name) or dbLookup(inst.Name)
      or dbLookup(textBlob(inst))
  end
  if key and DB[key] then return DB[key][2], DISPLAY[key] or key, DB[key][3] end
  return nil, nil, nil
end

local function mutationOf(inst)
  local blob = lower(textBlob(inst)) .. " " .. lower(inst.Name)
  -- MUTATION sudah diurut dari terpanjang: "Spirit Bloom" sebelum "Bloom"
  for _, m in ipairs(MUTATION) do
    if blob:find(lower(m), 1, true) then return m end
  end
  return nil
end

-- pengali mutasi resmi
local MUT_MULT = {
  ["Spirit Bloom"] = 3.0,
  ["Rainbow"]      = 2.5,
  ["Golden"]       = 2.0,
  ["Bloom"]        = 1.5,
  ["Silver"]       = 1.25,
}

-- berat telur (kg) kalau ada
local function weightOf(inst)
  local blob = textBlob(inst)
  local n = blob:match("([%d%.,]+)%s*[kK][gG]")
  if n then return tonumber((n:gsub(",", ""))) or 0 end
  for _, d in ipairs(inst:GetDescendants()) do
    if (d:IsA("NumberValue") or d:IsA("IntValue")) and lower(d.Name):find("weight") then
      return d.Value
    end
  end
  return 0
end

local function isEggName(n)
  n = lower(n)
  return n:find("egg") ~= nil
end

-- ============ SCAN OBJEK ============
-- myBase() harus didefinisikan SEBELUM scanEggs() karena scanEggs memakainya;
-- kalau ditaruh di bawah, Lua membacanya sebagai global nil dan scan meledak.
local baseCache, baseCacheT = nil, -1e9
local function flushBaseCache()
  baseCache, baseCacheT = nil, -1e9
end

local function plotOwnerIsMe(plot)
  local hit = false
  pcall(function()
    for _, key in ipairs({ "Owner", "OwnerName", "Player", "PlayerName" }) do
      local o = plot:FindFirstChild(key)
      if o and o:IsA("ValueBase") and tostring(o.Value) == LP.Name then hit = true end
    end
  end)
  if not hit then
    pcall(function()
      for _, v in pairs(plot:GetAttributes()) do
        if tostring(v) == LP.Name then hit = true break end
      end
    end)
  end
  if not hit then
    for _, d in ipairs(plot:GetDescendants()) do
      if d:IsA("StringValue") and tostring(d.Value) == LP.Name then hit = true break end
      if d:IsA("TextLabel") and tostring(d.Text):find(LP.Name, 1, true) then hit = true break end
    end
  end
  return hit
end

-- Apakah objek berada di dalam plot pemain (base)? Telur di base TIDAK boleh
-- jadi sasaran default: laporan nyata v6 — auto steal malah kabur ke base
-- orang lain dan mencoba mencuri telur milik pemain, bukan telur liar di zona.
-- Kembalikan: inPlot, milikPlotSaya
local function plotState(obj)
  local plots = Workspace:FindFirstChild("Plots")
  if not plots then return false, false end
  local p = obj and obj.Parent
  while p and p ~= Workspace do
    if p.Parent == plots then
      return true, plotOwnerIsMe(p)
    end
    p = p.Parent
  end
  return false, false
end

-- Telur yang sedang DIBAWA pemain lain juga milik orang: karakter yang
-- memegangnya akan dikejar kalau tidak disaring — itu laporan nyata kedua.
local function heldByOther(obj)
  local p = obj and obj.Parent
  while p and p ~= Workspace do
    if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then
      local pl = Players:GetPlayerFromCharacter(p)
      if pl then return pl ~= LP end
    end
    p = p.Parent
  end
  return false
end

local function myBase()
  if tick() - baseCacheT < 5 then return baseCache end

  -- game nyata: plot pemain ada di workspace.Plots (terverifikasi Agu 2026)
  local plots = Workspace:FindFirstChild("Plots")
  if plots then
    for _, plot in ipairs(plots:GetChildren()) do
      if (plot:IsA("Model") or plot:IsA("BasePart")) and plotOwnerIsMe(plot) then
        local p = posOf(plot) or (plot:IsA("Model") and plot:GetPivot().Position)
        if p then baseCache, baseCacheT = p, tick(); return p end
      end
    end
    -- tanpa penanda pemilik: plot terdekat ke spawn kita (pemain lahir di plot sendiri)
    local best, bestD = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
      local sp = plot:FindFirstChild("SpawnLocation")
      if sp and sp:IsA("BasePart") then
        local d = math.abs(sp.Position.X) + math.abs(sp.Position.Z)
        if d < bestD then bestD, best = d, sp.Position end
      end
    end
    if best then baseCache, baseCacheT = best, tick(); return best end
  end

  -- cadangan: objek bernama base/plot/garden dengan penanda pemain (game lain)
  for _, v in ipairs(Workspace:GetDescendants()) do
    local n = lower(v.Name)
    if (v:IsA("BasePart") or v:IsA("Model")) and (n:find("base") or n:find("plot") or n:find("garden")) then
      for _, key in ipairs({ "Owner", "OwnerName", "Player", "PlayerName" }) do
        local o = v:FindFirstChild(key)
        if o and o:IsA("ValueBase") and tostring(o.Value) == LP.Name then
          local p = posOf(v) or (v:IsA("Model") and v:GetPivot().Position)
          if p then baseCache, baseCacheT = p, tick(); return p end
        end
      end
      for _, d in ipairs(v:GetDescendants()) do
        if d:IsA("TextLabel") and tostring(d.Text):find(LP.Name) then
          local p = posOf(v)
          if p then baseCache, baseCacheT = p, tick(); return p end
        end
      end
    end
  end
  local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
  return sp and sp.Position or nil
end

-- ============ TELUR GAME NYATA (v6) ============
-- Game ini TIDAK menamai telurnya "Egg": telur hidup di
-- workspace.AreaEggSlotsClient (tiap slot punya part "Plane"), telur event
-- berdiri sendiri dengan anak "Hitbox", telur langka bertanda
-- "RareAreaEggHighlight", telur parasit "MonsterParasiteVisual". Versi lama
-- mencari nama 'egg' → tidak menemukan apa pun → "pet tidak ada di database".
local function eggFromEntry(entryObj, kind, rare)
  local part = entryObj:FindFirstChild("Plane") or firstPartOf(entryObj)
  if not (part and part:IsA("BasePart")) then return nil end
  local pos = part.Position
  local rar, key = rarityOf(entryObj)
  local inc, petName, biome = incomeOf(entryObj, key)
  local mut = mutationOf(entryObj)
  local mine = false
  local bpos = myBase()
  if bpos and dist(pos, bpos) < S.baseGuard then mine = true end
  local ap = entryObj.Parent
  while ap and ap ~= Workspace do
    if ap == LP.Character then mine = true break end
    ap = ap.Parent
  end
  local inPlot, myPlot = plotState(entryObj)
  if myPlot then mine = true end
  local owned = inPlot or heldByOther(entryObj)
  return {
    obj    = entryObj,
    part   = part,
    pos    = pos,
    rar    = rar,
    key    = key,
    pet    = petName,
    biome  = biome or zoneOf(pos),
    income = inc,
    mut    = mut,
    mult   = mut and MUT_MULT[mut] or 1,
    wt     = weightOf(entryObj),
    mine   = mine,
    owned  = owned,      -- telur ini milik/dipegang pemain lain
    rare   = rare or false,
    kind   = kind,
  }
end

local function scanSlotEggs()
  local out = {}
  local sl = Workspace:FindFirstChild("AreaEggSlotsClient")
  if sl then
    for _, s in ipairs(sl:GetChildren()) do
      local e = eggFromEntry(s, nil, s:FindFirstChild("RareAreaEggHighlight") ~= nil)
      if e then
        if s:FindFirstChild("MonsterParasiteVisual") then e.kind = "parasite" end
        out[#out + 1] = e
      end
    end
  end
  -- telur event: objek Workspace berdiri sendiri dengan anak Hitbox
  for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("Model") and obj:FindFirstChild("Hitbox") then
      local e = eggFromEntry(obj, "event", findNamed(obj, "RareAreaEggHighlight") ~= nil)
      if e then
        if findNamed(obj, "MonsterParasiteVisual") then e.kind = "parasite" end
        out[#out + 1] = e
      end
    end
  end
  return out
end

-- Telur milik sendiri (sudah di base) ditandai `mine` supaya loop steal tidak
-- memilihnya lagi — itu penyebab "mundar-mandir di base".
local function scanEggs()
  local out = {}
  local seen = {}
  local base = myBase()

  -- 1. telur game nyata (slot AreaEggSlotsClient + telur event) — lihat v6 di atas
  for _, e in ipairs(scanSlotEggs()) do
    seen[e.obj] = true
    if e.part then seen[e.part] = true end
    out[#out + 1] = e
  end

  -- 2. deteksi nama generik (game/event lain): nama memuat 'egg' atau cocok db
  for _, v in ipairs(Workspace:GetDescendants()) do
    if (v:IsA("Model") or v:IsA("BasePart")) and not seen[v] then
      local nameHit = isEggName(v.Name)
      local dbHit = dbExact(v.Name) or dbStripMutation(v.Name)
      if nameHit or dbHit then
        local parentListed = false
        local p = v.Parent
        while p and p ~= Workspace do
          if seen[p] then parentListed = true break end
          p = p.Parent
        end
        if not parentListed then
          local pos = posOf(v)
          if pos then
            seen[v] = true
            local rar, key = rarityOf(v)
            local inc, petName, biome = incomeOf(v, key)
            local mut = mutationOf(v)
            -- apakah telur ini sudah ada di base sendiri / sedang dibawa?
            local mine = false
            if base and dist(pos, base) < S.baseGuard then mine = true end
            local ap = v.Parent
            while ap and ap ~= Workspace do
              if ap == LP.Character then mine = true break end
              ap = ap.Parent
            end
            local inPlot, myPlot = plotState(v)
            if myPlot then mine = true end
            out[#out + 1] = {
              obj    = v,
              pos    = pos,
              rar    = rar,
              key    = key,
              pet    = petName,
              biome  = biome or zoneOf(pos),
              income = inc,
              mut    = mut,
              mult   = mut and MUT_MULT[mut] or 1,
              wt     = weightOf(v),
              mine   = mine,
              owned  = inPlot or heldByOther(v),
            }
          end
        end
      end
    end
  end
  return out
end

local function scanTraps()
  local out = {}
  for _, v in ipairs(Workspace:GetDescendants()) do
    local n = lower(v.Name)
    if v:IsA("BasePart") or v:IsA("Model") then
      if n:find("trap") or n:find("spike") or n:find("mine") or n:find("net")
         or n:find("snare") or n:find("bomb") then
        local p = posOf(v)
        if p then out[#out + 1] = { obj = v, pos = p } end
      end
    end
  end
  return out
end

local function scanHostiles()
  local out = {}
  for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
      local n = lower(v.Name)
      local kind = (n:find("bat") and "bat")
        or ((n:find("guard") or n:find("guardian")) and "guard")
        or ((n:find("beast") or n:find("boss")) and "beast")
        or nil
      if kind then
        local p = posOf(v)
        if p then out[#out + 1] = { obj = v, pos = p, kind = kind } end
      end
    end
  end
  return out
end
