-- ============ PEREKAM CARA AMBIL (remote spy) ============
-- Dua versi sebelumnya MENEBAK nama remote ("steal", "pickup", ...) dan gagal.
-- Menebak bukan jalan keluar. Modul ini MEREKAM apa yang benar-benar terjadi
-- saat pengguna mengambil telur dengan tangan sendiri:
--   · setiap RemoteEvent/RemoteFunction yang ditembak klien, beserta argumennya
--   · ProximityPrompt mana yang benar-benar terpicu
--   · apakah pengambilan terjadi TANPA remote sama sekali (murni sentuhan)
-- Lalu hasil rekaman itu diputar ulang apa adanya untuk auto steal.

local SPY = {
  hooked     = false,
  recording  = false,
  log        = {},        -- {t, name, method, args, argdesc, path}
  prompts    = {},        -- {t, name, path}
  learned    = nil,       -- {name, method, template, path}
  learnedFrom= nil,       -- "remote" | "prompt" | "touch"
  note       = "belum merekam",
  fires      = 0,
  lastPickup = nil,
  onDisk     = false,     -- resep tersimpan di berkas executor?
}

local MAXLOG = 60

-- Deteksi Instance tanpa bergantung pada typeof(): di beberapa lingkungan
-- typeof tidak ada, dan tebakan lewat type() mengembalikan "table" sehingga
-- objek telur tidak dikenali di argumen — itu membuat resep salah bentuk.
local function isInstance(v)
  if typeof and typeof(v) == "Instance" then return true end
  if type(v) ~= "table" and type(v) ~= "userdata" then return false end
  local ok, res = pcall(function()
    return v.ClassName ~= nil and type(v.IsA) == "function"
  end)
  return ok and res == true
end

local function isDescendantOf(v, root)
  if not (isInstance(v) and root) then return false end
  local ok, res = pcall(function() return v:IsDescendantOf(root) end)
  if ok then return res == true end
  -- cadangan: jalan naik rantai induk sendiri
  local ok2, res2 = pcall(function()
    local p = v.Parent
    while p do
      if p == root then return true end
      p = p.Parent
    end
    return false
  end)
  return ok2 and res2 == true
end

local function pathOf(inst)
  local parts, n = {}, inst
  local hops = 0
  while n and hops < 6 do
    table.insert(parts, 1, n.Name)
    n = n.Parent
    hops = hops + 1
  end
  return table.concat(parts, ".")
end

local function describeArg(v)
  if isInstance(v) then
    local cn, nm = "?", "?"
    pcall(function() cn = tostring(v.ClassName); nm = tostring(v.Name) end)
    return "Instance(" .. cn .. ":" .. nm .. ")"
  end
  local t = type(v)
  if t == "string" then
    return '"' .. tostring(v):sub(1, 24) .. '"'
  elseif t == "table" then
    local keys = {}
    for k in pairs(v) do
      keys[#keys + 1] = tostring(k)
      if #keys >= 4 then break end
    end
    return "table{" .. table.concat(keys, ",") .. "}"
  end
  return t .. "(" .. tostring(v):sub(1, 20) .. ")"
end

local function describeArgs(args)
  local d = {}
  for i = 2, args.n do d[#d + 1] = describeArg(args[i]) end
  return table.concat(d, ", ")
end

-- Ubah argumen rekaman menjadi cetakan (template) yang bisa dipakai ulang.
-- Argumen yang menunjuk telur diganti placeholder, sisanya dipakai apa adanya.
local function buildTemplate(args, eggObj)
  local tpl = {}
  for i = 2, args.n do
    local v = args[i]
    local slot
    if v == eggObj then
      slot = { kind = "egg" }
    elseif isDescendantOf(v, eggObj) then
      slot = { kind = "egg" }
    elseif eggObj and type(v) == "string" and v == eggObj.Name then
      slot = { kind = "eggname" }
    elseif type(v) == "table" and not isInstance(v) then
      -- salin dangkal, tukar nilai yang menunjuk telur
      local copy = {}
      for k, vv in pairs(v) do
        if vv == eggObj then copy[k] = "__EGG__"
        elseif eggObj and type(vv) == "string" and vv == eggObj.Name then copy[k] = "__EGGNAME__"
        else copy[k] = vv end
      end
      slot = { kind = "table", value = copy }
    else
      slot = { kind = "literal", value = v }
    end
    tpl[#tpl + 1] = slot
  end
  return tpl
end

local function fillTemplate(tpl, eggObj)
  local out = {}
  for i, slot in ipairs(tpl) do
    if slot.kind == "egg" then
      out[i] = eggObj
    elseif slot.kind == "eggname" then
      out[i] = eggObj and eggObj.Name or ""
    elseif slot.kind == "table" then
      local copy = {}
      for k, v in pairs(slot.value) do
        if v == "__EGG__" then copy[k] = eggObj
        elseif v == "__EGGNAME__" then copy[k] = eggObj and eggObj.Name or ""
        else copy[k] = v end
      end
      out[i] = copy
    else
      out[i] = slot.value
    end
  end
  return out, #tpl
end

local function describeTemplate(tpl)
  local d = {}
  for _, s in ipairs(tpl) do
    if s.kind == "egg" then d[#d + 1] = "<telur>"
    elseif s.kind == "eggname" then d[#d + 1] = "<nama telur>"
    elseif s.kind == "table" then d[#d + 1] = "table"
    else d[#d + 1] = describeArg(s.value) end
  end
  return table.concat(d, ", ")
end

-- ---------- pemasangan hook ----------
local function recordFire(remote, method, args)
  SPY.fires = SPY.fires + 1
  local entry = {
    t       = tick(),
    name    = remote.Name,
    method  = method,
    args    = args,
    argdesc = describeArgs(args),
    path    = pathOf(remote),
    remote  = remote,
  }
  table.insert(SPY.log, 1, entry)
  while #SPY.log > MAXLOG do table.remove(SPY.log) end
  return entry
end

-- Jalur suntik untuk harness uji. Di Roblox, recordFire dipanggil dari hook
-- __namecall; harness tidak bisa memasang hook itu, jadi ia memakai pintu ini.
function SPY.recordForTest(remote, method, args)
  return recordFire(remote, method, args)
end

function SPY.install()
  if SPY.hooked then return true, "sudah terpasang" end

  -- jalur utama: hookmetamethod pada __namecall (didukung Delta/Synapse/dll)
  local okHook = false
  pcall(function()
    if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
      local old
      old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if (m == "FireServer" or m == "InvokeServer") and SPY.recording then
          -- table.pack di sini, JANGAN '...' di dalam closure pcall
          local packed = table.pack(self, ...)
          pcall(function()
            if self and self.IsA and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
              recordFire(self, m, packed)
            end
          end)
        end
        return old(self, ...)
      end)
      okHook = true
    end
  end)

  -- jalur cadangan: ganti metatable mentah
  if not okHook then
    pcall(function()
      local mt = getrawmetatable and getrawmetatable(game)
      if mt and setreadonly then
        setreadonly(mt, false)
        local oldNC = mt.__namecall
        mt.__namecall = function(self, ...)
          local m = getnamecallmethod and getnamecallmethod() or ""
          if (m == "FireServer" or m == "InvokeServer") and SPY.recording then
            local packed = table.pack(self, ...)
            pcall(function()
              if self and self.IsA and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                recordFire(self, m, packed)
              end
            end)
          end
          return oldNC(self, ...)
        end
        setreadonly(mt, true)
        okHook = true
      end
    end)
  end

  -- hook prompt: catat prompt mana yang benar-benar terpicu
  pcall(function()
    for _, p in ipairs(Workspace:GetDescendants()) do
      if p:IsA("ProximityPrompt") then
        p.Triggered:Connect(function()
          if SPY.recording then
            table.insert(SPY.prompts, 1, { t = tick(), name = p.Parent and p.Parent.Name or "?", path = pathOf(p) })
            while #SPY.prompts > 20 do table.remove(SPY.prompts) end
          end
        end)
      end
    end
  end)

  SPY.hooked = okHook
  SPY.note = okHook and "hook terpasang" or "executor tidak mendukung hook remote"
  return okHook, SPY.note
end

-- ---------- belajar dari rekaman ----------
-- Dipanggil saat terdeteksi telur BERHASIL terambil oleh pengguna.
function SPY.learnFrom(eggObj, sinceT)
  sinceT = sinceT or (tick() - 4)

  -- 1. remote yang argumennya menyebut telur ini -> paling meyakinkan
  for _, e in ipairs(SPY.log) do
    if e.t >= sinceT then
      for i = 2, e.args.n do
        local v = e.args[i]
        local hit = (v == eggObj)
        if not hit and type(v) == "string" and eggObj and v == eggObj.Name then hit = true end
        if not hit and isDescendantOf(v, eggObj) then hit = true end
        if hit then
          SPY.learned = {
            name = e.name, method = e.method, path = e.path,
            remote = e.remote,
            template = buildTemplate(e.args, eggObj),
          }
          SPY.learnedFrom = "remote"
          SPY.note = "belajar: " .. e.name .. "(" .. describeTemplate(SPY.learned.template) .. ")"
          return true
        end
      end
    end
  end

  -- 2. remote terakhir sebelum telur terambil, walau argumennya tidak menyebut telur
  for _, e in ipairs(SPY.log) do
    if e.t >= sinceT then
      SPY.learned = {
        name = e.name, method = e.method, path = e.path,
        remote = e.remote,
        template = buildTemplate(e.args, eggObj),
      }
      SPY.learnedFrom = "remote"
      SPY.note = "belajar (tanpa arg telur): " .. e.name
      return true
    end
  end

  -- 3. tidak ada remote: prompt?
  for _, p in ipairs(SPY.prompts) do
    if p.t >= sinceT then
      SPY.learned = nil
      SPY.learnedFrom = "prompt"
      SPY.note = "ambil lewat ProximityPrompt di " .. p.name .. " (tanpa remote)"
      return true
    end
  end

  -- 4. benar-benar tanpa apa pun: murni sentuhan / server-side
  SPY.learned = nil
  SPY.learnedFrom = "touch"
  SPY.note = "tidak ada remote & prompt — pengambilan murni sentuhan; yang penting mendekat"
  return true
end

-- putar ulang cara yang sudah dipelajari
function SPY.replay(eggObj)
  local L = SPY.learned
  if not L then return false end
  local ok = false
  pcall(function()
    local r = L.remote
    if not (r and r.Parent) then return end
    local args, n = fillTemplate(L.template, eggObj)
    if L.method == "InvokeServer" then
      r:InvokeServer(table.unpack(args, 1, n))
    else
      r:FireServer(table.unpack(args, 1, n))
    end
    ok = true
  end)
  return ok
end

-- ---------- PERSISTENSI (v6) ----------
-- Keluhan "masa harus diajari terus": sekarang resep hasil AJARI ditulis ke
-- berkas executor (writefile) dan dimuat ulang otomatis saat script jalan
-- lagi di lain waktu. AJARI cukup sekali.
local RECIPE_FILE = "SAE_Recipe.lua"

local function litOut(v)
  local t = type(v)
  if t == "string" then return string.format("%q", v) end
  if t == "number" or t == "boolean" then return tostring(v) end
  if v == nil then return "nil" end
  return nil            -- Instance/func/tabel dalam: tidak bisa disimpan
end

local function slotStorable(slot)
  if slot.kind == "egg" or slot.kind == "eggname" then return true end
  if slot.kind == "literal" then return litOut(slot.value) ~= nil end
  if slot.kind == "table" then
    for k, v in pairs(slot.value) do
      if litOut(k) == nil or litOut(v) == nil then return false end
    end
    return true
  end
  return false
end

function SPY.saveRecipe()
  local L = SPY.learned
  if not (L and L.template and L.name and L.method) then return false end
  if type(writefile) ~= "function" then return false end
  local parts = {}
  for i, slot in ipairs(L.template) do
    if not slotStorable(slot) then return false end
    if slot.kind == "egg" then
      parts[i] = '{kind="egg"}'
    elseif slot.kind == "eggname" then
      parts[i] = '{kind="eggname"}'
    elseif slot.kind == "table" then
      local kv = {}
      for k, v in pairs(slot.value) do
        kv[#kv + 1] = "[" .. litOut(k) .. "]=" .. litOut(v)
      end
      parts[i] = '{kind="table", value={' .. table.concat(kv, ",") .. '}}'
    else
      parts[i] = '{kind="literal", value=' .. litOut(slot.value) .. '}'
    end
  end
  local src = "return {name=" .. string.format("%q", L.name)
    .. ", method=" .. string.format("%q", L.method)
    .. ", template={" .. table.concat(parts, ",") .. "}}"
  local ok = pcall(writefile, RECIPE_FILE, src)
  if ok then SPY.onDisk = true end
  return ok
end

function SPY.loadRecipe()
  SPY.onDisk = false
  if not (type(readfile) == "function" and type(isfile) == "function"
    and type(loadstring) == "function") then return false end
  local ok, exists = pcall(isfile, RECIPE_FILE)
  if not (ok and exists) then return false end
  local ok2, src = pcall(readfile, RECIPE_FILE)
  if not (ok2 and type(src) == "string") then return false end
  local okc, chunk = pcall(loadstring, src)
  if not (okc and type(chunk) == "function") then return false end
  local okr, data = pcall(chunk)
  if not (okr and type(data) == "table" and data.name and data.method
    and type(data.template) == "table") then return false end
  for _, slot in ipairs(data.template) do
    if not (type(slot) == "table" and slot.kind) then return false end
  end
  -- remote diselesaikan ulang lewat nama: path bisa berubah antar update game
  local remote = findRemoteByName(data.name)
  if not remote then return false end
  SPY.learned = { name = data.name, method = data.method,
    remote = remote, template = data.template }
  SPY.learnedFrom = "remote"
  SPY.onDisk = true
  SPY.note = "resep dimuat dari berkas: " .. data.name
  return true
end

pcall(function() SPY.loadRecipe() end)

function SPY.summary()
  local lines = {}
  lines[#lines + 1] = "status : " .. SPY.note
  lines[#lines + 1] = "hook   : " .. (SPY.hooked and "aktif" or "TIDAK aktif")
  lines[#lines + 1] = "rekam  : " .. (SPY.recording and "MENYALA" or "mati")
  lines[#lines + 1] = "tembakan tercatat: " .. SPY.fires
  lines[#lines + 1] = "berkas : " .. (SPY.onDisk and "resep tersimpan (dimuat otomatis)" or "belum ada resep tersimpan")
  if SPY.learned then
    lines[#lines + 1] = "dipakai: " .. SPY.learned.name
      .. ":" .. SPY.learned.method
      .. "(" .. describeTemplate(SPY.learned.template) .. ")"
  elseif SPY.learnedFrom then
    lines[#lines + 1] = "dipakai: cara " .. SPY.learnedFrom
  end
  if #SPY.log > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "remote terakhir:"
    for i = 1, math.min(6, #SPY.log) do
      local e = SPY.log[i]
      lines[#lines + 1] = "  " .. e.name .. "(" .. e.argdesc:sub(1, 46) .. ")"
    end
  end
  return table.concat(lines, "\n")
end
