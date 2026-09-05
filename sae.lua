--[[
  STEAL AN EGG — Delta Hub v3
  Hermes Agent · 5 Sep 2026
  https://github.com/naharsyaifullah-ai/steal-an-egg-script

  Perbaikan v3 (dari laporan bug):
   · rarity dibaca dari DATABASE 80 pet, bukan label teks — dulu hampir semua
     telur tak terbaca sehingga cuma satu rarity yang kena filter
   · jalan pakai Humanoid:MoveTo, TIDAK terbang, tidak jatuh terhuyung
   · kecepatan steal punya slider sendiri di tab STEAL
   · ESP menampilkan rarity + nama pet + income $/s + mutasi + berat + jarak

  Resiko: cheat bisa kena ban. Pakai akun cadangan.
]]

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local LP                = Players.LocalPlayer

-- urutan rarity dari terendah ke Divine (10 tier resmi)
local RARITY = {
  "Common", "Uncommon", "Rare", "Epic", "Legendary",
  "Mythic", "Cosmic", "Secret", "Eternal", "Divine",
}

local RCOLOR = {
  Common    = Color3.fromRGB(150, 160, 175),
  Uncommon  = Color3.fromRGB(120, 220, 150),
  Rare      = Color3.fromRGB(90,  170, 255),
  Epic      = Color3.fromRGB(180, 130, 255),
  Legendary = Color3.fromRGB(255, 190, 80),
  Mythic    = Color3.fromRGB(255, 110, 200),
  Cosmic    = Color3.fromRGB(90,  230, 240),
  Secret    = Color3.fromRGB(255, 235, 130),
  Eternal   = Color3.fromRGB(200, 120, 255),
  Divine    = Color3.fromRGB(255, 255, 255),
}

-- mutasi diurut dari NAMA TERPANJANG supaya "Spirit Bloom" tidak
-- keliru terbaca sebagai "Bloom"
local MUTATION = { "Spirit Bloom", "Rainbow", "Golden", "Bloom", "Silver" }

-- ============ STATE ============
local S = {
  -- steal
  stealOn      = false,
  rarityPick   = {},
  minWeight    = 0,
  minIncome    = 0,        -- filter income $/s minimum
  maxRange     = 3000,     -- jarak maksimum telur yang dikejar
  preferMutasi = true,
  returnBase   = true,
  stealDelay   = 0.25,
  stealSpeed   = 180,      -- kecepatan khusus saat steal (stud/detik)
  takeUnknown  = true,     -- telur yang tidak dikenal database tetap diambil
  baseGuard    = 60,       -- telur sedekat ini ke base sendiri diabaikan
  grabTries    = 3,        -- berapa kali usaha ambil per telur

  -- gerak
  walkMode     = false,    -- false = terbang datar (hop), true = jalan kaki

  -- farm
  autoHatch    = false,
  autoClaim    = false,
  autoTrain    = false,
  autoSell     = false,
  autoUpgrade  = false,

  -- player
  speedOn      = false,
  speed        = 120,      -- kecepatan gerak umum
  antiTrap     = false,
  antiBat      = false,
  antiStun     = true,     -- default ON: mencegah ragdoll saat steal
  noFall       = true,
  avoidRadius  = 26,

  -- esp
  espEgg       = false,
  espPlayer    = false,
  espTrap      = false,
  espGuard     = false,
  espMinRarity = 1,
  espRange     = 3000,
  espUnknown   = true,     -- tampilkan juga telur yang belum dikenal

  -- runtime
  status       = "idle",
  stolen       = 0,
  fails        = 0,
  lastEgg      = "-",
  lastGrab     = "-",
}

for _, r in ipairs(RARITY) do S.rarityPick[r] = false end
S.rarityPick.Secret  = true
S.rarityPick.Eternal = true
S.rarityPick.Divine  = true


-- ============ DATABASE PET & TELUR (106 pet) ============
-- Sumber, diambil 5 Sep 2026 lewat you.com:
--   · Eldorado "all pets index"  -> 80 pet, 10 biome
--   · Joytify + Timesaver.gg     -> Titan Temple (Update 2, 29-30 Agu 2026)
--   · IGN All_Pets               -> Monster Egg 12 pet (income belum diindeks)
-- Angka income = NILAI DASAR pet. Di game, berat/ukuran telur ikut menentukan
-- money/s akhir, jadi ini patokan, bukan hasil persis.
-- Kunci = nama pet huruf kecil tanpa spasi/tanda baca.

local DB = {
  -- Forest
  chicken            = { "Common",    1,          "Forest" },
  dog                = { "Common",    2,          "Forest" },
  bird               = { "Uncommon",  8,          "Forest" },
  owl                = { "Rare",      35,         "Forest" },
  raccoon            = { "Rare",      45,         "Forest" },
  bear               = { "Epic",      240,        "Forest" },
  fox                = { "Epic",      180,        "Forest" },
  brrbrrpatapim      = { "Legendary", 1800,       "Forest" },
  -- Lake
  frog               = { "Common",    3,          "Lake" },
  duckling           = { "Common",    4,          "Lake" },
  catfish            = { "Uncommon",  12,         "Lake" },
  turtle             = { "Rare",      60,         "Lake" },
  trulimerotrulicina = { "Epic",      260,        "Lake" },
  swan               = { "Epic",      320,        "Lake" },
  axolotl            = { "Legendary", 2800,       "Lake" },
  leviathan          = { "Cosmic",    220000,     "Lake" },
  -- Desert
  jerboa             = { "Common",    6,          "Desert" },
  fennec             = { "Uncommon",  18,         "Desert" },
  camel              = { "Rare",      75,         "Desert" },
  tobtobitobtob      = { "Epic",      325,        "Desert" },
  snake              = { "Legendary", 3600,       "Desert" },
  scorpion           = { "Mythic",    18500,      "Desert" },
  sandspider         = { "Mythic",    16000,      "Desert" },
  royalsphinx        = { "Cosmic",    280000,     "Desert" },
  -- Jungle
  toucan             = { "Rare",      110,        "Jungle" },
  chimpanzee         = { "Rare",      90,         "Jungle" },
  crocodile          = { "Epic",      420,        "Jungle" },
  gorilla            = { "Legendary", 4800,       "Jungle" },
  orangutiniananassini = { "Legendary", 5500,     "Jungle" },
  spider             = { "Mythic",    22000,      "Jungle" },
  tiger              = { "Mythic",    28000,      "Jungle" },
  kingsnake          = { "Secret",    3500000,    "Jungle" },
  -- Snow
  penguin            = { "Rare",      140,        "Snow" },
  walrus             = { "Epic",      600,        "Snow" },
  polarbear          = { "Legendary", 7000,       "Snow" },
  sabertoothtiger    = { "Mythic",    35000,      "Snow" },
  mammoth            = { "Mythic",    42000,      "Snow" },
  kingmammoth        = { "Cosmic",    400000,     "Snow" },
  yeti               = { "Secret",    5000000,    "Snow" },
  icedragon          = { "Eternal",   65000000,   "Snow" },
  -- Volcano
  lavagecko          = { "Rare",      180,        "Volcano" },
  lavafrog           = { "Epic",      850,        "Volcano" },
  flamingbull        = { "Legendary", 9500,       "Volcano" },
  lavaiguana         = { "Legendary", 11000,      "Volcano" },
  chillinchilli      = { "Mythic",    55000,      "Volcano" },
  cerberus           = { "Secret",    8000000,    "Volcano" },
  phoenix            = { "Eternal",   85000000,   "Volcano" },
  lavadragon         = { "Eternal",   100000000,  "Volcano" },
  -- Abyss Ocean
  parrotfish         = { "Rare",      220,        "Abyss" },
  swordfish          = { "Epic",      1100,       "Abyss" },
  shark              = { "Legendary", 15000,      "Abyss" },
  orca               = { "Mythic",    80000,      "Abyss" },
  whaleshark         = { "Cosmic",    700000,     "Abyss" },
  belugawhale        = { "Cosmic",    850000,     "Abyss" },
  kraken             = { "Secret",    15000000,   "Abyss" },
  elmaja             = { "Eternal",   130000000,  "Abyss" },
  -- Prehistoric
  dodo               = { "Rare",      280,        "Prehistoric" },
  pterodactyl        = { "Legendary", 22000,      "Prehistoric" },
  ankylosaurus       = { "Mythic",    120000,     "Prehistoric" },
  triceratops        = { "Cosmic",    1200000,    "Prehistoric" },
  bronto             = { "Cosmic",    1500000,    "Prehistoric" },
  tralaledon         = { "Secret",    32000000,   "Prehistoric" },
  trex               = { "Secret",    25000000,   "Prehistoric" },
  mosasaurus         = { "Eternal",   180000000,  "Prehistoric" },
  -- Cosmic
  centapede          = { "Epic",      1500,       "Cosmic" },
  cosmicgecko        = { "Legendary", 30000,      "Cosmic" },
  cosmicgorilla      = { "Mythic",    180000,     "Cosmic" },
  lavaccasaturnosaturnita = { "Cosmic", 2200000,  "Cosmic" },
  cosmicdragon       = { "Secret",    60000000,   "Cosmic" },
  cosmicskeletonboss = { "Secret",    45000000,   "Cosmic" },
  eternallunardragon = { "Eternal",   250000000,  "Cosmic" },
  unicorn            = { "Divine",    1000000000, "Cosmic" },
  -- Cherry Blossom
  crane              = { "Epic",      4000,       "Cherry" },
  salamander         = { "Legendary", 74000,      "Cherry" },
  redpanda           = { "Mythic",    450000,     "Cherry" },
  koi                = { "Cosmic",    12000000,   "Cherry" },
  snowyowl           = { "Cosmic",    7500000,    "Cherry" },
  stag               = { "Secret",    145000000,  "Cherry" },
  onitiger           = { "Eternal",   600000000,  "Cherry" },
  kitsune            = { "Divine",    1800000000, "Cherry" },
  -- Titan Temple (Update 2 — Monsters Are Coming, 29-30 Agu 2026)
  crustacia          = { "Legendary", 130000,     "Titan" },
  spideron           = { "Legendary", 95000,      "Titan" },
  bladehide          = { "Mythic",    750000,     "Titan" },
  mantaris           = { "Cosmic",    11000000,   "Titan" },
  rhinotaur          = { "Cosmic",    17500000,   "Titan" },
  mutantshark        = { "Secret",    215000000,  "Titan" },
  gorillaking        = { "Eternal",   880000000,  "Titan" },
  nightflame         = { "Divine",    nil,        "Titan" },   -- belum diindeks
  -- Brainrot (telur Shop terbatas) — income tidak dipublikasikan
  tungtungsahur      = { "Rare",      nil,        "Brainrot" },
  bananitadolphinita = { "Epic",      nil,        "Brainrot" },
  belulabeluga       = { "Mythic",    nil,        "Brainrot" },
  mangoliniparrochini = { "Cosmic",   nil,        "Brainrot" },
  bomboclatcrocolat  = { "Secret",    nil,        "Brainrot" },
  strawberryelephant = { "Eternal",   nil,        "Brainrot" },
  -- Monster Egg (Robux Shop) — IGN mencatat income "Unknown"; dibiarkan nil
  scorpio            = { "Legendary", nil,        "Monster" },
  froggo             = { "Mythic",    nil,        "Monster" },
  crawler            = { "Cosmic",    nil,        "Monster" },
  crocodon           = { "Secret",    nil,        "Monster" },
  krakenoid          = { "Eternal",   nil,        "Monster" },
  dreadscale         = { "Divine",    8000000000, "Monster" },  -- 1 sumber: ~$8B/s
  mechascorpio       = { "Legendary", nil,        "Monster" },
  mechafroggo        = { "Mythic",    nil,        "Monster" },
  mechacrawler       = { "Cosmic",    nil,        "Monster" },
  mechacrocodon      = { "Secret",    nil,        "Monster" },
  mechakrakenoid     = { "Eternal",   nil,        "Monster" },
  mechadreadscale    = { "Divine",    nil,        "Monster" },
}

-- Nama tampilan: default kapitalkan huruf pertama; multi-kata ditulis manual.
local DISPLAY = {}
for k in pairs(DB) do DISPLAY[k] = k:sub(1, 1):upper() .. k:sub(2) end
DISPLAY.brrbrrpatapim = "Brr Brr Patapim"
DISPLAY.trulimerotrulicina = "Trulimero Trulicina"
DISPLAY.tobtobitobtob = "Tob Tobi Tob Tob"
DISPLAY.orangutiniananassini = "Orangutini Ananassini"
DISPLAY.sandspider = "Sand Spider"
DISPLAY.royalsphinx = "Royal Sphinx"
DISPLAY.kingsnake = "King Snake"
DISPLAY.polarbear = "Polar Bear"
DISPLAY.sabertoothtiger = "Sabertooth Tiger"
DISPLAY.kingmammoth = "King Mammoth"
DISPLAY.icedragon = "Ice Dragon"
DISPLAY.lavagecko = "Lava Gecko"
DISPLAY.lavafrog = "Lava Frog"
DISPLAY.flamingbull = "Flaming Bull"
DISPLAY.lavaiguana = "Lava Iguana"
DISPLAY.chillinchilli = "Chillin Chilli"
DISPLAY.lavadragon = "Lava Dragon"
DISPLAY.whaleshark = "Whale Shark"
DISPLAY.belugawhale = "Beluga Whale"
DISPLAY.elmaja = "El Maja"
DISPLAY.trex = "T-Rex"
DISPLAY.cosmicgecko = "Cosmic Gecko"
DISPLAY.cosmicgorilla = "Cosmic Gorilla"
DISPLAY.lavaccasaturnosaturnita = "La Vacca Saturno Saturnita"
DISPLAY.cosmicdragon = "Cosmic Dragon"
DISPLAY.cosmicskeletonboss = "Cosmic Skeleton Boss"
DISPLAY.eternallunardragon = "Eternal Lunar Dragon"
DISPLAY.redpanda = "Red Panda"
DISPLAY.snowyowl = "Snowy Owl"
DISPLAY.onitiger = "Oni Tiger"
DISPLAY.mutantshark = "Mutant Shark"
DISPLAY.gorillaking = "Gorilla King"
DISPLAY.tungtungsahur = "Tung Tung Sahur"
DISPLAY.bananitadolphinita = "Bananita Dolphinita"
DISPLAY.belulabeluga = "Belula Beluga"
DISPLAY.mangoliniparrochini = "Mangolini Parrochini"
DISPLAY.bomboclatcrocolat = "Bomboclat Crocolat"
DISPLAY.strawberryelephant = "Strawberry Elephant"
DISPLAY.mechascorpio = "Mecha Scorpio"
DISPLAY.mechafroggo = "Mecha Froggo"
DISPLAY.mechacrawler = "Mecha Crawler"
DISPLAY.mechacrocodon = "Mecha Crocodon"
DISPLAY.mechakrakenoid = "Mecha Krakenoid"
DISPLAY.mechadreadscale = "Mecha Dreadscale"

-- Kunci diurut dari TERPANJANG. Wajib: "kingmammoth" harus menang atas
-- "mammoth", "mechadreadscale" atas "dreadscale", "sandspider" atas "spider".
local DB_KEYS = {}
for k in pairs(DB) do DB_KEYS[#DB_KEYS + 1] = k end
table.sort(DB_KEYS, function(a, b) return #a > #b end)

local function normalize(s)
  return (tostring(s or ""):lower():gsub("[^%a]", ""))
end

-- pencocokan longgar: nama pet terkandung di dalam teks
local function dbLookup(name)
  local n = normalize(name)
  if n == "" then return nil end
  n = n:gsub("egg", "")
  if DB[n] then return n end
  for _, k in ipairs(DB_KEYS) do
    if #k >= 4 and n:find(k, 1, true) then return k end
  end
  return nil
end

-- pencocokan ketat: nama objek harus PERSIS nama pet setelah kata "egg" dan
-- semua tanda baca dibuang. Dipakai untuk memutuskan "ini telur atau bukan",
-- supaya "BearTrap" tidak dianggap telur Bear.
local function dbExact(name)
  local n = normalize(name):gsub("egg", "")
  if n ~= "" and DB[n] then return n end
  return nil
end

-- pencocokan dengan mengabaikan awalan mutasi: "RainbowKitsuneEgg" -> kitsune
local function dbStripMutation(name)
  local n = normalize(name):gsub("egg", "")
  for _, m in ipairs({ "spiritbloom", "rainbow", "golden", "bloom", "silver" }) do
    n = n:gsub("^" .. m, "")
  end
  if n ~= "" and DB[n] then return n end
  return nil
end

local function money(v)
  if not v then return "?" end
  local a = math.abs(v)
  if a >= 1e9 then return string.format("$%.3gB/s", v / 1e9) end
  if a >= 1e6 then return string.format("$%.3gM/s", v / 1e6) end
  if a >= 1e3 then return string.format("$%.3gK/s", v / 1e3) end
  return string.format("$%d/s", math.floor(v))
end

local function kg(v)
  if not v or v <= 0 then return nil end
  if v >= 1e6 then return string.format("%.3gMkg", v / 1e6) end
  if v >= 1e3 then return string.format("%.3gKkg", v / 1e3) end
  return string.format("%dkg", math.floor(v))
end

-- jumlah entri, dipakai panel info
local DB_COUNT = 0
for _ in pairs(DB) do DB_COUNT = DB_COUNT + 1 end


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
-- Game tidak menempelkan kata "Cosmic"/"Divine" pada telur, jadi versi lama
-- yang hanya membaca teks membuat hampir semua telur nil dan filter menolak
-- semuanya. Urutan pencocokan: nama persis -> nama tanpa awalan mutasi ->
-- nama longgar -> teks di dalam objek -> kata rarity eksplisit.
local function rarityOf(inst)
  local key = dbExact(inst.Name) or dbStripMutation(inst.Name) or dbLookup(inst.Name)
  if key then return DB[key][1], key end

  local blob = textBlob(inst)
  local k2 = dbLookup(blob)
  if k2 then return DB[k2][1], k2 end

  -- cadangan terakhir: kata rarity eksplisit di teks.
  -- "Uncommon" wajib diuji sebelum "Common" (substring!), jadi urut manual.
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
  key = key or dbExact(inst.Name) or dbStripMutation(inst.Name)
    or dbLookup(inst.Name) or dbLookup(textBlob(inst))
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
    if okRar and okWt and okInc and not e.mine and not nearOwnBase(e.pos) then
      local d = dist(h.Position, e.pos)
      if d <= S.maxRange then
        local sc = eggScore(e) - d * 0.08
        if sc > bestScore then bestScore, best = sc, e end
      end
    end
  end
  return best
end


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


-- ============ AMBIL TELUR: banyak cara, dicoba berurutan ============
-- Penyebab "steal ga ke-steal": v3 hanya menembak prompt + touch sekali lalu
-- langsung pergi. Sekarang: dekati sampai benar-benar dekat, tekan prompt di
-- dalam objek telur itu sendiri, sentuh SEMUA part-nya, tembak remote dengan
-- beberapa bentuk argumen, lalu VERIFIKASI apakah telur benar-benar terbawa.

local function promptsInside(obj, radius)
  local h = hrp(); if not h then return 0 end
  local n = 0
  for _, p in ipairs(obj:GetDescendants()) do
    if p:IsA("ProximityPrompt") then
      pcall(function()
        p.Enabled = true
        p.MaxActivationDistance = math.max(p.MaxActivationDistance or 0, 80)
        p.RequiresLineOfSight = false
        p.HoldDuration = 0
        fireproximityprompt(p)
      end)
      n = n + 1
    end
  end
  if obj:IsA("ProximityPrompt") then
    pcall(function() fireproximityprompt(obj) end)
    n = n + 1
  end
  return n
end

local function touchAllParts(obj)
  local h = hrp(); if not h then return 0 end
  local n = 0
  local parts = {}
  if obj:IsA("BasePart") then parts[1] = obj end
  for _, d in ipairs(obj:GetDescendants()) do
    if d:IsA("BasePart") then parts[#parts + 1] = d end
  end
  for _, p in ipairs(parts) do
    pcall(function()
      firetouchinterest(h, p, 0)
      firetouchinterest(h, p, 1)
      firetouchinterest(h, p, 0)
      firetouchinterest(h, p, 1)
      n = n + 1
    end)
  end
  return n
end

-- Apakah telur BENAR-BENAR terbawa? Kedekatan posisi BUKAN bukti — berdiri di
-- sebelah telur tidak berarti memegangnya, dan itulah yang membuat v3 mengaku
-- berhasil lalu pulang dengan tangan kosong. Bukti yang diterima hanya:
--   a) telur menjadi keturunan karakter kita, atau
--   b) telur di-weld ke HumanoidRootPart kita, atau
--   c) telur hilang dari dunia SAAT kita berdiri di sisinya (<16 stud)
-- `nearDist` = jarak kita ke telur pada percobaan terakhir.
local function heldByMe(obj, nearDist)
  local c = char(); if not c then return false end
  local h = hrp()

  if not obj.Parent then
    return (nearDist ~= nil) and (nearDist < 16)
  end

  local p = obj.Parent
  while p do
    if p == c then return true end
    p = p.Parent
  end

  if h then
    for _, d in ipairs(obj:GetDescendants()) do
      if d:IsA("WeldConstraint") or d:IsA("Weld") then
        local ok = false
        pcall(function()
          if d.Part0 == h or d.Part1 == h then ok = true end
        end)
        if ok then return true end
      end
    end
  end
  return false
end

-- satu percobaan ambil penuh
local function grabAttempt(e)
  local acts = 0
  acts = acts + promptsInside(e.obj, 26)
  acts = acts + pressPromptsNear(30)
  acts = acts + touchAllParts(e.obj)
  -- remote dengan beberapa bentuk argumen: game bisa minta objek, nama, atau
  -- tanpa argumen sama sekali
  local words = { "steal", "pickup", "pick", "grab", "take", "collect", "carry", "hold" }
  fireMatch(words, e.obj)
  fireMatch(words, e.obj.Name)
  fireMatch(words)
  return acts
end

-- ============ LOOP: STEAL EGG ============
task.spawn(function()
  while true do
    task.wait(S.stealDelay)
    if S.stealOn and alive() then
      local ok, err = pcall(function()
        local e = pickEgg()
        if not e then
          S.status = "nunggu telur cocok"
          return
        end

        local tag = (e.rar or "?")
        if e.pet then tag = tag .. " " .. e.pet end
        if e.mut then tag = e.mut .. " " .. tag end

        -- 1. dekati sampai benar-benar dekat, bukan cuma "kira-kira sampai"
        S.status = "menuju " .. tag
        moveTo(e.pos, 25, S.stealSpeed)
        if not S.stealOn then S.status = "dibatalkan"; return end

        -- 2. koreksi jarak: kalau masih jauh, dekati lagi sekali
        local h = hrp()
        if h and e.obj.Parent then
          local now = posOf(e.obj) or e.pos
          if dist(h.Position, now) > 12 then
            moveTo(now, 8, S.stealSpeed)
          end
        end

        -- 3. usaha ambil beberapa kali, berhenti begitu terbukti terbawa
        local got = false
        for i = 1, math.max(1, S.grabTries) do
          if not S.stealOn then S.status = "dibatalkan"; return end

          local hh = hrp()
          local ep = posOf(e.obj)
          local dNow = (hh and ep) and dist(hh.Position, ep) or nil

          -- kalau telur sudah hilang sebelum kita sempat menyentuh, itu bukan
          -- keberhasilan kita — kecuali kita memang sedang berdiri di sisinya
          if not e.obj.Parent then
            got = heldByMe(e.obj, dNow)
            break
          end

          grabAttempt(e)
          task.wait(0.35)

          local hh2 = hrp()
          local ep2 = posOf(e.obj)
          local d2 = (hh2 and ep2) and dist(hh2.Position, ep2) or dNow
          if heldByMe(e.obj, d2) then got = true break end

          local cur = posOf(e.obj)
          if cur then moveTo(cur, 4, S.stealSpeed) end
        end

        S.lastGrab = got and ("berhasil: " .. tag) or ("gagal ambil: " .. tag)
        if not got then
          S.fails = S.fails + 1
          S.status = "gagal ambil, cari yang lain"
          return                      -- JANGAN pulang kalau tangan kosong
        end

        -- 4. baru pulang setelah telur benar-benar terbawa
        if S.returnBase then
          local b = myBase()
          if b then
            S.status = "bawa pulang " .. tag
            moveTo(b, 35, S.stealSpeed)
            if not S.stealOn then S.status = "dibatalkan"; return end
            pressPromptsNear(30)
            fireMatch({ "deposit", "deliver", "place", "store", "submit", "drop" }, e.obj)
            fireMatch({ "deposit", "deliver", "place", "store", "submit", "drop" })
            task.wait(0.3)
          end
        end

        S.stolen = S.stolen + 1
        S.lastEgg = tag .. (e.income and (" · " .. (money(e.income * (e.mult or 1)) or "?")) or "")
        S.status = "selesai #" .. S.stolen
      end)
      if not ok then
        S.fails = S.fails + 1
        S.status = "error: " .. tostring(err):sub(1, 44)
      end
    end
  end
end)

-- ============ LOOP: FARM ============
task.spawn(function()
  while true do
    task.wait(2.2)
    if alive() then
      pcall(function()
        if S.autoHatch   then fireMatch({ "hatch", "openegg", "incubat" }) end
        if S.autoClaim   then fireMatch({ "claim", "collectmoney", "collectcash", "collectincome" }) end
        if S.autoTrain   then fireMatch({ "train", "treadmill", "speedtrain" }) end
        if S.autoSell    then fireMatch({ "sellpet", "sell" }) end
        if S.autoUpgrade then fireMatch({ "upgrade", "buyupgrade", "levelup" }) end
      end)
    end
  end
end)

task.spawn(function()
  while true do
    task.wait(6)
    if S.autoTrain and alive() and not S.stealOn then
      pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
          if (v:IsA("BasePart") or v:IsA("Model")) and lower(v.Name):find("treadmill") then
            local p = posOf(v)
            if p and hrp() and dist(hrp().Position, p) > 12 then moveTo(p, 20) end
            pressPromptsNear(24)
            break
          end
        end
      end)
    end
  end
end)

-- ============ PLAYER: speed, anti stun, no fall ============
task.spawn(function()
  while true do
    task.wait(0.25)
    pcall(function()
      local h = hum()
      if not h then return end

      -- jangan ganggu WalkSpeed saat gerak sedang mengatur kecepatan
      if not moving then
        if S.speedOn then
          h.WalkSpeed = math.clamp(S.speed, 8, 1000)
        elseif h.WalkSpeed > 40 then
          h.WalkSpeed = 16
        end
      end

      -- PlatformStand tidak boleh pernah nyangkut true
      if h.PlatformStand and not moving then h.PlatformStand = false end

      if S.antiStun then
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        h.Sit = false
      end
      if S.noFall then
        local hp = hrp()
        if hp and hp.Velocity.Y < -120 then
          hp.Velocity = Vector3.new(hp.Velocity.X, -20, hp.Velocity.Z)
        end
      end
    end)
  end
end)

-- ============ ESP ============
local espF = Instance.new("Folder")
espF.Name = "SAE_ESP"
espF.Parent = CoreGui

local function tagBox(inst, color, lines)
  local hl = Instance.new("Highlight")
  hl.Adornee = inst
  hl.FillColor = color
  hl.OutlineColor = color
  hl.FillTransparency = 0.62
  hl.OutlineTransparency = 0
  hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  hl.Parent = espF

  if lines and #lines > 0 then
    local p = partOf(inst)
    if p then
      local bb = Instance.new("BillboardGui")
      bb.Adornee = p
      bb.Size = UDim2.new(0, 200, 0, 16 * #lines + 6)
      bb.StudsOffset = Vector3.new(0, 2.8, 0)
      bb.AlwaysOnTop = true
      bb.Parent = espF
      local ll = Instance.new("UIListLayout")
      ll.Parent = bb
      for i, ln in ipairs(lines) do
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 0, 16)
        tl.BackgroundTransparency = 1
        tl.Text = ln
        tl.Font = (i == 1) and Enum.Font.GothamBold or Enum.Font.Code
        tl.TextSize = (i == 1) and 13 or 11
        tl.TextColor3 = (i == 1) and color or Color3.fromRGB(225, 232, 242)
        tl.TextStrokeTransparency = 0.25
        tl.Parent = bb
      end
    end
  end
end

task.spawn(function()
  while true do
    task.wait(2)
    pcall(function()
      espF:ClearAllChildren()
      local h = hrp(); if not h then return end

      if S.espEgg then
        for _, e in ipairs(scanEggs()) do
          local d = dist(h.Position, e.pos)
          if d <= S.espRange then
            local idx = 0
            if e.rar then
              for i, r in ipairs(RARITY) do if r == e.rar then idx = i break end end
            end
            local show
            if idx == 0 then show = S.espUnknown else show = (idx >= S.espMinRarity) end
            if show then
              local col = (e.rar and RCOLOR[e.rar]) or Color3.fromRGB(190, 195, 205)

              -- baris 1: mutasi + rarity + nama pet
              local head
              if e.pet then
                head = (e.rar or "?") .. " · " .. e.pet
              elseif e.rar then
                head = e.rar
              else
                -- pakai nama objek apa adanya, jangan menulis "belum diketahui"
                head = tostring(e.obj.Name):gsub("_", " ")
              end
              if e.mut then head = e.mut .. " " .. head end

              -- baris 2: income
              local l2
              if e.income then
                local base = money(e.income)
                if e.mut and (e.mult or 1) > 1 then
                  l2 = (money(e.income * e.mult) or "?") .. "  (" .. base .. " ×" .. e.mult .. ")"
                else
                  l2 = base
                end
              elseif e.rar then
                l2 = e.rar .. " · income tak dipublikasikan"
              else
                l2 = "pet belum ada di database"
              end

              -- baris 3: biome, berat, jarak
              local bits = {}
              if e.biome then bits[#bits + 1] = e.biome end
              local w = kg(e.wt)
              if w then bits[#bits + 1] = w end
              bits[#bits + 1] = math.floor(d) .. "m"
              if e.mine then bits[#bits + 1] = "MILIKKU" end

              tagBox(e.obj, col, { head, l2, table.concat(bits, " · ") })
            end
          end
        end
      end

      if S.espTrap then
        for _, t in ipairs(scanTraps()) do
          local d = dist(h.Position, t.pos)
          if d < 900 then tagBox(t.obj, Color3.fromRGB(255, 90, 90), { "TRAP", math.floor(d) .. "m" }) end
        end
      end
      if S.espGuard then
        for _, m in ipairs(scanHostiles()) do
          local d = dist(h.Position, m.pos)
          if d < 1200 then
            tagBox(m.obj, Color3.fromRGB(255, 160, 60), { string.upper(m.kind), math.floor(d) .. "m" })
          end
        end
      end
      if S.espPlayer then
        for _, pl in ipairs(Players:GetPlayers()) do
          if pl ~= LP and pl.Character then
            local pp = pl.Character:FindFirstChild("HumanoidRootPart")
            if pp then
              tagBox(pl.Character, Color3.fromRGB(90, 200, 255),
                { pl.Name, math.floor(dist(h.Position, pp.Position)) .. "m" })
            end
          end
        end
      end
    end)
  end
end)


-- ============ LOOP PENGAMAT SIKLUS ============
-- Belajar periode reset dari perubahan nyata isi map, bukan dari angka hafalan.
task.spawn(function()
  -- ambil sidik jari awal supaya reset pertama tidak dihitung palsu
  local ok0 = pcall(function() PRED.sig = (eggSignature()) end)
  if not ok0 then PRED.sig = nil end

  while true do
    task.wait(1)
    if PRED.watch then
      pcall(function()
        PRED.liveTimer = findLiveTimer()

        local sig, eggs = eggSignature()

        -- reset terdeteksi kalau isi map berubah drastis (mirip < 35%)
        if PRED.sig and sig ~= PRED.sig then
          local sim = similarity(PRED.sig, sig)
          if sim < 0.35 and #eggs > 0 then
            local now = tick()
            -- tolak deteksi ganda dalam 20 detik (gemerlap render, bukan reset)
            if not PRED.lastReset or (now - PRED.lastReset) > 20 then
              PRED.lastReset = now
              table.insert(PRED.resetTimes, now)
              while #PRED.resetTimes > 40 do table.remove(PRED.resetTimes, 1) end
              PRED.period = computePeriod()
              PRED.observed = PRED.observed + 1

              -- catat rarity apa saja yang muncul di reset ini
              local seen = {}
              for _, e in ipairs(eggs) do
                if e.rar and not seen[e.rar] then
                  seen[e.rar] = true
                  PRED.counts[e.rar] = (PRED.counts[e.rar] or 0) + 1
                  PRED.seenNames[e.rar] = e.obj.Name
                end
              end

              -- alarm untuk rarity yang dipantau
              for _, e in ipairs(eggs) do
                if e.rar and PRED.notify[e.rar] then
                  pushAlert(e, "reset")
                end
              end
            end
          end
        end
        PRED.sig = sig

        -- deteksi instan: telur langka muncul di luar siklus reset
        for _, e in ipairs(eggs) do
          if e.rar and PRED.notify[e.rar] then
            local fresh = true
            for _, a in ipairs(PRED.alerts) do
              if a.name == e.obj.Name and (tick() - a.t) < 60 then fresh = false break end
            end
            if fresh then pushAlert(e, "muncul") end
          end
        end
      end)
    end
  end
end)

-- auto kejar telur langka begitu terdeteksi
task.spawn(function()
  while true do
    task.wait(1.5)
    if PRED.watch and PRED.autoGo and alive() and not S.stealOn then
      pcall(function()
        local target = nil
        for _, e in ipairs(scanEggs()) do
          if e.rar and PRED.notify[e.rar] then
            if not target or eggScore(e) > eggScore(target) then target = e end
          end
        end
        if target then
          S.status = "kejar " .. target.rar .. (target.mut and (" " .. target.mut) or "")
          glideTo(target.pos, 25)
          pressPromptsNear(26)
          local p = partOf(target.obj)
          if p then touchPart(p) end
          fireMatch({ "steal", "pickup", "grabegg", "takeegg", "collectegg" }, target.obj)
          task.wait(0.5)
          local b = myBase()
          if b and S.returnBase then
            glideTo(b, 30)
            pressPromptsNear(26)
            fireMatch({ "deposit", "deliver", "placeegg", "storeegg", "submit" }, target.obj)
          end
        end
      end)
    end
  end
end)


-- ============ UI: tema & helper ============
local T = {
  bg      = Color3.fromRGB(13, 15, 21),
  panel   = Color3.fromRGB(19, 22, 30),
  panel2  = Color3.fromRGB(25, 29, 39),
  line    = Color3.fromRGB(38, 44, 58),
  txt     = Color3.fromRGB(232, 238, 247),
  txt2    = Color3.fromRGB(146, 160, 182),
  gold    = Color3.fromRGB(232, 163, 61),
  jade    = Color3.fromRGB(62, 207, 154),
  red     = Color3.fromRGB(217, 117, 95),
}

local function corner(o, r)
  local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c
end
local function stroke(o, col, th)
  local s = Instance.new("UIStroke")
  s.Color = col or T.line; s.Thickness = th or 1
  s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s
end
local function pad(o, v)
  local p = Instance.new("UIPadding")
  p.PaddingTop = UDim.new(0, v); p.PaddingBottom = UDim.new(0, v)
  p.PaddingLeft = UDim.new(0, v); p.PaddingRight = UDim.new(0, v)
  p.Parent = o; return p
end
local function label(parent, text, size, color, bold)
  local l = Instance.new("TextLabel")
  l.BackgroundTransparency = 1
  l.Size = UDim2.new(1, 0, 0, size + 8)
  l.Text = text
  l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
  l.TextSize = size
  l.TextColor3 = color or T.txt
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.Parent = parent
  return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "SAE_Hub_v2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- tombol bulat pembuka (kalau hub disembunyikan)
local orb = Instance.new("TextButton")
orb.Size = UDim2.new(0, 52, 0, 52)
orb.Position = UDim2.new(0, 14, 0.42, 0)
orb.BackgroundColor3 = T.gold
orb.Text = "EGG"
orb.Font = Enum.Font.GothamBlack
orb.TextSize = 13
orb.TextColor3 = Color3.fromRGB(20, 14, 4)
orb.Visible = false
orb.Active = true
orb.Draggable = true
orb.Parent = gui
corner(orb, 26)

-- jendela utama
local win = Instance.new("Frame")
win.Size = UDim2.new(0, 330, 0, 412)
win.Position = UDim2.new(0, 18, 0.5, -206)
win.BackgroundColor3 = T.bg
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = gui
corner(win, 14)
stroke(win, T.line, 1)

-- header
local head = Instance.new("Frame")
head.Size = UDim2.new(1, 0, 0, 46)
head.BackgroundTransparency = 1
head.Parent = win

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 16, 0, 19)
dot.BackgroundColor3 = T.jade
dot.BorderSizePixel = 0
dot.Parent = head
corner(dot, 4)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1, -110, 1, 0)
ttl.Position = UDim2.new(0, 32, 0, 0)
ttl.BackgroundTransparency = 1
ttl.Text = "STEAL AN EGG"
ttl.Font = Enum.Font.GothamBlack
ttl.TextSize = 14
ttl.TextColor3 = T.txt
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.Parent = head

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(0, 40, 1, 0)
ver.Position = UDim2.new(1, -86, 0, 0)
ver.BackgroundTransparency = 1
ver.Text = "v2"
ver.Font = Enum.Font.Code
ver.TextSize = 11
ver.TextColor3 = T.txt2
ver.Parent = head

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 34, 0, 34)
hideBtn.Position = UDim2.new(1, -44, 0, 6)
hideBtn.BackgroundColor3 = T.panel2
hideBtn.Text = "—"
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 16
hideBtn.TextColor3 = T.txt2
hideBtn.Parent = head
corner(hideBtn, 9)

-- tab bar
local tabbar = Instance.new("Frame")
tabbar.Size = UDim2.new(1, -24, 0, 38)
tabbar.Position = UDim2.new(0, 12, 0, 44)
tabbar.BackgroundColor3 = T.panel
tabbar.BorderSizePixel = 0
tabbar.Parent = win
corner(tabbar, 10)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabbar
pad(tabbar, 4)

-- area konten
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -132)
content.Position = UDim2.new(0, 12, 0, 90)
content.BackgroundTransparency = 1
content.Parent = win

-- status bar bawah
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 34)
statusBar.Position = UDim2.new(0, 12, 1, -40)
statusBar.BackgroundColor3 = T.panel
statusBar.BorderSizePixel = 0
statusBar.Parent = win
corner(statusBar, 9)

local statusTxt = Instance.new("TextLabel")
statusTxt.Size = UDim2.new(1, -16, 1, 0)
statusTxt.Position = UDim2.new(0, 10, 0, 0)
statusTxt.BackgroundTransparency = 1
statusTxt.Text = "siap"
statusTxt.Font = Enum.Font.Code
statusTxt.TextSize = 11
statusTxt.TextColor3 = T.txt2
statusTxt.TextXAlignment = Enum.TextXAlignment.Left
statusTxt.TextTruncate = Enum.TextTruncate.AtEnd
statusTxt.Parent = statusBar

hideBtn.MouseButton1Click:Connect(function()
  win.Visible = false; orb.Visible = true
end)
orb.MouseButton1Click:Connect(function()
  win.Visible = true; orb.Visible = false
end)


-- ============ UI: komponen ============
local pages, tabs = {}, {}
local activePage = nil

local function makePage(name)
  local sc = Instance.new("ScrollingFrame")
  sc.Size = UDim2.new(1, 0, 1, 0)
  sc.BackgroundTransparency = 1
  sc.BorderSizePixel = 0
  sc.ScrollBarThickness = 3
  sc.ScrollBarImageColor3 = T.line
  sc.CanvasSize = UDim2.new(0, 0, 0, 0)
  sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
  sc.Visible = false
  sc.Parent = content

  local ll = Instance.new("UIListLayout")
  ll.Padding = UDim.new(0, 7)
  ll.SortOrder = Enum.SortOrder.LayoutOrder
  ll.Parent = sc

  local pd = Instance.new("UIPadding")
  pd.PaddingRight = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 10)
  pd.Parent = sc

  pages[name] = sc
  return sc
end

local function showPage(name)
  for n, p in pairs(pages) do p.Visible = (n == name) end
  for n, b in pairs(tabs) do
    local on = (n == name)
    b.BackgroundColor3 = on and T.panel2 or T.panel
    b.TextColor3 = on and T.gold or T.txt2
  end
  activePage = name
end

local function makeTab(name, w)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0, w, 1, 0)
  b.BackgroundColor3 = T.panel
  b.Text = name
  b.Font = Enum.Font.GothamBold
  b.TextSize = 12
  b.TextColor3 = T.txt2
  b.AutoButtonColor = false
  b.Parent = tabbar
  corner(b, 8)
  tabs[name] = b
  b.MouseButton1Click:Connect(function() showPage(name) end)
  return b
end

-- baris toggle
local function toggle(page, text, sub, get, set)
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0, sub and 50 or 42)
  row.BackgroundColor3 = T.panel
  row.BorderSizePixel = 0
  row.Parent = page
  corner(row, 9)

  local t = Instance.new("TextLabel")
  t.Size = UDim2.new(1, -70, 0, sub and 20 or 42)
  t.Position = UDim2.new(0, 12, 0, sub and 7 or 0)
  t.BackgroundTransparency = 1
  t.Text = text
  t.Font = Enum.Font.GothamMedium
  t.TextSize = 13
  t.TextColor3 = T.txt
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.Parent = row

  if sub then
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, -70, 0, 16)
    s.Position = UDim2.new(0, 12, 0, 26)
    s.BackgroundTransparency = 1
    s.Text = sub
    s.Font = Enum.Font.Gotham
    s.TextSize = 10
    s.TextColor3 = T.txt2
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Parent = row
  end

  local sw = Instance.new("TextButton")
  sw.Size = UDim2.new(0, 44, 0, 24)
  sw.Position = UDim2.new(1, -56, 0.5, -12)
  sw.BackgroundColor3 = T.panel2
  sw.Text = ""
  sw.AutoButtonColor = false
  sw.Parent = row
  corner(sw, 12)

  local knob = Instance.new("Frame")
  knob.Size = UDim2.new(0, 18, 0, 18)
  knob.Position = UDim2.new(0, 3, 0.5, -9)
  knob.BackgroundColor3 = T.txt2
  knob.BorderSizePixel = 0
  knob.Parent = sw
  corner(knob, 9)

  local function paint()
    local on = get()
    TweenService:Create(sw, TweenInfo.new(0.16), {
      BackgroundColor3 = on and T.jade or T.panel2 }):Play()
    TweenService:Create(knob, TweenInfo.new(0.16), {
      Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
      BackgroundColor3 = on and Color3.fromRGB(6, 24, 16) or T.txt2 }):Play()
  end
  sw.MouseButton1Click:Connect(function() set(not get()); paint() end)
  paint()
  return row
end

-- slider
local function slider(page, text, min, max, get, set, fmt)
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0, 58)
  row.BackgroundColor3 = T.panel
  row.BorderSizePixel = 0
  row.Parent = page
  corner(row, 9)

  local t = Instance.new("TextLabel")
  t.Size = UDim2.new(1, -24, 0, 20)
  t.Position = UDim2.new(0, 12, 0, 8)
  t.BackgroundTransparency = 1
  t.Text = text
  t.Font = Enum.Font.GothamMedium
  t.TextSize = 12
  t.TextColor3 = T.txt
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.Parent = row

  local val = Instance.new("TextLabel")
  val.Size = UDim2.new(0, 90, 0, 20)
  val.Position = UDim2.new(1, -102, 0, 8)
  val.BackgroundTransparency = 1
  val.Text = ""
  val.Font = Enum.Font.Code
  val.TextSize = 12
  val.TextColor3 = T.gold
  val.TextXAlignment = Enum.TextXAlignment.Right
  val.Parent = row

  local track = Instance.new("Frame")
  track.Size = UDim2.new(1, -24, 0, 8)
  track.Position = UDim2.new(0, 12, 0, 38)
  track.BackgroundColor3 = T.panel2
  track.BorderSizePixel = 0
  track.Parent = row
  corner(track, 4)

  local fill = Instance.new("Frame")
  fill.Size = UDim2.new(0, 0, 1, 0)
  fill.BackgroundColor3 = T.gold
  fill.BorderSizePixel = 0
  fill.Parent = track
  corner(fill, 4)

  local grab = Instance.new("TextButton")
  grab.Size = UDim2.new(1, 0, 0, 30)
  grab.Position = UDim2.new(0, 0, 0, -11)
  grab.BackgroundTransparency = 1
  grab.Text = ""
  grab.Parent = track

  local function paint()
    local v = get()
    local a = (v - min) / (max - min)
    fill.Size = UDim2.new(math.clamp(a, 0, 1), 0, 1, 0)
    val.Text = fmt and fmt(v) or tostring(math.floor(v))
  end

  local dragging = false
  local function setFromX(x)
    local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
    set(math.floor(min + a * (max - min)))
    paint()
  end
  grab.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      dragging = true; setFromX(i.Position.X)
    end
  end)
  grab.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      dragging = false
    end
  end)
  game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
      setFromX(i.Position.X)
    end
  end)
  paint()
  return row
end

-- judul seksi
local function section(page, text)
  local l = Instance.new("TextLabel")
  l.Size = UDim2.new(1, 0, 0, 24)
  l.BackgroundTransparency = 1
  l.Text = string.upper(text)
  l.Font = Enum.Font.GothamBold
  l.TextSize = 10
  l.TextColor3 = T.txt2
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.Parent = page
  return l
end

-- tombol aksi
local function action(page, text, fn, tone)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1, 0, 0, 40)
  b.BackgroundColor3 = tone == "gold" and T.gold or T.panel2
  b.Text = text
  b.Font = Enum.Font.GothamBold
  b.TextSize = 12
  b.TextColor3 = tone == "gold" and Color3.fromRGB(20, 14, 4) or T.txt
  b.AutoButtonColor = false
  b.Parent = page
  corner(b, 9)
  b.MouseButton1Click:Connect(function() pcall(fn) end)
  return b
end


-- ============ TAB: STEAL / FARM / PLAYER / ESP ============
makeTab("STEAL", 70)
makeTab("FARM", 62)
makeTab("PLAYER", 74)
makeTab("ESP", 56)

local pSteal  = makePage("STEAL")
local pFarm   = makePage("FARM")
local pPlayer = makePage("PLAYER")
local pEsp    = makePage("ESP")

-- --- STEAL ---
toggle(pSteal, "Auto Steal Egg", "terbang datar, ambil, baru pulang",
  function() return S.stealOn end,
  function(v) S.stealOn = v; if not v then stopGlide() end end)

toggle(pSteal, "Bawa pulang ke base", "matikan kalau mau kumpul dulu",
  function() return S.returnBase end, function(v) S.returnBase = v end)

toggle(pSteal, "Ambil telur tak dikenal", "telur di luar database tetap diambil",
  function() return S.takeUnknown end, function(v) S.takeUnknown = v end)

toggle(pSteal, "Prioritas telur mutasi", "Spirit Bloom 3x > Rainbow 2.5x > Golden 2x",
  function() return S.preferMutasi end, function(v) S.preferMutasi = v end)

section(pSteal, "kecepatan steal")
slider(pSteal, "Kecepatan saat steal", 16, 1000,
  function() return S.stealSpeed end, function(v) S.stealSpeed = v end,
  function(v) return v .. " stud" end)
slider(pSteal, "Jeda antar steal", 0, 30,
  function() return math.floor(S.stealDelay * 10) end,
  function(v) S.stealDelay = v / 10 end,
  function(v) return string.format("%.1f s", v / 10) end)
slider(pSteal, "Jarak maksimum telur", 100, 5000,
  function() return S.maxRange end, function(v) S.maxRange = v end,
  function(v) return v .. " stud" end)
slider(pSteal, "Usaha ambil per telur", 1, 8,
  function() return S.grabTries end, function(v) S.grabTries = v end,
  function(v) return v .. "x" end)
slider(pSteal, "Radius abaikan base", 0, 200,
  function() return S.baseGuard end, function(v) S.baseGuard = v end,
  function(v) return v <= 0 and "mati" or (v .. " stud") end)

section(pSteal, "pilih rarity")

local rgrid = Instance.new("Frame")
rgrid.Size = UDim2.new(1, 0, 0, 0)
rgrid.AutomaticSize = Enum.AutomaticSize.Y
rgrid.BackgroundTransparency = 1
rgrid.Parent = pSteal

local gl = Instance.new("UIGridLayout")
gl.CellSize = UDim2.new(0.5, -4, 0, 36)
gl.CellPadding = UDim2.new(0, 7, 0, 7)
gl.Parent = rgrid

local rarityBtns = {}
for _, r in ipairs(RARITY) do
  local b = Instance.new("TextButton")
  b.BackgroundColor3 = T.panel
  b.Text = r
  b.Font = Enum.Font.GothamBold
  b.TextSize = 11
  b.AutoButtonColor = false
  b.Parent = rgrid
  corner(b, 8)
  local st = stroke(b, T.line, 1)

  local function paint()
    local on = S.rarityPick[r]
    b.BackgroundColor3 = on and T.panel2 or T.panel
    b.TextColor3 = on and RCOLOR[r] or T.txt2
    st.Color = on and RCOLOR[r] or T.line
    st.Thickness = on and 1.6 or 1
  end
  b.MouseButton1Click:Connect(function()
    S.rarityPick[r] = not S.rarityPick[r]; paint()
  end)
  paint()
  rarityBtns[r] = paint
end

local rowQuick = Instance.new("Frame")
rowQuick.Size = UDim2.new(1, 0, 0, 34)
rowQuick.BackgroundTransparency = 1
rowQuick.Parent = pSteal
local qll = Instance.new("UIListLayout")
qll.FillDirection = Enum.FillDirection.Horizontal
qll.Padding = UDim.new(0, 6)
qll.Parent = rowQuick

local function quick(text, fn)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0.25, -5, 1, 0)
  b.BackgroundColor3 = T.panel2
  b.Text = text
  b.Font = Enum.Font.GothamBold
  b.TextSize = 10
  b.TextColor3 = T.txt
  b.AutoButtonColor = false
  b.Parent = rowQuick
  corner(b, 8)
  b.MouseButton1Click:Connect(function()
    fn()
    for _, paint in pairs(rarityBtns) do paint() end
  end)
end
quick("Semua", function() for _, r in ipairs(RARITY) do S.rarityPick[r] = true end end)
quick("Kosong", function() for _, r in ipairs(RARITY) do S.rarityPick[r] = false end end)
quick("Top 3", function()
  for _, r in ipairs(RARITY) do S.rarityPick[r] = false end
  S.rarityPick.Secret = true; S.rarityPick.Eternal = true; S.rarityPick.Divine = true
end)
quick("Cosmic+", function()
  for _, r in ipairs(RARITY) do S.rarityPick[r] = false end
  S.rarityPick.Cosmic = true; S.rarityPick.Secret = true
  S.rarityPick.Eternal = true; S.rarityPick.Divine = true
end)

section(pSteal, "filter nilai")
slider(pSteal, "Income minimum", 0, 100,
  function()
    -- slider 0..100 dipetakan ke skala log $0 .. $1B
    if S.minIncome <= 0 then return 0 end
    return math.floor(math.log(S.minIncome) / math.log(10) * 100 / 9)
  end,
  function(v)
    if v <= 0 then S.minIncome = 0
    else S.minIncome = math.floor(10 ^ (v * 9 / 100)) end
  end,
  function(v)
    if v <= 0 then return "abaikan" end
    return money(math.floor(10 ^ (v * 9 / 100)))
  end)
slider(pSteal, "Berat minimum", 0, 5000000,
  function() return S.minWeight end, function(v) S.minWeight = v end,
  function(v) return v <= 0 and "abaikan" or (kg(v) or tostring(v)) end)

-- --- FARM ---
section(pFarm, "otomatis")
toggle(pFarm, "Auto Hatch", "tetaskan telur begitu siap",
  function() return S.autoHatch end, function(v) S.autoHatch = v end)
toggle(pFarm, "Auto Claim uang", "ambil income pet",
  function() return S.autoClaim end, function(v) S.autoClaim = v end)
toggle(pFarm, "Auto Treadmill", "latih Speed saat idle",
  function() return S.autoTrain end, function(v) S.autoTrain = v end)
toggle(pFarm, "Auto Upgrade", "beli upgrade base bila mampu",
  function() return S.autoUpgrade end, function(v) S.autoUpgrade = v end)
toggle(pFarm, "Auto Sell pet", "jual pet duplikat",
  function() return S.autoSell end, function(v) S.autoSell = v end)

section(pFarm, "manual")
action(pFarm, "Hatch sekarang", function() fireMatch({ "hatch", "openegg", "incubat" }) end)
action(pFarm, "Claim semua uang", function() fireMatch({ "claim", "collectcash", "collectincome" }) end)
action(pFarm, "Tekan prompt terdekat", function() pressPromptsNear(30) end)

-- --- PLAYER ---
section(pPlayer, "gerak")
toggle(pPlayer, "Mode jalan kaki", "matikan = terbang datar (lebih cepat)",
  function() return S.walkMode end,
  function(v) S.walkMode = v; stopGlide() end)
toggle(pPlayer, "Speed custom", "kecepatan gerak umum",
  function() return S.speedOn end, function(v) S.speedOn = v end)
slider(pPlayer, "Kecepatan", 16, 1000,
  function() return S.speed end, function(v) S.speed = v end,
  function(v) return v .. " stud" end)

section(pPlayer, "keamanan")
toggle(pPlayer, "Anti Trap", "geser jalur menjauh dari trap",
  function() return S.antiTrap end, function(v) S.antiTrap = v end)
toggle(pPlayer, "Anti Bat / Guard", "geser jalur menjauh dari musuh",
  function() return S.antiBat end, function(v) S.antiBat = v end)
toggle(pPlayer, "Anti Stun / Ragdoll", "tolak state jatuh & duduk",
  function() return S.antiStun end, function(v) S.antiStun = v end)
toggle(pPlayer, "No Fall Damage", "redam kecepatan jatuh",
  function() return S.noFall end, function(v) S.noFall = v end)
slider(pPlayer, "Radius hindar", 10, 80,
  function() return S.avoidRadius end, function(v) S.avoidRadius = v end,
  function(v) return v .. " stud" end)

section(pPlayer, "darurat")
action(pPlayer, "STOP semua", function()
  S.stealOn = false; S.autoHatch = false; S.autoClaim = false
  S.autoTrain = false; S.autoSell = false; S.autoUpgrade = false
  stopGlide()
  local h = hum(); if h then h.WalkSpeed = 16; h.PlatformStand = false end
  S.status = "semua dimatikan"
end, "gold")
action(pPlayer, "Perbaiki karakter", function()
  -- lepas semua sisa gaya + PlatformStand: obat kalau karakter terhuyung
  stopGlide()
  local h = hum()
  if h then
    h.PlatformStand = false
    h.Sit = false
    h:ChangeState(Enum.HumanoidStateType.GettingUp)
    h.WalkSpeed = S.speedOn and S.speed or 16
  end
  S.status = "karakter dibereskan"
end)
action(pPlayer, "Reset karakter", function()
  local h = hum(); if h then h.Health = 0 end
end)

-- --- ESP ---
section(pEsp, "tampilkan")
toggle(pEsp, "ESP Telur", "rarity + nama pet + income $/s",
  function() return S.espEgg end, function(v) S.espEgg = v end)
toggle(pEsp, "ESP Trap", "tandai semua trap merah",
  function() return S.espTrap end, function(v) S.espTrap = v end)
toggle(pEsp, "ESP Bat / Guard", "musuh penjaga nest",
  function() return S.espGuard end, function(v) S.espGuard = v end)
toggle(pEsp, "ESP Pemain", "nama + jarak pemain lain",
  function() return S.espPlayer end, function(v) S.espPlayer = v end)

section(pEsp, "saringan tampilan")
toggle(pEsp, "Tampilkan telur tak dikenal", "pet di luar database tetap ditandai",
  function() return S.espUnknown end, function(v) S.espUnknown = v end)
slider(pEsp, "Rarity minimum", 1, 10,
  function() return S.espMinRarity end, function(v) S.espMinRarity = v end,
  function(v) return RARITY[math.clamp(v, 1, 10)] or "?" end)
slider(pEsp, "Jarak ESP", 200, 5000,
  function() return S.espRange end, function(v) S.espRange = v end,
  function(v) return v .. " stud" end)

section(pEsp, "isi map sekarang")
local infoBox = Instance.new("Frame")
infoBox.Size = UDim2.new(1, 0, 0, 138)
infoBox.BackgroundColor3 = T.panel
infoBox.BorderSizePixel = 0
infoBox.Parent = pEsp
corner(infoBox, 9)
local infoTxt = Instance.new("TextLabel")
infoTxt.Size = UDim2.new(1, -20, 1, -16)
infoTxt.Position = UDim2.new(0, 10, 0, 8)
infoTxt.BackgroundTransparency = 1
infoTxt.Text = "memindai..."
infoTxt.Font = Enum.Font.Code
infoTxt.TextSize = 11
infoTxt.TextColor3 = T.txt2
infoTxt.TextXAlignment = Enum.TextXAlignment.Left
infoTxt.TextYAlignment = Enum.TextYAlignment.Top
infoTxt.Parent = infoBox

action(pEsp, "Scan ulang remote", function()
  local n = indexRemotes()
  S.status = "remote terindeks: " .. n
end)

showPage("STEAL")

-- ============ STATUS TICKER ============
task.spawn(function()
  while true do
    task.wait(1)
    pcall(function()
      dot.BackgroundColor3 = S.stealOn and T.jade or T.txt2
      statusTxt.Text = string.format("%s · ok:%d gagal:%d · %s",
        S.status, S.stolen, S.fails, S.lastGrab)
    end)
  end
end)

task.spawn(function()
  while true do
    task.wait(2.5)
    pcall(function()
      if activePage ~= "ESP" then return end
      local eggs = scanEggs()
      local byR, known, best, mine = {}, 0, nil, 0
      for _, e in ipairs(eggs) do
        local k = e.rar or "?"
        byR[k] = (byR[k] or 0) + 1
        if e.mine then mine = mine + 1 end
        if e.income then
          known = known + 1
          local val = e.income * (e.mult or 1)
          if not best or val > (best.income * (best.mult or 1)) then best = e end
        end
      end
      local parts = {}
      for _, r in ipairs(RARITY) do
        if byR[r] then parts[#parts + 1] = r:sub(1, 3) .. ":" .. byR[r] end
      end
      if byR["?"] then parts[#parts + 1] = "??:" .. byR["?"] end

      local bestLine = "-"
      if best then
        bestLine = (best.mut and (best.mut .. " ") or "") .. (best.pet or "?")
          .. " " .. (money(best.income * (best.mult or 1)) or "?")
      end

      infoTxt.Text = table.concat({
        "telur     : " .. #eggs .. "  (income diketahui: " .. known .. ")",
        "milikku   : " .. mine .. "  (diabaikan saat steal)",
        "rincian   : " .. (#parts > 0 and table.concat(parts, " ") or "-"),
        "termahal  : " .. bestLine,
        "trap/musuh: " .. #scanTraps() .. " / " .. #scanHostiles(),
        "remote    : " .. #remotes .. "  · database: " .. DB_COUNT .. " pet",
      }, "\n")
    end)
  end
end)

print("[SAE v4] loaded · remote=" .. #remotes .. " · db=" .. DB_COUNT)


-- ============ TAB PREDIKSI ============
makeTab("PREDIKSI", 92)
local pPred = makePage("PREDIKSI")

-- panel peringatan jujur di paling atas
local warnBox = Instance.new("Frame")
warnBox.Size = UDim2.new(1, 0, 0, 58)
warnBox.BackgroundColor3 = Color3.fromRGB(38, 30, 18)
warnBox.BorderSizePixel = 0
warnBox.Parent = pPred
corner(warnBox, 9)
stroke(warnBox, Color3.fromRGB(90, 70, 30), 1)

local warnTxt = Instance.new("TextLabel")
warnTxt.Size = UDim2.new(1, -20, 1, -12)
warnTxt.Position = UDim2.new(0, 10, 0, 6)
warnTxt.BackgroundTransparency = 1
warnTxt.Text = "Spawn Secret/Eternal/Divine itu undian acak tiap reset — tidak ada jadwal jam pasti. Yang di bawah diukur dari server ini, bukan dikarang."
warnTxt.Font = Enum.Font.Gotham
warnTxt.TextSize = 10
warnTxt.TextColor3 = Color3.fromRGB(235, 200, 130)
warnTxt.TextWrapped = true
warnTxt.TextXAlignment = Enum.TextXAlignment.Left
warnTxt.TextYAlignment = Enum.TextYAlignment.Top
warnTxt.Parent = warnBox

section(pPred, "pengamat siklus")
toggle(pPred, "Pantau siklus telur", "ukur periode reset dari map",
  function() return PRED.watch end, function(v) PRED.watch = v end)
toggle(pPred, "Auto kejar telur langka", "otomatis ambil begitu muncul",
  function() return PRED.autoGo end, function(v) PRED.autoGo = v end)

section(pPred, "rarity yang dipantau")
local pgrid = Instance.new("Frame")
pgrid.Size = UDim2.new(1, 0, 0, 0)
pgrid.AutomaticSize = Enum.AutomaticSize.Y
pgrid.BackgroundTransparency = 1
pgrid.Parent = pPred
local pgl = Instance.new("UIGridLayout")
pgl.CellSize = UDim2.new(0.5, -4, 0, 34)
pgl.CellPadding = UDim2.new(0, 7, 0, 7)
pgl.Parent = pgrid

local WATCHABLE = { "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
for _, r in ipairs(WATCHABLE) do
  local b = Instance.new("TextButton")
  b.BackgroundColor3 = T.panel
  b.Text = r
  b.Font = Enum.Font.GothamBold
  b.TextSize = 11
  b.AutoButtonColor = false
  b.Parent = pgrid
  corner(b, 8)
  local st = stroke(b, T.line, 1)
  local function paint()
    local on = PRED.notify[r] == true
    b.BackgroundColor3 = on and T.panel2 or T.panel
    b.TextColor3 = on and (RCOLOR[r] or T.txt) or T.txt2
    st.Color = on and (RCOLOR[r] or T.line) or T.line
    st.Thickness = on and 1.6 or 1
  end
  b.MouseButton1Click:Connect(function()
    PRED.notify[r] = not PRED.notify[r]; paint()
  end)
  paint()
end

section(pPred, "hitung mundur reset")
local cdBox = Instance.new("Frame")
cdBox.Size = UDim2.new(1, 0, 0, 76)
cdBox.BackgroundColor3 = T.panel
cdBox.BorderSizePixel = 0
cdBox.Parent = pPred
corner(cdBox, 9)

local cdBig = Instance.new("TextLabel")
cdBig.Size = UDim2.new(1, -20, 0, 40)
cdBig.Position = UDim2.new(0, 10, 0, 8)
cdBig.BackgroundTransparency = 1
cdBig.Text = "--"
cdBig.Font = Enum.Font.GothamBlack
cdBig.TextSize = 30
cdBig.TextColor3 = T.gold
cdBig.TextXAlignment = Enum.TextXAlignment.Left
cdBig.Parent = cdBox

local cdSub = Instance.new("TextLabel")
cdSub.Size = UDim2.new(1, -20, 0, 20)
cdSub.Position = UDim2.new(0, 10, 0, 50)
cdSub.BackgroundTransparency = 1
cdSub.Text = "nyalakan pantau siklus dulu"
cdSub.Font = Enum.Font.Code
cdSub.TextSize = 10
cdSub.TextColor3 = T.txt2
cdSub.TextXAlignment = Enum.TextXAlignment.Left
cdSub.Parent = cdBox

section(pPred, "peluang terukur")
local oddsBox = Instance.new("Frame")
oddsBox.Size = UDim2.new(1, 0, 0, 118)
oddsBox.BackgroundColor3 = T.panel
oddsBox.BorderSizePixel = 0
oddsBox.Parent = pPred
corner(oddsBox, 9)
local oddsTxt = Instance.new("TextLabel")
oddsTxt.Size = UDim2.new(1, -20, 1, -14)
oddsTxt.Position = UDim2.new(0, 10, 0, 7)
oddsTxt.BackgroundTransparency = 1
oddsTxt.Text = "belum ada reset tercatat"
oddsTxt.Font = Enum.Font.Code
oddsTxt.TextSize = 10
oddsTxt.TextColor3 = T.txt2
oddsTxt.TextXAlignment = Enum.TextXAlignment.Left
oddsTxt.TextYAlignment = Enum.TextYAlignment.Top
oddsTxt.Parent = oddsBox

section(pPred, "temuan langka")
local alertBox = Instance.new("Frame")
alertBox.Size = UDim2.new(1, 0, 0, 108)
alertBox.BackgroundColor3 = T.panel
alertBox.BorderSizePixel = 0
alertBox.Parent = pPred
corner(alertBox, 9)
local alertTxt = Instance.new("TextLabel")
alertTxt.Size = UDim2.new(1, -20, 1, -14)
alertTxt.Position = UDim2.new(0, 10, 0, 7)
alertTxt.BackgroundTransparency = 1
alertTxt.Text = "belum ada"
alertTxt.Font = Enum.Font.Code
alertTxt.TextSize = 10
alertTxt.TextColor3 = T.txt2
alertTxt.TextXAlignment = Enum.TextXAlignment.Left
alertTxt.TextYAlignment = Enum.TextYAlignment.Top
alertTxt.Parent = alertBox

section(pPred, "uji kejujuran")
local probeBox = Instance.new("Frame")
probeBox.Size = UDim2.new(1, 0, 0, 92)
probeBox.BackgroundColor3 = T.panel
probeBox.BorderSizePixel = 0
probeBox.Parent = pPred
corner(probeBox, 9)
local probeTxt = Instance.new("TextLabel")
probeTxt.Size = UDim2.new(1, -20, 1, -14)
probeTxt.Position = UDim2.new(0, 10, 0, 7)
probeTxt.BackgroundTransparency = 1
probeTxt.Text = "tekan tombol di bawah untuk cek apakah server\nmengirim data telur berikutnya"
probeTxt.Font = Enum.Font.Code
probeTxt.TextSize = 10
probeTxt.TextColor3 = T.txt2
probeTxt.TextXAlignment = Enum.TextXAlignment.Left
probeTxt.TextYAlignment = Enum.TextYAlignment.Top
probeTxt.Parent = probeBox

action(pPred, "Cek data 'telur berikutnya'", function()
  local p = probeNextEgg()
  local n = hookAnnouncements()
  if p.found == 0 then
    probeTxt.Text = "HASIL: server TIDAK mengirim data telur berikutnya.\n"
      .. "Jadi prediksi rarity pasti memang mustahil dari klien.\n"
      .. "hook pengumuman aktif: " .. n .. " remote"
    probeTxt.TextColor3 = Color3.fromRGB(235, 170, 140)
  else
    local lines = { "HASIL: ada " .. p.found .. " nilai yang mungkin relevan:" }
    for i = 1, math.min(4, #p.list) do lines[#lines + 1] = "  " .. p.list[i] end
    probeTxt.Text = table.concat(lines, "\n")
    probeTxt.TextColor3 = T.jade
  end
end, "gold")

action(pPred, "Reset data pengamatan", function()
  PRED.resetTimes = {}; PRED.counts = {}; PRED.seenNames = {}
  PRED.observed = 0; PRED.period = nil; PRED.lastReset = nil
  PRED.alerts = {}; PRED.sig = nil
end)

-- ticker halaman prediksi
task.spawn(function()
  while true do
    task.wait(1)
    pcall(function()
      if activePage ~= "PREDIKSI" then return end

      local left, src = nextResetIn()
      cdBig.Text = left and fmtDur(left) or "--"
      cdBig.TextColor3 = (left and left < 25) and T.jade or T.gold
      local perTxt = PRED.period and (fmtDur(PRED.period) .. "/siklus") or "periode belum terukur"
      cdSub.Text = string.format("%s · %s · reset tercatat: %d", src, perTxt, PRED.observed)

      -- peluang
      if PRED.observed < 1 then
        oddsTxt.Text = PRED.watch
          and "mengamati... butuh minimal 2 reset (~10 menit)"
          or  "nyalakan 'Pantau siklus telur'"
      else
        local lines = {}
        for _, r in ipairs({ "Cosmic", "Secret", "Eternal", "Divine" }) do
          local wait, n, rate = odds(r)
          if wait then
            lines[#lines + 1] = string.format("%-8s %5.1f%% · tiap ~%s",
              r, rate * 100, fmtDur(wait))
          else
            lines[#lines + 1] = string.format("%-8s   belum pernah terlihat (%d reset)", r, n)
          end
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = "angka dari server ini saja, bukan global"
        oddsTxt.Text = table.concat(lines, "\n")
      end

      -- temuan
      if #PRED.alerts == 0 then
        alertTxt.Text = PRED.watch and "belum ada telur langka terdeteksi" or "pengamat mati"
      else
        local lines = {}
        local h = hrp()
        for i = 1, math.min(5, #PRED.alerts) do
          local a = PRED.alerts[i]
          local ago = fmtDur(tick() - a.t)
          local d = (h and a.pos) and (math.floor(dist(h.Position, a.pos)) .. "m") or "?"
          lines[#lines + 1] = string.format("%s%s · %s · %s lalu",
            (a.mut and (a.mut .. " ") or ""), a.rar, d, ago)
        end
        if PRED.lastAnn then
          lines[#lines + 1] = "pengumuman server: " .. PRED.lastAnn.rar
        end
        alertTxt.Text = table.concat(lines, "\n")
      end
    end)
  end
end)


-- ============ TEST HOOK ============
-- Publishes internals only when a harness sets SAE_TEST as a global first.
-- Roblox/Delta never set it, so nothing leaks into the game environment.
-- Note: in the standalone Luau CLI, top-level globals land in getfenv(0),
-- which is NOT the same table as _G — so both are checked and written.
do
  local env = getfenv(0)
  local flagged = rawget(env, "SAE_TEST") or (type(_G) == "table" and rawget(_G, "SAE_TEST"))
  if flagged then
    local api = {
      S            = S,
      RARITY       = RARITY,
      MUTATION     = MUTATION,
      RCOLOR       = RCOLOR,
      scanEggs     = scanEggs,
      scanTraps    = scanTraps,
      scanHostiles = scanHostiles,
      rarityOf     = rarityOf,
      mutationOf   = mutationOf,
      weightOf     = weightOf,
      myBase       = myBase,
      pickEgg      = pickEgg,
      eggScore     = eggScore,
      glideTo      = glideTo,
      stopGlide    = stopGlide,
      fireMatch    = fireMatch,
      indexRemotes = indexRemotes,
      getRemotes   = function() return remotes end,
      pressPromptsNear = pressPromptsNear,
      -- database pet
      DB           = DB,
      DB_COUNT     = DB_COUNT,
      DISPLAY      = DISPLAY,
      dbLookup     = dbLookup,
      dbExact      = dbExact,
      dbStripMutation = dbStripMutation,
      incomeOf     = incomeOf,
      money        = money,
      kg           = kg,
      MUT_MULT     = MUT_MULT,
      walkTo       = walkTo,
      hopTo        = hopTo,
      moveTo       = moveTo,
      avoidOffset  = avoidOffset,
      nearOwnBase  = nearOwnBase,
      heldByMe     = heldByMe,
      grabAttempt  = grabAttempt,
      promptsInside = promptsInside,
      touchAllParts = touchAllParts,
      gui          = gui,
      win          = win,
      orb          = orb,
      pages        = pages,
      tabs         = tabs,
      showPage     = showPage,
      espFolder    = espF,
      statusTxt    = statusTxt,
      hideBtn      = hideBtn,
      rarityBtns   = rarityBtns,
      -- prediksi
      PRED         = PRED,
      eggSignature = eggSignature,
      similarity   = similarity,
      computePeriod = computePeriod,
      nextResetIn  = nextResetIn,
      odds         = odds,
      probeNextEgg = probeNextEgg,
      findLiveTimer = findLiveTimer,
      hookAnnouncements = hookAnnouncements,
      fmtDur       = fmtDur,
      predPage     = pPred,
      cdBig        = cdBig,
      cdSub        = cdSub,
      oddsTxt      = oddsTxt,
      alertTxt     = alertTxt,
      probeTxt     = probeTxt,
    }
    env.SAE = api
    -- _G may be readonly (standalone Luau CLI); ignore if so
    pcall(function()
      if type(_G) == "table" then _G.SAE = api end
    end)
  end
end
