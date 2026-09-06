-- ============ AMBIL TELUR: banyak cara, dicoba berurutan ============
-- Penyebab "steal ga ke-steal": v3 hanya menembak prompt + touch sekali lalu
-- langsung pergi. Sekarang: dekati sampai benar-benar dekat, tekan prompt di
-- dalam objek telur itu sendiri, sentuh SEMUA part-nya, tembak remote dengan
-- beberapa bentuk argumen, lalu VERIFIKASI apakah telur benar-benar terbawa.

local function promptsInside(obj, radius)
  local h = hrp(); if not h then return 0 end
  local n = 0
  for _, p in ipairs(obj:GetDescendants()) do
    if p:IsA("ProximityPrompt") then
      pcall(function()
        p.Enabled = true
        p.MaxActivationDistance = math.max(p.MaxActivationDistance or 0, 80)
        p.RequiresLineOfSight = false
        p.HoldDuration = 0
        fireproximityprompt(p)
      end)
      n = n + 1
    end
  end
  if obj:IsA("ProximityPrompt") then
    pcall(function() fireproximityprompt(obj) end)
    n = n + 1
  end
  return n
end

local function touchAllParts(obj)
  local h = hrp(); if not h then return 0 end
  local n = 0
  local parts = {}
  if obj:IsA("BasePart") then parts[1] = obj end
  for _, d in ipairs(obj:GetDescendants()) do
    if d:IsA("BasePart") then parts[#parts + 1] = d end
  end
  for _, p in ipairs(parts) do
    pcall(function()
      firetouchinterest(h, p, 0)
      firetouchinterest(h, p, 1)
      firetouchinterest(h, p, 0)
      firetouchinterest(h, p, 1)
      n = n + 1
    end)
  end
  return n
end

-- Apakah telur BENAR-BENAR terbawa? Kedekatan posisi BUKAN bukti — berdiri di
-- sebelah telur tidak berarti memegangnya, dan itulah yang membuat v3 mengaku
-- berhasil lalu pulang dengan tangan kosong. Bukti yang diterima hanya:
--   a) telur menjadi keturunan karakter kita, atau
--   b) telur di-weld ke HumanoidRootPart kita, atau
--   c) telur hilang dari dunia SAAT kita berdiri di sisinya (<16 stud)
-- `nearDist` = jarak kita ke telur pada percobaan terakhir.
local function heldByMe(obj, nearDist)
  local c = char(); if not c then return false end
  local h = hrp()

  if not obj.Parent then
    return (nearDist ~= nil) and (nearDist < 16)
  end

  local p = obj.Parent
  while p do
    if p == c then return true end
    p = p.Parent
  end

  if h then
    for _, d in ipairs(obj:GetDescendants()) do
      if d:IsA("WeldConstraint") or d:IsA("Weld") then
        local ok = false
        pcall(function()
          if d.Part0 == h or d.Part1 == h then ok = true end
        end)
        if ok then return true end
      end
    end
  end
  return false
end

-- satu percobaan ambil penuh.
-- Urutan penting: kalau cara ambil sudah DIPELAJARI dari rekaman nyata, itu
-- yang dipakai lebih dulu. Tebakan nama remote hanya cadangan terakhir, dan
-- hanya kalau S.blindFire menyala — menembak remote secara buta bisa memicu
-- anti-cheat dan itu yang gagal di v3/v4.
local function grabAttempt(e)
  local acts = 0

  -- 1. selalu: prompt di dalam telur + SmartPromptPart (pusat prompt game ini)
  --    + prompt lain yang dekat + sentuh semua part (cara pemain asli)
  acts = acts + promptsInside(e.obj, 26)
  acts = acts + fireSmartPrompts()
  acts = acts + pressPromptsNear(30)
  acts = acts + touchAllParts(e.obj)

  -- 2. resep hasil belajar
  if SPY and SPY.learned then
    if SPY.replay(e.obj) then acts = acts + 1 end
    return acts
  end

  -- 3. kalau yang dipelajari adalah "prompt saja" atau "sentuhan saja",
  --    jangan menembak remote apa pun
  if SPY and (SPY.learnedFrom == "prompt" or SPY.learnedFrom == "touch") then
    return acts
  end

  -- 4. cadangan tebakan (bisa dimatikan)
  if S.blindFire then
    local words = { "steal", "pickup", "pick", "grab", "take", "collect", "carry", "hold" }
    fireMatch(words, e.obj)
    fireMatch(words, e.obj.Name)
    fireMatch(words)
    acts = acts + 1
  end
  return acts
end

-- ============ LOOP: STEAL EGG ============
task.spawn(function()
  while true do
    task.wait(S.stealDelay)
    if S.stealOn and alive() then
      local ok, err = pcall(function()
        local e = pickEgg()
        if not e then
          -- jujur soal kenapa tidak ada target: peta kosong, filter, atau
          -- semua telur memang di base pemain lain (bukan sasaran default)
          local wild, total = 0, 0
          for _, x in ipairs(scanEggs()) do
            if not x.mine then
              total = total + 1
              if not x.owned then wild = wild + 1 end
            end
          end
          S.status = (total > 0 and wild == 0)
            and "semua telur di base pemain — nyalakan toggle 'Ambil dari base pemain' kalau mau"
            or "nunggu telur cocok"
          return
        end

        local tag = (e.rar or "?")
        if e.pet then tag = tag .. " " .. e.pet end
        if e.mut then tag = e.mut .. " " .. tag end

        -- 1. dekati sampai benar-benar dekat, bukan cuma "kira-kira sampai"
        S.status = "menuju " .. tag
        moveTo(e.pos, 25, S.stealSpeed)
        if not S.stealOn then S.status = "dibatalkan"; return end

        -- 2. koreksi jarak: benar-benar sampai di sisi telur, bukan "kira-kira".
        -- Jarak yang terlalu jauh adalah penyebab paling umum prompt/sentuhan
        -- tidak berefek sama sekali.
        for _ = 1, 3 do
          local h = hrp()
          if not (h and e.obj.Parent) then break end
          local now = posOf(e.obj) or e.pos
          local d = dist(h.Position, now)
          if d <= S.approachDist then break end
          moveTo(now, 10, S.stealSpeed)
        end

        -- 3. usaha ambil beberapa kali, berhenti begitu terbukti terbawa
        local got = false
        for i = 1, math.max(1, S.grabTries) do
          if not S.stealOn then S.status = "dibatalkan"; return end

          local hh = hrp()
          local ep = posOf(e.obj)
          local dNow = (hh and ep) and dist(hh.Position, ep) or nil

          -- kalau telur sudah hilang sebelum kita sempat menyentuh, itu bukan
          -- keberhasilan kita — kecuali kita memang sedang berdiri di sisinya
          if not e.obj.Parent then
            got = heldByMe(e.obj, dNow)
            break
          end

          grabAttempt(e)
          task.wait(0.35)

          local hh2 = hrp()
          local ep2 = posOf(e.obj)
          local d2 = (hh2 and ep2) and dist(hh2.Position, ep2) or dNow
          if heldByMe(e.obj, d2) then got = true break end

          local cur = posOf(e.obj)
          if cur then moveTo(cur, 4, S.stealSpeed) end
        end

        S.lastGrab = got and ("berhasil: " .. tag) or ("gagal ambil: " .. tag)
        if not got then
          S.fails = S.fails + 1
          S.status = "gagal ambil, cari yang lain"
          return                      -- JANGAN pulang kalau tangan kosong
        end

        -- 4. baru pulang setelah telur benar-benar terbawa
        if S.returnBase then
          local b = myBase()
          if b then
            S.status = "bawa pulang " .. tag
            moveTo(b, 35, S.stealSpeed)
            if not S.stealOn then S.status = "dibatalkan"; return end
            pressPromptsNear(30)
            fireMatch({ "deposit", "deliver", "place", "store", "submit", "drop" }, e.obj)
            fireMatch({ "deposit", "deliver", "place", "store", "submit", "drop" })
            task.wait(0.3)
          end
        end

        S.stolen = S.stolen + 1
        S.lastEgg = tag .. (e.income and (" · " .. (money(e.income * (e.mult or 1)) or "?")) or "")
        S.status = "selesai #" .. S.stolen
      end)
      if not ok then
        S.fails = S.fails + 1
        S.status = "error: " .. tostring(err):sub(1, 44)
      end
    end
  end
end)

-- ============ LOOP: FARM ============
task.spawn(function()
  while true do
    task.wait(2.2)
    if alive() then
      pcall(function()
        if S.autoHatch   then fireMatch({ "hatch", "openegg", "incubat" }) end
        if S.autoClaim   then fireMatch({ "claim", "collectmoney", "collectcash", "collectincome" }) end
        if S.autoTrain   then fireMatch({ "train", "treadmill", "speedtrain" }) end
        if S.autoSell    then fireMatch({ "sellpet", "sell" }) end
        if S.autoUpgrade then fireMatch({ "upgrade", "buyupgrade", "levelup" }) end
      end)
    end
  end
end)

task.spawn(function()
  while true do
    task.wait(6)
    if S.autoTrain and alive() and not S.stealOn then
      pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
          if (v:IsA("BasePart") or v:IsA("Model")) and lower(v.Name):find("treadmill") then
            local p = posOf(v)
            if p and hrp() and dist(hrp().Position, p) > 12 then moveTo(p, 20) end
            pressPromptsNear(24)
            break
          end
        end
      end)
    end
  end
end)

-- ============ PLAYER: speed, anti stun, no fall ============
task.spawn(function()
  while true do
    task.wait(0.25)
    pcall(function()
      local h = hum()
      if not h then return end

      -- jangan ganggu WalkSpeed saat gerak sedang mengatur kecepatan
      if not moving then
        if S.speedOn then
          h.WalkSpeed = math.clamp(S.speed, 8, 1000)
        elseif h.WalkSpeed > 40 then
          h.WalkSpeed = 16
        end
      end

      -- PlatformStand tidak boleh pernah nyangkut true
      if h.PlatformStand and not moving then h.PlatformStand = false end

      if S.antiStun then
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        h.Sit = false
      end
      if S.noFall then
        local hp = hrp()
        if hp and hp.Velocity.Y < -120 then
          hp.Velocity = Vector3.new(hp.Velocity.X, -20, hp.Velocity.Z)
        end
      end
    end)
  end
end)

-- ============ ESP ============
local espF = Instance.new("Folder")
espF.Name = "SAE_ESP"
espF.Parent = CoreGui

local function tagBox(inst, color, lines)
  local hl = Instance.new("Highlight")
  hl.Adornee = inst
  hl.FillColor = color
  hl.OutlineColor = color
  hl.FillTransparency = 0.62
  hl.OutlineTransparency = 0
  hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  hl.Parent = espF

  if lines and #lines > 0 then
    local p = partOf(inst)
    if p then
      local bb = Instance.new("BillboardGui")
      bb.Adornee = p
      bb.Size = UDim2.new(0, 200, 0, 16 * #lines + 6)
      bb.StudsOffset = Vector3.new(0, 2.8, 0)
      bb.AlwaysOnTop = true
      bb.Parent = espF
      local ll = Instance.new("UIListLayout")
      ll.Parent = bb
      for i, ln in ipairs(lines) do
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 0, 16)
        tl.BackgroundTransparency = 1
        tl.Text = ln
        tl.Font = (i == 1) and Enum.Font.GothamBold or Enum.Font.Code
        tl.TextSize = (i == 1) and 13 or 11
        tl.TextColor3 = (i == 1) and color or Color3.fromRGB(225, 232, 242)
        tl.TextStrokeTransparency = 0.25
        tl.Parent = bb
      end
    end
  end
end

task.spawn(function()
  while true do
    task.wait(2)
    pcall(function()
      espF:ClearAllChildren()
      local h = hrp(); if not h then return end

      if S.espEgg then
        for _, e in ipairs(scanEggs()) do
          local d = dist(h.Position, e.pos)
          if d <= S.espRange then
            local idx = 0
            if e.rar then
              for i, r in ipairs(RARITY) do if r == e.rar then idx = i break end end
            end
            local show
            if idx == 0 then show = S.espUnknown else show = (idx >= S.espMinRarity) end
            if show then
              local col = (e.rar and RCOLOR[e.rar]) or Color3.fromRGB(190, 195, 205)

              -- baris 1: mutasi + rarity + nama pet
              local head
              if e.pet then
                head = (e.rar or "?") .. " · " .. e.pet
              elseif e.rar then
                head = e.rar
              else
                -- nama slot game ini adalah UUID — tampilkan label yang bisa
                -- dibaca, bukan deretan huruf acak
                local nm = tostring(e.obj.Name)
                if #nm == 32 and nm:match("^%x+$") then nm = "Telur zona" end
                head = nm:gsub("_", " ")
              end
              if e.mut then head = e.mut .. " " .. head end

              -- baris 2: income
              local l2
              if e.income then
                local base = money(e.income)
                if e.mut and (e.mult or 1) > 1 then
                  l2 = (money(e.income * e.mult) or "?") .. "  (" .. base .. " ×" .. e.mult .. ")"
                else
                  l2 = base
                end
              elseif e.rar then
                l2 = e.rar .. " · income tak dipublikasikan"
              else
                l2 = "pet belum ada di database"
              end

              -- baris 3: biome, berat, jarak
              local bits = {}
              if e.rare then bits[#bits + 1] = "RARE" end
              if e.kind == "parasite" then bits[#bits + 1] = "PARASIT" end
              if e.owned and not e.mine then bits[#bits + 1] = "MILIK PEMAIN" end
              if e.biome then bits[#bits + 1] = e.biome end
              local w = kg(e.wt)
              if w then bits[#bits + 1] = w end
              bits[#bits + 1] = math.floor(d) .. "m"
              if e.mine then bits[#bits + 1] = "MILIKKU" end

              tagBox(e.obj, col, { head, l2, table.concat(bits, " · ") })
            end
          end
        end
      end

      if S.espTrap then
        for _, t in ipairs(scanTraps()) do
          local d = dist(h.Position, t.pos)
          if d < 900 then tagBox(t.obj, Color3.fromRGB(255, 90, 90), { "TRAP", math.floor(d) .. "m" }) end
        end
      end
      if S.espGuard then
        for _, m in ipairs(scanHostiles()) do
          local d = dist(h.Position, m.pos)
          if d < 1200 then
            tagBox(m.obj, Color3.fromRGB(255, 160, 60), { string.upper(m.kind), math.floor(d) .. "m" })
          end
        end
      end
      if S.espPlayer then
        for _, pl in ipairs(Players:GetPlayers()) do
          if pl ~= LP and pl.Character then
            local pp = pl.Character:FindFirstChild("HumanoidRootPart")
            if pp then
              tagBox(pl.Character, Color3.fromRGB(90, 200, 255),
                { pl.Name, math.floor(dist(h.Position, pp.Position)) .. "m" })
            end
          end
        end
      end
    end)
  end
end)
