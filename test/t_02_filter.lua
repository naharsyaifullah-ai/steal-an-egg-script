-- ---- t_02_filter.lua ----
local A = SAE

sect("3. filter rarity benar-benar menyaring")
do
  local function only(...)
    for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = false end
    for _, r in ipairs({ ... }) do A.S.rarityPick[r] = true end
  end

  -- default dari script: Secret + Eternal + Divine
  local e = A.pickEgg()
  check("default pilih Divine (skor tertinggi)", e and e.obj.Name == "KitsuneEgg",
    e and e.obj.Name)

  only("Common")
  local e2 = A.pickEgg()
  check("filter Common → ChickenEgg", e2 and e2.obj.Name == "ChickenEgg", e2 and e2.obj.Name)

  only("Legendary")
  local e3 = A.pickEgg()
  check("filter Legendary → LavaIguanaEgg", e3 and e3.obj.Name == "LavaIguanaEgg",
    e3 and e3.obj.Name)

  only("Secret")
  local e4 = A.pickEgg()
  check("filter Secret → StagEgg", e4 and e4.obj.Name == "StagEgg", e4 and e4.obj.Name)

  only("Mythic")
  local e5 = A.pickEgg()
  check("filter Mythic (tak ada di map) → nil, tidak salah ambil", e5 == nil,
    e5 and e5.obj.Name)

  only("Rare", "Eternal")
  local e6 = A.pickEgg()
  check("filter ganda ambil yang lebih tinggi (Eternal)",
    e6 and e6.obj.Name == "OniTigerEgg", e6 and e6.obj.Name)

  -- semua rarity aktif → telur tanpa label tetap boleh
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = true end
  local all = 0
  for _, eg in ipairs(A.scanEggs()) do
    if eg.rar == nil then all = all + 1 end
  end
  check("telur tanpa label tidak lolos filter aktif (dilewati)", all == 1, all)

  -- tanpa filter apa pun (semua off) → tidak menyaring rarity, ambil apa saja terdekat
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = false end
  local e7 = A.pickEgg()
  check("nol filter → tetap dapat telur (mode ambil semua)", e7 ~= nil, e7 and e7.obj.Name)
end

sect("4. filter berat & prioritas mutasi")
do
  for _, r in ipairs(A.RARITY) do A.S.rarityPick[r] = true end

  A.S.minWeight = 1000000
  local e = A.pickEgg()
  check("berat minimum 1jt kg dipatuhi", e and e.wt >= 1000000, e and e.wt)

  A.S.minWeight = 9999999999
  local none = A.pickEgg()
  check("berat minimum mustahil → nil", none == nil, none and none.obj.Name)
  A.S.minWeight = 0

  A.S.preferMutasi = true
  local withMut = A.eggScore({ rar = "Secret", mut = "Spirit Bloom", wt = 0 })
  local noMut   = A.eggScore({ rar = "Secret", mut = nil, wt = 0 })
  check("mutasi menaikkan skor", withMut > noMut, withMut .. " vs " .. noMut)

  local spirit = A.eggScore({ rar = "Secret", mut = "Spirit Bloom", wt = 0 })
  local silver = A.eggScore({ rar = "Secret", mut = "Silver", wt = 0 })
  check("Spirit Bloom > Silver (urut pengali)", spirit > silver, spirit .. " vs " .. silver)

  A.S.preferMutasi = false
  local off = A.eggScore({ rar = "Secret", mut = "Spirit Bloom", wt = 0 })
  check("prioritas mutasi bisa dimatikan", off == noMut, off .. " vs " .. noMut)
  A.S.preferMutasi = true

  check("Divine > Eternal", A.eggScore({ rar = "Divine", wt = 0 }) > A.eggScore({ rar = "Eternal", wt = 0 }))
  check("Eternal > Secret", A.eggScore({ rar = "Eternal", wt = 0 }) > A.eggScore({ rar = "Secret", wt = 0 }))
  check("Secret > Cosmic", A.eggScore({ rar = "Secret", wt = 0 }) > A.eggScore({ rar = "Cosmic", wt = 0 }))
  check("rarity mengalahkan berat",
    A.eggScore({ rar = "Divine", wt = 0 }) > A.eggScore({ rar = "Common", wt = 5000000 }))
end
