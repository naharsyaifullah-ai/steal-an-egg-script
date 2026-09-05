-- ---- t_01_detect.lua ----
local A = SAE

sect("1. deteksi rarity / mutasi / berat")
do
  local eggs = A.scanEggs()
  check("semua telur terdeteksi (7)", #eggs == 7, #eggs)

  local byName = {}
  for _, e in ipairs(eggs) do byName[e.obj.Name] = e end

  check("Kitsune terbaca Divine", byName.KitsuneEgg and byName.KitsuneEgg.rar == "Divine",
    byName.KitsuneEgg and byName.KitsuneEgg.rar)
  check("Stag terbaca Secret (bukan 'Rare' dari substring)",
    byName.StagEgg and byName.StagEgg.rar == "Secret",
    byName.StagEgg and byName.StagEgg.rar)
  check("OniTiger terbaca Eternal", byName.OniTigerEgg and byName.OniTigerEgg.rar == "Eternal",
    byName.OniTigerEgg and byName.OniTigerEgg.rar)
  check("Dodo terbaca Rare", byName.DodoEgg and byName.DodoEgg.rar == "Rare",
    byName.DodoEgg and byName.DodoEgg.rar)
  check("mutasi Spirit Bloom terbaca (bukan 'Bloom')",
    byName.KitsuneEgg and byName.KitsuneEgg.mut == "Spirit Bloom",
    byName.KitsuneEgg and byName.KitsuneEgg.mut)
  check("mutasi Bloom biasa terbaca",
    byName.OniTigerEgg and byName.OniTigerEgg.mut == "Bloom",
    byName.OniTigerEgg and byName.OniTigerEgg.mut)
  check("mutasi Silver terbaca", byName.LavaIguanaEgg and byName.LavaIguanaEgg.mut == "Silver",
    byName.LavaIguanaEgg and byName.LavaIguanaEgg.mut)
  check("telur tanpa label rarity = nil (tidak dikarang)",
    byName.MysteryEgg and byName.MysteryEgg.rar == nil,
    byName.MysteryEgg and byName.MysteryEgg.rar)
  check("berat kg terbaca dari label", byName.KitsuneEgg and byName.KitsuneEgg.wt == 3240000,
    byName.KitsuneEgg and byName.KitsuneEgg.wt)
  check("telur tanpa berat = 0", byName.MysteryEgg and byName.MysteryEgg.wt == 0,
    byName.MysteryEgg and byName.MysteryEgg.wt)
end

sect("2. trap, musuh, base")
do
  check("trap terdeteksi (2)", #A.scanTraps() == 2, #A.scanTraps())
  local h = A.scanHostiles()
  check("musuh terdeteksi (3)", #h == 3, #h)
  local kinds = {}
  for _, m in ipairs(h) do kinds[m.kind] = (kinds[m.kind] or 0) + 1 end
  check("bat dikenali", kinds.bat == 1, kinds.bat)
  check("guard dikenali", kinds.guard == 1, kinds.guard)
  check("beast/boss dikenali", kinds.beast == 1, kinds.beast)
  check("karakter pemain tidak dihitung musuh",
    #h == 3 and #MOCK.Players:GetPlayers() == 3, #h)

  local b = A.myBase()
  check("base sendiri ketemu lewat tag Owner",
    b ~= nil and math.abs(b.X) < 1 and math.abs(b.Z) < 1,
    b and (b.X .. "," .. b.Z))
  check("base rival TIDAK dipilih", b ~= nil and b.X ~= 999, b and b.X)
end
