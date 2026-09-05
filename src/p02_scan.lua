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
local function myBase()
  for _, v in ipairs(Workspace:GetDescendants()) do
    local n = lower(v.Name)
    if (v:IsA("BasePart") or v:IsA("Model")) and (n:find("base") or n:find("plot") or n:find("garden")) then
      for _, key in ipairs({ "Owner", "OwnerName", "Player", "PlayerName" }) do
        local o = v:FindFirstChild(key)
        if o and o:IsA("ValueBase") and tostring(o.Value) == LP.Name then
          return posOf(v) or (v:IsA("Model") and v:GetPivot().Position)
        end
      end
      for _, d in ipairs(v:GetDescendants()) do
        if d:IsA("TextLabel") and tostring(d.Text):find(LP.Name) then
          return posOf(v)
        end
      end
    end
  end
  local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
  return sp and sp.Position or nil
end

-- Telur milik sendiri (sudah di base) ditandai `mine` supaya loop steal tidak
-- memilihnya lagi — itu penyebab "mundar-mandir di base".
local function scanEggs()
  local out = {}
  local seen = {}
  local base = myBase()
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
            out[#out + 1] = {
              obj    = v,
              pos    = pos,
              rar    = rar,
              key    = key,
              pet    = petName,
              biome  = biome,
              income = inc,
              mut    = mut,
              mult   = mut and MUT_MULT[mut] or 1,
              wt     = weightOf(v),
              mine   = mine,
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
