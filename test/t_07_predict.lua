-- ---- t_07_predict.lua ----
local A = SAE
local P = A.PRED

-- helper: bikin ulang isi map telur seperti "reset" di game
local function clearEggs()
  for _, e in ipairs(A.scanEggs()) do e.obj.Parent = nil end
end
local function spawnSet(list)
  clearEggs()
  local made = {}
  for _, spec in ipairs(list) do
    made[#made + 1] = makeEgg(MOCK.Workspace, spec[1],
      Vector3.new(spec[4] or 200, 0, 0), spec[2], spec[3], spec[5])
  end
  return made
end

sect("21. format durasi")
do
  check("detik", A.fmtDur(45) == "45s", A.fmtDur(45))
  check("menit:detik", A.fmtDur(305) == "5m 05s", A.fmtDur(305))
  check("jam", A.fmtDur(3700) == "1j 01m", A.fmtDur(3700))
  check("hari", A.fmtDur(90000) == "1h 01j", A.fmtDur(90000))
  check("nil aman", A.fmtDur(nil) == "-", A.fmtDur(nil))
end

sect("22. sidik jari & kemiripan isi map")
do
  local s1 = A.eggSignature()
  check("sidik jari terisi", type(s1) == "string" and #s1 > 0, (s1 or ""):sub(1, 40))
  local s2 = A.eggSignature()
  check("sidik jari stabil kalau map tidak berubah", s1 == s2)

  check("identik → similarity 1", math.abs(A.similarity(s1, s1) - 1) < 0.001,
    A.similarity(s1, s1))
  check("beda total → similarity 0",
    A.similarity("a@1,1", "b@2,2") == 0, A.similarity("a@1,1", "b@2,2"))
  local half = A.similarity("a@1,1;b@2,2", "a@1,1;c@3,3")
  check("separuh sama → similarity di tengah", half > 0.2 and half < 0.5, half)
end

sect("23. pengamat mempelajari periode reset dari map")
do
  -- bersihkan data pengamatan
  P.resetTimes = {}; P.counts = {}; P.seenNames = {}
  P.observed = 0; P.period = nil; P.lastReset = nil
  P.alerts = {}; P.sig = nil
  P.watch = true
  A.S.stealOn = false
  P.autoGo = false

  -- reset #1: isi map A
  spawnSet({
    { "ChickenEgg", "Common", nil, 100, 120 },
    { "DodoEgg", "Rare", nil, 150, 4000 },
  })
  stepScheduler(30, 1.0)   -- 30 detik dunia

  -- reset #2: isi map benar-benar beda (semua nama & posisi baru)
  spawnSet({
    { "StagEgg", "Secret", nil, 300, 900000 },
    { "KoiEgg", "Cosmic", nil, 350, 500000 },
  })
  stepScheduler(30, 1.0)

  -- reset #3
  spawnSet({
    { "KitsuneEgg", "Divine", "Spirit Bloom", 400, 3240000 },
    { "CraneEgg", "Epic", nil, 420, 8000 },
  })
  stepScheduler(30, 1.0)

  check("reset terdeteksi (≥2)", P.observed >= 2, P.observed)
  check("riwayat waktu reset tercatat", #P.resetTimes >= 2, #P.resetTimes)
  check("periode terukur, bukan dikarang", P.period ~= nil and P.period > 0, P.period)
  check("periode mendekati 30s (jarak simulasi)",
    P.period and math.abs(P.period - 30) < 8, P.period)

  check("Secret tercatat pernah muncul", (P.counts.Secret or 0) >= 1, P.counts.Secret)
  check("Divine tercatat pernah muncul", (P.counts.Divine or 0) >= 1, P.counts.Divine)
  check("Mythic TIDAK dikarang muncul", P.counts.Mythic == nil, P.counts.Mythic)

  local left, src = A.nextResetIn()
  check("hitung mundur reset tersedia", left ~= nil, left)
  check("hitung mundur tidak negatif", left and left >= 0, left)
  check("sumber hitungan disebut jujur",
    src == "periode terukur" or src == "timer game", src)
end

sect("24. peluang: hanya dari data nyata")
do
  local w, n, rate = A.odds("Secret")
  check("peluang Secret terhitung", w ~= nil, w)
  check("rate antara 0 dan 1", rate > 0 and rate <= 1, rate)
  check("jumlah reset dilaporkan apa adanya", n == P.observed, n .. " vs " .. P.observed)

  local w2, n2, rate2 = A.odds("Mythic")
  check("rarity tak pernah terlihat → tidak ada perkiraan (nil)", w2 == nil, w2)
  check("rate 0 untuk yang belum terlihat", rate2 == 0, rate2)

  -- tanpa data sama sekali, semua nil
  local savedObs = P.observed
  P.observed = 0
  local w3 = A.odds("Divine")
  check("nol pengamatan → nil, tidak menebak", w3 == nil, w3)
  P.observed = savedObs
end

sect("25. deteksi telur langka + alarm")
do
  P.alerts = {}
  P.notify = { Secret = true, Eternal = true, Divine = true }

  spawnSet({
    { "ChickenEgg", "Common", nil, 100, 120 },
    { "MosasaurusEgg", "Eternal", "Rainbow", 500, 2000000 },
  })
  stepScheduler(20, 1.0)

  check("alarm terisi saat Eternal muncul", #P.alerts >= 1, #P.alerts)
  local found = false
  for _, a in ipairs(P.alerts) do if a.rar == "Eternal" then found = true end end
  check("alarm menyebut rarity yang benar", found, P.alerts[1] and P.alerts[1].rar)
  check("alarm menyimpan posisi", P.alerts[1] and P.alerts[1].pos ~= nil)
  check("alarm menyimpan mutasi",
    (function() for _, a in ipairs(P.alerts) do if a.mut == "Rainbow" then return true end end return false end)())

  -- rarity yang tidak dipantau tidak boleh memicu alarm
  P.alerts = {}
  P.notify = { Divine = true }
  spawnSet({ { "DodoEgg", "Rare", nil, 200, 4000 } })
  stepScheduler(20, 1.0)
  local wrong = false
  for _, a in ipairs(P.alerts) do if a.rar == "Rare" then wrong = true end end
  check("rarity tak dipantau tidak memicu alarm", wrong == false, #P.alerts)
  P.notify = { Secret = true, Eternal = true, Divine = true }
end

sect("26. probe kejujuran: server kirim data telur berikutnya?")
do
  local p1 = A.probeNextEgg()
  check("probe jalan", type(p1) == "table")
  check("map bersih → 0 temuan (tidak mengaku bisa prediksi)", p1.found == 0, p1.found)

  -- tanam nilai yang MEMANG relevan
  local v = Instance.new("StringValue", MOCK.RS)
  v.Name = "NextEggRarity"
  v.Value = "Secret"
  local p2 = A.probeNextEgg()
  check("probe menemukan nilai relevan kalau ada", p2.found >= 1, p2.found)
  check("isi nilai dilaporkan",
    tostring(table.concat(p2.list, " ")):find("Secret") ~= nil, p2.list[1])
  v.Parent = nil

  -- nama mirip tapi tak relevan tidak boleh dihitung
  local v2 = Instance.new("StringValue", MOCK.RS)
  v2.Name = "PlayerNickname"
  v2.Value = "next"
  local p3 = A.probeNextEgg()
  check("nilai tak relevan diabaikan", p3.found == 0, p3.found)
  v2.Parent = nil
end

sect("27. hitung mundur bawaan game diprioritaskan")
do
  local pg = MOCK.LocalPlayer:FindFirstChild("PlayerGui")
  local lbl = Instance.new("TextLabel", pg)
  lbl.Text = "2:15"
  local t = A.findLiveTimer()
  check("timer game 2:15 terbaca = 135s", t == 135, t)

  lbl.Text = "45s"
  check("format 45s terbaca", A.findLiveTimer() == 45, A.findLiveTimer())

  lbl.Text = "99:99"
  check("nilai mustahil ditolak", A.findLiveTimer() == nil, A.findLiveTimer())

  lbl.Text = "1:30"
  P.liveTimer = A.findLiveTimer()
  local left, src = A.nextResetIn()
  check("timer game dipakai lebih dulu", src == "timer game", src)
  check("nilainya dari label game", left == 90, left)
  lbl.Parent = nil
  P.liveTimer = nil
end

sect("28. hook pengumuman server")
do
  local ann = makeRemote(MOCK.RS, "AnnouncementEvent")
  A.indexRemotes()
  local n = A.hookAnnouncements()
  check("remote pengumuman ter-hook", n >= 1, n)

  P.announces = 0
  rawget(ann, "_p").OnClientEvent:Fire("Divine Kitsune Egg spawned at Cherry Blossom!")
  check("pengumuman Divine tertangkap", P.announces == 1, P.announces)
  check("rarity diambil dari teks", P.lastAnn and P.lastAnn.rar == "Divine",
    P.lastAnn and P.lastAnn.rar)

  rawget(ann, "_p").OnClientEvent:Fire("someone bought a trail")
  check("teks tanpa rarity tidak dihitung", P.announces == 1, P.announces)
  ann.Parent = nil
end

sect("29. pengamat mati = tidak ada tebakan")
do
  P.watch = false
  P.resetTimes = {}; P.counts = {}; P.observed = 0
  P.period = nil; P.lastReset = nil; P.sig = nil
  spawnSet({ { "KitsuneEgg", "Divine", "Spirit Bloom", 400, 3240000 } })
  stepScheduler(40, 1.0)
  check("pengamat mati → tidak ada reset tercatat", P.observed == 0, P.observed)
  check("pengamat mati → periode tetap nil", P.period == nil, P.period)
  local left = A.nextResetIn()
  check("tanpa data → hitung mundur nil (bukan angka palsu)", left == nil, left)

  -- pulihkan dunia untuk tes lain
  spawnSet({
    { "ChickenEgg", "Common", nil, 120, 120 },
    { "DodoEgg", "Rare", nil, 200, 4000 },
    { "LavaIguanaEgg", "Legendary", "Silver", 260, 25000 },
    { "StagEgg", "Secret", nil, 300, 900000 },
    { "OniTigerEgg", "Eternal", "Bloom", 340, 1500000 },
    { "KitsuneEgg", "Divine", "Spirit Bloom", 380, 3240000 },
    { "MysteryEgg", nil, nil, 410, nil },
  })
  check("dunia dipulihkan (7 telur)", #A.scanEggs() == 7, #A.scanEggs())
end

sect("30. auto kejar telur langka")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  hrp.Position = Vector3.new(0, 0, 0)
  for _, r in pairs(R) do rawget(r, "_p")._fired = nil end

  P.watch = true
  P.autoGo = true
  P.notify = { Divine = true }
  A.S.stealOn = false
  A.S.speed = 400
  A.S.returnBase = true
  A.S.antiTrap = false
  A.S.antiBat = false

  stepScheduler(400, 0.05)

  P.autoGo = false
  P.watch = false
  A.stopGlide()

  check("auto kejar menembak remote steal", rawget(R.steal, "_p")._fired ~= nil,
    rawget(R.steal, "_p")._fired)
  -- telur Divine di sekitar x=400; toleransi longgar karena auto-kejar bisa
  -- sudah menyelesaikan perjalanan pulang saat scheduler berhenti
  check("karakter bergerak dari titik awal", math.abs(hrp.Position.X) > 5,
    hrp.Position.X)
  check("status menyebut 'kejar' atau selesai",
    tostring(A.S.status):find("kejar") ~= nil or tostring(A.S.status):find("selesai") ~= nil,
    A.S.status)
end
