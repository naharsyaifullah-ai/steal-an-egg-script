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

-- ambil semua teks di dalam objek (kalau game memang memasang label)
local function textBlob(inst)
  local t = { inst.Name }
  for _, d in ipairs(inst:GetDescendants()) do
    if d:IsA("TextLabel") or d:IsA("TextBox") then
      t[#t + 1] = d.Text
    elseif d:IsA("StringValue") then
      t[#t + 1] = d.Name .. "=" .. tostring(d.Value)
    elseif d:IsA("NumberValue") or d:IsA("IntValue") then
      t[#t + 1] = d.Name .. "=" .. tostring(d.Value)
    end
  end
  return table.concat(t, " | ")
end

-- Rarity: DATABASE PET DULU, label teks cuma cadangan.
-- Versi lama hanya mencari kata rarity di teks. Game tidak menempelkan label
-- itu, jadi hampir semua telur jadi nil dan filter menolak semuanya —
-- inilah sebabnya "cuma Uncommon yang kena": satu-satunya telur yang teksnya
-- kebetulan memuat kata rarity. Sekarang nama pet dipetakan ke rarity resmi.
local function rarityOf(inst)
  local key = dbLookup(inst.Name)
  if key then return DB[key][1], key end

  -- cadangan: cari nama pet di seluruh teks objek
  local blob = textBlob(inst)
  local k2 = dbLookup(blob)
  if k2 then return DB[k2][1], k2 end

  -- cadangan terakhir: kata rarity eksplisit di teks.
  -- "Uncommon" wajib diuji sebelum "Common" (substring!), jadi urut dari
  -- yang terpanjang, bukan dari indeks tabel.
  local lb = lower(blob)
  local order = { "Divine", "Eternal", "Secret", "Cosmic", "Mythic",
                  "Legendary", "Uncommon", "Common", "Epic", "Rare" }
  for _, r in ipairs(order) do
    -- batas kata supaya "Rare" tidak ikut kena dari "Rarest"/"Uncommon"
    local pat = "%f[%a]" .. lower(r) .. "%f[%A]"
    if lb:find(pat) then return r, nil end
  end
  return nil, nil
end

-- income per detik dari database (nil kalau pet tidak dikenal)
local function incomeOf(inst, key)
  key = key or dbLookup(inst.Name) or dbLookup(textBlob(inst))
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
local function scanEggs()
  local out = {}
  local seen = {}
  for _, v in ipairs(Workspace:GetDescendants()) do
    if (v:IsA("Model") or v:IsA("BasePart")) and not seen[v] then
      local nameHit = isEggName(v.Name)
      local dbHit = dbExact(v.Name)     -- ketat: "BearTrap" bukan telur Bear
      if nameHit or dbHit then
        -- kalau induknya sudah terdaftar, lewati anaknya (hindari duplikat)
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
