-- ---- t_04_remote.lua ----
local A = SAE

sect("8. remote: indeks & tembakan tepat sasaran")
do
  local n = A.indexRemotes()
  check("remote terindeks (8)", n == 8, n)

  local function fired(r) return rawget(r, "_p")._fired end

  local hit = A.fireMatch({ "steal" })
  check("fireMatch('steal') kena tepat 1 remote", hit == 1, hit)
  check("StealEgg benar di-FireServer", fired(R.steal) == 1, fired(R.steal))
  check("remote tak relevan tidak ditembak", fired(R.noise) == nil, fired(R.noise))

  A.fireMatch({ "hatch" })
  check("HatchEgg tertembak", fired(R.hatch) == 1, fired(R.hatch))

  A.fireMatch({ "claim" })
  check("ClaimMoney tertembak", fired(R.claim) == 1, fired(R.claim))

  A.fireMatch({ "train", "treadmill" })
  check("TrainTreadmill tertembak sekali walau 2 kata cocok",
    fired(R.train) == 1, fired(R.train))

  A.fireMatch({ "sell" })
  check("RemoteFunction SellPet di-InvokeServer", fired(R.sell) == 1, fired(R.sell))

  -- regresi: '...' di dalam closure pcall pernah bikin SyntaxError
  local ref = { tag = "eggref" }
  A.fireMatch({ "deposit" }, ref)
  local la = rawget(R.deposit, "_p")._lastArgs
  check("argumen diteruskan utuh ke remote", la and la.n == 1 and la[1] == ref, la and la.n)

  local miss = A.fireMatch({ "tidakadaremoteini" })
  check("kata tanpa kecocokan → 0 tembakan", miss == 0, miss)
end

sect("9. ProximityPrompt: hanya yang dekat")
do
  local hrp = CHR:FindFirstChild("HumanoidRootPart")
  local before = PROMPT_FIRED

  hrp.Position = Vector3.new(380, 0, 0)   -- prompt ada di 381
  local n1 = A.pressPromptsNear(26)
  check("prompt dekat ditekan", n1 >= 1, n1)
  check("counter executor naik", PROMPT_FIRED > before, PROMPT_FIRED)

  hrp.Position = Vector3.new(0, 0, 0)     -- jauh dari kedua prompt
  local n2 = A.pressPromptsNear(26)
  check("prompt jauh (5000 stud) tidak ditekan", n2 == 0, n2)
end

sect("10. ESP: highlight & label")
do
  A.S.espEgg = true
  A.S.espTrap = true
  A.S.espGuard = true
  A.S.espPlayer = true
  CHR:FindFirstChild("HumanoidRootPart").Position = Vector3.new(300, 0, 0)

  stepScheduler(40, 0.1)   -- biarkan loop ESP jalan

  local kids = A.espFolder:GetChildren()
  local hl, bb = 0, 0
  for _, k in ipairs(kids) do
    if k.ClassName == "Highlight" then hl = hl + 1 end
    if k.ClassName == "BillboardGui" then bb = bb + 1 end
  end
  check("ESP membuat Highlight", hl > 0, hl)
  check("ESP membuat label BillboardGui", bb > 0, bb)
  -- 7 telur + 2 trap + 3 musuh + 2 pemain = 14 objek maksimal
  check("jumlah highlight wajar (≤14)", hl <= 14, hl)

  local texts = {}
  for _, k in ipairs(kids) do
    if k.ClassName == "BillboardGui" then
      local tl = k:FindFirstChildOfClass("TextLabel")
      if tl then texts[#texts + 1] = tl.Text end
    end
  end
  local blob = table.concat(texts, " ~ ")
  check("label memuat nama rarity", blob:find("Divine") ~= nil or blob:find("Secret") ~= nil, blob:sub(1, 90))
  check("label memuat TRAP", blob:find("TRAP") ~= nil, blob:sub(1, 90))
  check("label memuat jarak (m)", blob:find("m") ~= nil)

  A.S.espEgg = false; A.S.espTrap = false
  A.S.espGuard = false; A.S.espPlayer = false
  stepScheduler(40, 0.1)
  check("ESP mati → folder dibersihkan", #A.espFolder:GetChildren() == 0,
    #A.espFolder:GetChildren())
end
