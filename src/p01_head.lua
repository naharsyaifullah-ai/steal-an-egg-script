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
  blindFire    = false,    -- tembak remote hasil TEBAKAN nama (mati by default)
  approachDist = 6,        -- sedekat apa harus mendekat sebelum mencoba ambil
  hoverBase    = true,     -- setelah ambil, pulang ke base

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
