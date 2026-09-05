-- ---- t_12_spy.lua ----
-- Inti v5: script tidak lagi MENEBAK nama remote. Ia merekam panggilan yang
-- benar-benar dipakai saat pengguna mengambil telur, lalu memutarnya ulang.
-- Blok ini membuktikan rekaman-dan-putar-ulang itu benar-benar bekerja.
local A = SAE
local SPY = A.SPY
local W = MOCK.Workspace

local function bareEgg(name, pos)
  local m = Instance.new("Model", W)
  m.Name = name
  local pp = Instance.new("Part", m)
  pp.Name = "Shell"
  pp.Position = pos
  rawget(m, "_p").PrimaryPart = pp
  return m
end
local function clearEggs()
  for _, e in ipairs(A.scanEggs()) do e.obj.Parent = nil end
end
local function fired(r) return rawget(r, "_p")._fired end
local function lastArgs(r) return rawget(r, "_p")._lastArgs end

sect("63. perekam: mencatat tembakan remote nyata")
do
  SPY.log = {}
  SPY.prompts = {}
  SPY.fires = 0
  SPY.learned = nil
  SPY.learnedFrom = nil
  SPY.recording = true

  -- mock tidak punya hookmetamethod, jadi rekaman disuntik lewat jalur
  -- yang sama dipakai hook: recordFire dipanggil dari FireServer wrapper.
  -- Di sini kita tiru dengan memanggil API publik perekam.
  local egg = bareEgg("KoiEgg", Vector3.new(9000, 5, 0))
  local gameRemote = makeRemote(MOCK.RS, "RF_EggInteract")

  -- inilah bentuk panggilan yang khas: remote(aksi, objekTelur)
  SPY.recordForTest(gameRemote, "FireServer",
    table.pack(gameRemote, "Grab", egg))

  check("tembakan tercatat", SPY.fires == 1, SPY.fires)
  check("nama remote tercatat", SPY.log[1] and SPY.log[1].name == "RF_EggInteract",
    SPY.log[1] and SPY.log[1].name)
  check("argumen dideskripsikan", SPY.log[1] and
    SPY.log[1].argdesc:find("Grab") ~= nil, SPY.log[1] and SPY.log[1].argdesc)
  check("objek telur dikenali di argumen",
    SPY.log[1] and SPY.log[1].argdesc:find("Instance") ~= nil,
    SPY.log[1] and SPY.log[1].argdesc)
end

sect("64. belajar: resep dibuat dari rekaman + telur yang benar terambil")
do
  local egg = nil
  for _, e in ipairs(A.scanEggs()) do if e.obj.Name == "KoiEgg" then egg = e.obj end end
  check("telur uji ada", egg ~= nil)

  local ok = SPY.learnFrom(egg, tick() - 10)
  check("belajar berhasil", ok == true)
  check("sumber belajar = remote", SPY.learnedFrom == "remote", SPY.learnedFrom)
  check("resep menyimpan nama remote",
    SPY.learned and SPY.learned.name == "RF_EggInteract",
    SPY.learned and SPY.learned.name)
  check("resep menyimpan metode",
    SPY.learned and SPY.learned.method == "FireServer",
    SPY.learned and SPY.learned.method)

  -- cetakan: argumen pertama literal "Grab", kedua placeholder telur
  local tpl = SPY.learned and SPY.learned.template
  check("cetakan punya 2 slot", tpl and #tpl == 2, tpl and #tpl)
  check("slot 1 = literal", tpl and tpl[1].kind == "literal", tpl and tpl[1].kind)
  check("slot 1 nilainya 'Grab'", tpl and tpl[1].value == "Grab", tpl and tpl[1].value)
  check("slot 2 = placeholder telur", tpl and tpl[2].kind == "egg", tpl and tpl[2].kind)
end

sect("65. putar ulang: telur BARU disisipkan ke posisi yang benar")
do
  clearEggs()
  local newEgg = bareEgg("StagEgg", Vector3.new(9100, 5, 0))
  local r = nil
  for _, d in ipairs(MOCK.RS:GetChildren()) do
    if d.Name == "RF_EggInteract" then r = d end
  end
  check("remote yang dipelajari masih ada", r ~= nil)
  rawget(r, "_p")._fired = nil

  local ok = SPY.replay(newEgg)
  check("putar ulang berhasil", ok == true)
  check("remote yang SAMA ditembak", fired(r) == 1, fired(r))

  local la = lastArgs(r)
  check("2 argumen terkirim", la and la.n == 2, la and la.n)
  check("argumen 1 tetap 'Grab' (literal dipertahankan)",
    la and la[1] == "Grab", la and tostring(la[1]))
  check("argumen 2 = telur BARU, bukan telur lama",
    la and la[2] == newEgg, la and tostring(la[2] and la[2].Name))
end

sect("66. grabAttempt memakai resep, bukan tebakan")
do
  clearEggs()
  local egg = bareEgg("LeviathanEgg", Vector3.new(9200, 5, 0))
  local e = nil
  for _, x in ipairs(A.scanEggs()) do if x.obj == egg then e = x end end
  check("telur siap", e ~= nil)

  local r = nil
  for _, d in ipairs(MOCK.RS:GetChildren()) do
    if d.Name == "RF_EggInteract" then r = d end
  end
  rawget(r, "_p")._fired = nil
  for _, rr in pairs(R) do rawget(rr, "_p")._fired = nil end

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(9200, 5, 0)

  A.S.blindFire = false
  A.grabAttempt(e)

  check("remote hasil belajar ditembak", fired(r) == 1, fired(r))
  check("remote tebakan 'StealEgg' TIDAK ditembak",
    fired(R.steal) == nil, fired(R.steal))
  check("argumen berisi telur yang sedang diproses",
    lastArgs(r) and lastArgs(r)[2] == egg, "ok")
end

sect("67. tanpa resep: hanya prompt + sentuhan, tidak menembak remote")
do
  SPY.learned = nil
  SPY.learnedFrom = nil
  clearEggs()
  local egg = bareEgg("CraneEgg", Vector3.new(9300, 5, 0))
  local prompt = Instance.new("ProximityPrompt", egg)
  local e = nil
  for _, x in ipairs(A.scanEggs()) do if x.obj == egg then e = x end end

  for _, rr in pairs(R) do rawget(rr, "_p")._fired = nil end
  local pBefore, tBefore = PROMPT_FIRED, TOUCH_FIRED
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(9300, 5, 0)

  A.S.blindFire = false
  A.grabAttempt(e)

  check("prompt tetap ditekan", PROMPT_FIRED > pBefore, PROMPT_FIRED - pBefore)
  check("part tetap disentuh", TOUCH_FIRED > tBefore, TOUCH_FIRED - tBefore)
  local any = false
  for _, rr in pairs(R) do if fired(rr) then any = true end end
  check("NOL remote tebakan ditembak", any == false, "ok")
end

sect("68. blindFire menyala: tebakan diizinkan (opt-in)")
do
  SPY.learned = nil
  SPY.learnedFrom = nil
  clearEggs()
  local egg = bareEgg("YetiEgg", Vector3.new(9400, 5, 0))
  local e = nil
  for _, x in ipairs(A.scanEggs()) do if x.obj == egg then e = x end end
  for _, rr in pairs(R) do rawget(rr, "_p")._fired = nil end

  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(9400, 5, 0)

  A.S.blindFire = true
  A.grabAttempt(e)
  check("dengan blindFire, remote 'StealEgg' ditembak", fired(R.steal) ~= nil,
    fired(R.steal))
  A.S.blindFire = false
end

sect("69. belajar 'prompt saja': tidak menembak remote apa pun")
do
  SPY.log = {}
  SPY.prompts = { { t = tick(), name = "KoiNest", path = "Workspace.KoiNest.Prompt" } }
  SPY.learned = nil
  SPY.learnedFrom = nil

  clearEggs()
  local egg = bareEgg("SwanEgg", Vector3.new(9500, 5, 0))
  SPY.learnFrom(egg, tick() - 5)
  check("sumber belajar = prompt", SPY.learnedFrom == "prompt", SPY.learnedFrom)
  check("tidak ada resep remote", SPY.learned == nil)
  check("catatan menjelaskan cara prompt",
    tostring(SPY.note):find("Prox") ~= nil or tostring(SPY.note):find("prompt") ~= nil,
    SPY.note)

  local e = nil
  for _, x in ipairs(A.scanEggs()) do if x.obj == egg then e = x end end
  for _, rr in pairs(R) do rawget(rr, "_p")._fired = nil end
  A.S.blindFire = true          -- sengaja menyala: resep prompt harus menang
  A.grabAttempt(e)
  local any = false
  for _, rr in pairs(R) do if fired(rr) then any = true end end
  check("resep prompt mencegah tembakan remote walau blindFire ON", any == false, "ok")
  A.S.blindFire = false
end

sect("70. belajar 'sentuhan saja': tidak ada remote & prompt")
do
  SPY.log = {}
  SPY.prompts = {}
  SPY.learned = nil
  SPY.learnedFrom = nil
  clearEggs()
  local egg = bareEgg("TurtleEgg", Vector3.new(9600, 5, 0))
  SPY.learnFrom(egg, tick() - 5)
  check("sumber belajar = touch", SPY.learnedFrom == "touch", SPY.learnedFrom)
  check("catatan menyebut sentuhan",
    tostring(SPY.note):find("sentuh") ~= nil, SPY.note)
end

sect("71. ringkasan bisa dibaca pengguna")
do
  local s = SPY.summary()
  check("ringkasan memuat status", s:find("status") ~= nil, s:sub(1, 80))
  check("ringkasan memuat kondisi hook", s:find("hook") ~= nil, s:sub(1, 120))
  check("ringkasan memuat jumlah tembakan",
    s:find("tembakan tercatat") ~= nil, s:sub(1, 200))
end

sect("72. mode belajar: tombol & pemantau")
do
  local btn
  for _, c in ipairs(A.pages.STEAL:GetDescendants()) do
    if c.ClassName == "TextButton" and c.Text == "AJARI: ambil 1 telur manual" then btn = c end
  end
  check("tombol AJARI ada di tab STEAL", btn ~= nil)

  clearEggs()
  local egg = bareEgg("AxolotlEgg", Vector3.new(9700, 5, 0))
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(9700, 5, 0)

  A.S.stealOn = true                      -- harus dimatikan oleh tombol
  if btn then rawget(btn, "_p").MouseButton1Click:Fire() end
  check("auto steal dimatikan saat mulai belajar", A.S.stealOn == false)
  check("perekam menyala", SPY.recording == true, SPY.recording)
  check("status memberi instruksi jelas",
    tostring(A.S.status):find("BELAJAR") ~= nil or tostring(A.S.status):find("hook") ~= nil,
    A.S.status)

  -- tiru pengguna mengambil telur: catat remote lalu pindahkan telur ke karakter
  local r2 = makeRemote(MOCK.RS, "RE_PickupRequest")
  SPY.recordForTest(r2, "FireServer", table.pack(r2, egg, "pickup"))
  egg.Parent = CHR
  stepScheduler(30, 0.2)

  check("pemantau mendeteksi telur terambil", SPY.recording == false, SPY.recording)
  check("resep dipelajari dari kejadian nyata",
    SPY.learned and SPY.learned.name == "RE_PickupRequest",
    SPY.learned and SPY.learned.name)
  check("telur yang terambil dicatat",
    tostring(SPY.lastPickup):find("Axolotl") ~= nil, SPY.lastPickup)

  -- resep baru harus bisa diputar untuk telur lain
  egg.Parent = nil
  clearEggs()
  local egg2 = bareEgg("SharkEgg", Vector3.new(9800, 5, 0))
  rawget(r2, "_p")._fired = nil
  SPY.replay(egg2)
  check("resep baru dipakai untuk telur lain", fired(r2) == 1, fired(r2))
  local la = lastArgs(r2)
  check("posisi argumen telur benar", la and la[1] == egg2, "ok")
  check("argumen literal 'pickup' dipertahankan", la and la[2] == "pickup",
    la and tostring(la[2]))
end

sect("73. jarak mendekat dihormati sebelum mencoba ambil")
do
  check("default approachDist wajar", A.S.approachDist >= 3 and A.S.approachDist <= 20,
    A.S.approachDist)
  -- slider ada di UI
  local found = false
  for _, c in ipairs(A.pages.STEAL:GetDescendants()) do
    if c.ClassName == "TextLabel" and c.Text == "Jarak mendekat sebelum ambil" then
      found = true
    end
  end
  check("slider jarak mendekat ada di UI", found)
end
