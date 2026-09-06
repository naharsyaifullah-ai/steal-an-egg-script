-- ============ TAB PREDIKSI ============
makeTab("PREDIKSI", 70)
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
