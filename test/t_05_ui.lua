-- ---- t_05_ui.lua ----
local A = SAE

local function clickOf(btn) return rawget(btn, "_p").MouseButton1Click end
local function click(btn) clickOf(btn):Fire() end

-- find a toggle switch by the label text of its row
local function findRow(page, text)
  for _, row in ipairs(page:GetChildren()) do
    for _, d in ipairs(row:GetDescendants()) do
      if d.ClassName == "TextLabel" and d.Text == text then return row end
    end
  end
  return nil
end
local function switchIn(row)
  for _, d in ipairs(row:GetDescendants()) do
    if d.ClassName == "TextButton" then return d end
  end
  return nil
end

sect("11. tab & panel terpisah")
do
  check("tab STEAL ada", A.tabs.STEAL ~= nil)
  check("tab FARM ada", A.tabs.FARM ~= nil)
  check("tab PLAYER ada", A.tabs.PLAYER ~= nil)
  check("tab ESP ada", A.tabs.ESP ~= nil)

  click(A.tabs.FARM)
  check("klik FARM → halaman FARM tampil",
    A.pages.FARM.Visible == true and A.pages.STEAL.Visible == false)
  click(A.tabs.PLAYER)
  check("klik PLAYER → halaman PLAYER tampil",
    A.pages.PLAYER.Visible == true and A.pages.FARM.Visible == false)
  click(A.tabs.ESP)
  check("klik ESP → halaman ESP tampil", A.pages.ESP.Visible == true)
  click(A.tabs.STEAL)
  check("kembali ke STEAL", A.pages.STEAL.Visible == true)

  -- pengaturan player benar-benar di tab PLAYER, bukan di STEAL
  check("Anti Trap ada di tab PLAYER", findRow(A.pages.PLAYER, "Anti Trap") ~= nil)
  check("Anti Bat / Guard ada di tab PLAYER", findRow(A.pages.PLAYER, "Anti Bat / Guard") ~= nil)
  check("Anti Trap TIDAK di tab STEAL", findRow(A.pages.STEAL, "Anti Trap") == nil)
  check("Auto Steal ada di tab STEAL", findRow(A.pages.STEAL, "Auto Steal Egg") ~= nil)
  check("Auto Hatch ada di tab FARM", findRow(A.pages.FARM, "Auto Hatch") ~= nil)
  check("ESP Telur ada di tab ESP", findRow(A.pages.ESP, "ESP Telur") ~= nil)
end

sect("12. toggle UI mengubah state nyata")
do
  local row = findRow(A.pages.PLAYER, "Anti Trap")
  local sw = switchIn(row)
  local before = A.S.antiTrap
  click(sw)
  check("klik toggle Anti Trap membalik state", A.S.antiTrap ~= before, A.S.antiTrap)
  click(sw)
  check("klik lagi kembali seperti semula", A.S.antiTrap == before, A.S.antiTrap)

  local row2 = findRow(A.pages.FARM, "Auto Hatch")
  local sw2 = switchIn(row2)
  click(sw2)
  check("toggle Auto Hatch aktif", A.S.autoHatch == true)
  click(sw2)
  check("toggle Auto Hatch mati", A.S.autoHatch == false)

  local row3 = findRow(A.pages.ESP, "ESP Trap")
  local sw3 = switchIn(row3)
  click(sw3)
  check("toggle ESP Trap aktif", A.S.espTrap == true)
  click(sw3)
  A.S.espTrap = false
end

sect("13. tombol rarity di UI")
do
  local n = 0
  for _ in pairs(A.rarityBtns) do n = n + 1 end
  check("10 tombol rarity dibuat", n == 10, n)

  -- cari tombol rarity di halaman STEAL dan klik "Divine"
  local target
  for _, child in ipairs(A.pages.STEAL:GetDescendants()) do
    if child.ClassName == "TextButton" and child.Text == "Divine" then target = child end
  end
  check("tombol Divine ditemukan di UI", target ~= nil)
  if target then
    local before = A.S.rarityPick.Divine
    click(target)
    check("klik Divine membalik pilihan", A.S.rarityPick.Divine ~= before, A.S.rarityPick.Divine)
    click(target)
    check("klik ulang kembali", A.S.rarityPick.Divine == before)
  end

  -- tombol cepat "Semua" / "Kosong" / "Top 3"
  local quickBtns = {}
  for _, child in ipairs(A.pages.STEAL:GetDescendants()) do
    if child.ClassName == "TextButton" then quickBtns[child.Text] = child end
  end
  check("tombol cepat Semua ada", quickBtns["Semua"] ~= nil)
  check("tombol cepat Kosong ada", quickBtns["Kosong"] ~= nil)
  check("tombol cepat Top 3 ada", quickBtns["Top 3"] ~= nil)

  if quickBtns["Semua"] then
    click(quickBtns["Semua"])
    local all = true
    for _, r in ipairs(A.RARITY) do if not A.S.rarityPick[r] then all = false end end
    check("'Semua' menyalakan 10 rarity", all)
  end
  if quickBtns["Kosong"] then
    click(quickBtns["Kosong"])
    local none = true
    for _, r in ipairs(A.RARITY) do if A.S.rarityPick[r] then none = false end end
    check("'Kosong' mematikan semua rarity", none)
  end
  if quickBtns["Top 3"] then
    click(quickBtns["Top 3"])
    check("'Top 3' = Secret+Eternal+Divine saja",
      A.S.rarityPick.Secret and A.S.rarityPick.Eternal and A.S.rarityPick.Divine
      and not A.S.rarityPick.Common and not A.S.rarityPick.Cosmic)
  end
end

sect("14. sembunyikan / tampilkan panel")
do
  check("panel tampil di awal", A.win.Visible == true)
  check("orb tersembunyi di awal", A.orb.Visible == false)
  click(A.hideBtn)
  check("tombol — menyembunyikan panel", A.win.Visible == false)
  check("orb muncul sebagai pengganti", A.orb.Visible == true)
  click(A.orb)
  check("klik orb membuka panel lagi", A.win.Visible == true and A.orb.Visible == false)
end

sect("15. tombol STOP darurat")
do
  A.S.stealOn = true; A.S.autoHatch = true; A.S.autoClaim = true
  A.S.autoTrain = true; A.S.autoSell = true; A.S.autoUpgrade = true
  local hum = CHR:FindFirstChildOfClass("Humanoid")
  hum.WalkSpeed = 500

  local stopBtn
  for _, c in ipairs(A.pages.PLAYER:GetDescendants()) do
    if c.ClassName == "TextButton" and c.Text == "STOP semua" then stopBtn = c end
  end
  check("tombol STOP ada", stopBtn ~= nil)
  if stopBtn then
    click(stopBtn)
    check("semua otomatis dimatikan",
      not A.S.stealOn and not A.S.autoHatch and not A.S.autoClaim
      and not A.S.autoTrain and not A.S.autoSell and not A.S.autoUpgrade)
    check("WalkSpeed kembali 16", hum.WalkSpeed == 16, hum.WalkSpeed)
    check("BodyVelocity dibersihkan",
      CHR:FindFirstChild("HumanoidRootPart"):FindFirstChildOfClass("BodyVelocity") == nil)
  end
end
