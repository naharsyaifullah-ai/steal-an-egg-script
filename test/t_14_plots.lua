-- ---- t_14_plots.lua ----
-- v6.1: telur di base pemain lain BUKAN sasaran default. Laporan nyata di
-- game: auto steal malah kabur ke base orang dan mencoba mencuri telur
-- milik pemain. Telur di dalam workspace.Plots kini ditandai `owned`
-- dan hanya dikejar kalau pengguna menyalakan togglenya sendiri.
local A = SAE
local W = MOCK.Workspace
local LPn = tostring(MOCK.LocalPlayer.Name)

sect("78. telur di base pemain bukan sasaran default")
do
  local plots = Instance.new("Folder", W)
  plots.Name = "Plots"

  local rivalPlot = Instance.new("Model", plots)
  rivalPlot.Name = "Plot7"
  local rf = makePart("Floor", rivalPlot, Vector3.new(5000, 0, 0))
  rawget(rivalPlot, "_p").PrimaryPart = rf
  local own2 = Instance.new("StringValue", rivalPlot)
  own2.Name = "Owner"
  own2.Value = "RivalOne"

  local minePlot = Instance.new("Model", plots)
  minePlot.Name = "Plot3"
  local mf = makePart("Floor", minePlot, Vector3.new(5200, 0, 0))
  rawget(minePlot, "_p").PrimaryPart = mf
  local own = Instance.new("StringValue", minePlot)
  own.Name = "Owner"
  own.Value = LPn

  -- telur di base rival, telur di base sendiri, telur liar di zona
  local plotEgg = makeEgg(rivalPlot, "KitsuneEgg", Vector3.new(5001, 0, 0), "Divine", nil, nil)
  local myEgg   = makeEgg(minePlot,   "StagEgg",    Vector3.new(5201, 0, 0), "Secret", nil, nil)
  local wild    = makeEgg(W,          "OniTigerEgg",Vector3.new(5100, 0, 0), "Eternal", nil, nil)

  -- dekatkan karakter ke area uji supaya telur dunia lama tidak ikut dicampur
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local oldPos = hrp.Position
  hrp.Position = Vector3.new(5000, 0, 3)
  A.flushBaseCache()

  local got = {}
  for _, e in ipairs(A.scanEggs()) do
    got[e.obj] = e
  end
  check("telur di plot rival ditandai owned", got[plotEgg] and got[plotEgg].owned == true)
  check("telur milik rival bukan milikku", got[plotEgg] and got[plotEgg].mine ~= true)
  check("telur di plot sendiri = owned + milikku",
    got[myEgg] and got[myEgg].owned == true and got[myEgg].mine == true)
  check("telur liar di zona bukan owned", got[wild] and got[wild].owned == false)

  A.S.takePlots = false
  local pick = A.pickEgg()
  check("default: yang dikejar telur LIAR di zona, bukan telur orang",
    pick ~= nil and pick.obj == wild, pick and tostring(pick.obj.Name))

  -- telur yang sedang DIBAWA pemain lain juga milik orang: jangan kejar
  -- karakter pemain itu (laporan nyata kedua dari game)
  local carrierPl = addOtherPlayer("CarrierRival", Vector3.new(5003, 0, 3))
  local carrierChr = rawget(carrierPl, "_p").Character
  local carried = makeEgg(carrierChr, "OniTigerEgg", Vector3.new(5003, 0, 3), "Eternal", nil, nil)
  check("telur di tangan pemain lain terdeteksi milik orang",
    A.heldByOther(carried) == true)
  check("telur di plot bukan 'dibawa pemain'", A.heldByOther(plotEgg) == false)
  local pickC = A.pickEgg()
  check("default: karakter pemain lain tidak dikejar",
    pickC ~= nil and pickC.obj == wild, pickC and tostring(pickC.obj.Name))

  A.S.takePlots = true
  local pick2 = A.pickEgg()
  check("toggle nyala: telur base orang boleh dikejar",
    pick2 ~= nil and pick2.obj == plotEgg, pick2 and tostring(pick2.obj.Name))

  A.S.takePlots = true
  local pickMine = nil
  for _, e in ipairs(A.scanEggs()) do
    if e.obj == myEgg and not e.mine then pickMine = e end
  end
  check("telur di base SENDIRI tidak pernah jadi sasaran", pickMine == nil)

  -- bersihkan
  A.S.takePlots = false
  hrp.Position = oldPos
  plots:Destroy()
  wild:Destroy()
  A.flushBaseCache()
end
