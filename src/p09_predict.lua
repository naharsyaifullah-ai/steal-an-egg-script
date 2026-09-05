-- ============ PREDIKSI SIKLUS TELUR ============
-- Jujur soal batasnya: spawn Secret/Eternal/Divine di Steal An Egg adalah
-- UNDIAN ACAK tiap reset (±5 menit), bukan jadwal tetap. Jadi "Divine jam 14:32"
-- tidak bisa dijanjikan siapa pun. Yang BISA nyata:
--   1. periode reset diukur sendiri dari perubahan isi map  -> waktu reset berikutnya presisi
--   2. deteksi instan begitu telur langka muncul (+ lokasi, jarak, ETA)
--   3. peluang empiris dari reset yang benar-benar tercatat  -> perkiraan waktu tunggu
--   4. probe state "telur berikutnya" kalau server memang mereplikasi datanya
-- Tidak ada angka yang dikarang. Sebelum ada data, tampilannya kosong.

local PRED = {
  watch      = false,
  autoGo     = false,
  notify     = { Secret = true, Eternal = true, Divine = true },

  period     = nil,      -- detik, hasil ukur sendiri
  lastReset  = nil,      -- tick() reset terakhir
  resetTimes = {},       -- riwayat tick() reset
  observed   = 0,        -- jumlah reset tercatat
  counts     = {},       -- rarity -> berapa reset memuat rarity itu
  seenNames  = {},       -- rarity -> nama telur terakhir
  alerts     = {},       -- temuan langka terbaru
  probe      = nil,      -- hasil probe state next-egg
  sig        = nil,      -- sidik jari isi map
  liveTimer  = nil,      -- hitung mundur bawaan game kalau ketemu
  announces  = 0,        -- jumlah pengumuman server tertangkap
  lastAnn    = nil,
}

local function fmtDur(s)
  if not s then return "-" end
  s = math.max(0, math.floor(s))
  if s < 60 then return s .. "s" end
  if s < 3600 then return string.format("%dm %02ds", s // 60, s % 60) end
  if s < 86400 then return string.format("%dj %02dm", s // 3600, (s % 3600) // 60) end
  return string.format("%dh %02dj", s // 86400, (s % 86400) // 3600)
end

-- sidik jari isi map: nama + posisi dibulatkan
local function eggSignature()
  local eggs = scanEggs()
  local ids = {}
  for _, e in ipairs(eggs) do
    ids[#ids + 1] = e.obj.Name .. "@" .. math.floor(e.pos.X) .. "," .. math.floor(e.pos.Z)
  end
  table.sort(ids)
  return table.concat(ids, ";"), eggs
end

local function setFromList(list)
  local s = {}
  for _, v in ipairs(list) do s[v] = true end
  return s
end

local function splitSig(sig)
  local out = {}
  if not sig then return out end
  for part in string.gmatch(sig, "[^;]+") do out[#out + 1] = part end
  return out
end

-- seberapa mirip dua isi map (0 = beda total, 1 = sama)
local function similarity(a, b)
  local la, lb = splitSig(a), splitSig(b)
  if #la == 0 and #lb == 0 then return 1 end
  local sa = setFromList(la)
  local inter = 0
  for _, v in ipairs(lb) do if sa[v] then inter = inter + 1 end end
  local union = #la + #lb - inter
  if union == 0 then return 1 end
  return inter / union
end

-- hitung mundur bawaan game: cari label m:ss / NNs dekat kata reset/night/egg
local function findLiveTimer()
  local best = nil
  local function consider(txt)
    if type(txt) ~= "string" then return end
    local m, s = txt:match("^%s*(%d+):(%d%d)%s*$")
    if m then
      local v = tonumber(m) * 60 + tonumber(s)
      if v <= 900 then best = best or v end
      return
    end
    local only = txt:match("^%s*(%d+)%s*[sS]%s*$")
    if only then
      local v = tonumber(only)
      if v <= 900 then best = best or v end
    end
  end
  local pg = LP:FindFirstChild("PlayerGui")
  if pg then
    for _, d in ipairs(pg:GetDescendants()) do
      if d:IsA("TextLabel") then consider(d.Text) end
    end
  end
  for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("TextLabel") then consider(d.Text) end
  end
  return best
end

-- periode = median selisih antar reset yang tercatat
local function computePeriod()
  local t = PRED.resetTimes
  if #t < 2 then return nil end
  local diffs = {}
  for i = 2, #t do diffs[#diffs + 1] = t[i] - t[i - 1] end
  table.sort(diffs)
  local mid = #diffs // 2 + 1
  local med = (#diffs % 2 == 1) and diffs[mid] or ((diffs[mid - 1] + diffs[mid]) / 2)
  return med, #diffs
end

-- reset berikutnya: pakai timer game kalau ada, kalau tidak pakai periode terukur
local function nextResetIn()
  if PRED.liveTimer then return PRED.liveTimer, "timer game" end
  if PRED.period and PRED.lastReset then
    local left = PRED.period - (tick() - PRED.lastReset)
    while left < 0 do left = left + PRED.period end
    return left, "periode terukur"
  end
  return nil, "belum cukup data"
end

-- peluang & perkiraan tunggu untuk satu rarity — nil kalau datanya belum ada
local function odds(rar)
  local n = PRED.observed
  if n < 1 then return nil, 0, 0 end
  local c = PRED.counts[rar] or 0
  if c == 0 then return nil, n, 0 end
  local rate = c / n
  local per = PRED.period or 300
  return per / rate, n, rate
end

local function pushAlert(e, source)
  table.insert(PRED.alerts, 1, {
    t    = tick(),
    rar  = e.rar,
    mut  = e.mut,
    name = e.obj and e.obj.Name or "?",
    pos  = e.pos,
    src  = source or "scan",
  })
  while #PRED.alerts > 8 do table.remove(PRED.alerts) end
end

-- probe: apakah server benar-benar mereplikasi "telur berikutnya"?
local function probeNextEgg()
  local hits = {}
  local KEY = { "next", "upcoming", "queue", "pool", "incoming", "schedule", "rolled" }
  local function nameLooksRight(n)
    n = lower(n)
    if not (n:find("egg") or n:find("rarity") or n:find("spawn") or n:find("reset")) then return false end
    for _, k in ipairs(KEY) do if n:find(k) then return true end end
    return false
  end
  local roots = { RS, Workspace }
  for _, root in ipairs(roots) do
    for _, d in ipairs(root:GetDescendants()) do
      if d:IsA("ValueBase") and nameLooksRight(d.Name) then
        hits[#hits + 1] = d.Name .. " = " .. tostring(d.Value)
      end
    end
  end
  PRED.probe = {
    t     = tick(),
    found = #hits,
    list  = hits,
  }
  return PRED.probe
end

-- hook pengumuman server (kalau gamenya memang mengirim lewat RemoteEvent)
local annHooked = {}
local function hookAnnouncements()
  local n = 0
  for _, r in ipairs(remotes) do
    if r:IsA("RemoteEvent") and not annHooked[r] then
      local nm = lower(r.Name)
      if nm:find("announce") or nm:find("notif") or nm:find("broadcast")
        or nm:find("global") or nm:find("alert") or nm:find("message") then
        annHooked[r] = true
        n = n + 1
        pcall(function()
          r.OnClientEvent:Connect(function(...)
            local blob = ""
            for _, a in ipairs({ ... }) do
              if type(a) == "string" then blob = blob .. " " .. a
              elseif type(a) == "table" then
                for _, v in pairs(a) do
                  if type(v) == "string" then blob = blob .. " " .. v end
                end
              end
            end
            local lb = lower(blob)
            for i = #RARITY, 1, -1 do
              if lb:find(lower(RARITY[i]), 1, true) then
                PRED.announces = PRED.announces + 1
                PRED.lastAnn = { t = tick(), rar = RARITY[i], text = blob:sub(1, 90) }
                break
              end
            end
          end)
        end)
      end
    end
  end
  return n
end
