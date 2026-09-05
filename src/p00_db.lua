-- ============ DATABASE PET & TELUR ============
-- Sumber: index resmi komunitas (Eldorado, 31 Agu 2026) — 80 pet, 10 biome.
-- Ini yang membuat ESP bisa bilang "Cosmic · Leviathan · $220K/s" walaupun
-- game TIDAK menempelkan label rarity apa pun pada telurnya.
-- Kunci = nama pet huruf kecil tanpa spasi, supaya cocok dengan nama objek
-- seperti "LeviathanEgg", "Leviathan_Egg", "Egg_Leviathan".

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
  -- Brainrot (telur Shop terbatas)
  tungtungsahur      = { "Rare",      nil,        "Brainrot" },
  bananitadolphinita = { "Epic",      nil,        "Brainrot" },
  belulabeluga       = { "Mythic",    nil,        "Brainrot" },
  mangoliniparrochini = { "Cosmic",   nil,        "Brainrot" },
  bomboclatcrocolat  = { "Secret",    nil,        "Brainrot" },
  strawberryelephant = { "Eternal",   nil,        "Brainrot" },
}

-- Nama tampilan. Default: kapitalkan huruf pertama kunci ("kitsune" -> "Kitsune").
-- Versi sebelumnya memakai kunci mentah, jadi ESP menulis "leviathan" huruf kecil.
local DISPLAY = {}
for k in pairs(DB) do
  DISPLAY[k] = k:sub(1, 1):upper() .. k:sub(2)
end
-- pet bernama lebih dari satu kata perlu ditulis manual
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

-- kunci diurut dari terpanjang: "kingmammoth" harus menang atas "mammoth",
-- "icedragon" atas "dragon", "sandspider" atas "spider"
local DB_KEYS = {}
for k in pairs(DB) do DB_KEYS[#DB_KEYS + 1] = k end
table.sort(DB_KEYS, function(a, b) return #a > #b end)

local function normalize(s)
  return (tostring(s or ""):lower():gsub("[^%a]", ""))
end

-- cocokkan nama objek ke database pet
local function dbLookup(name)
  local n = normalize(name)
  if n == "" then return nil end
  n = n:gsub("egg", "")           -- "leviathanegg" -> "leviathan"
  if DB[n] then return n end
  for _, k in ipairs(DB_KEYS) do
    if #k >= 4 and n:find(k, 1, true) then return k end
  end
  return nil
end

-- versi ketat: hanya cocok kalau nama objek PERSIS nama pet (setelah membuang
-- kata "egg" dan tanda baca). Dipakai untuk memutuskan apakah suatu objek
-- adalah telur, supaya "BearTrap" tidak keliru dianggap telur Bear.
local function dbExact(name)
  local n = normalize(name):gsub("egg", "")
  if n ~= "" and DB[n] then return n end
  return nil
end

-- format uang: 1800000000 -> "$1.8B/s"
local function money(v)
  if not v then return "?" end
  local a = math.abs(v)
  if a >= 1e9 then return string.format("$%.3gB/s", v / 1e9) end
  if a >= 1e6 then return string.format("$%.3gM/s", v / 1e6) end
  if a >= 1e3 then return string.format("$%.3gK/s", v / 1e3) end
  return string.format("$%d/s", math.floor(v))
end

-- berat kg singkat: 3240000 -> "3.24Mkg"
local function kg(v)
  if not v or v <= 0 then return nil end
  if v >= 1e6 then return string.format("%.3gMkg", v / 1e6) end
  if v >= 1e3 then return string.format("%.3gKkg", v / 1e3) end
  return string.format("%dkg", math.floor(v))
end
