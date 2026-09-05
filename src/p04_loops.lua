-- ============ LOOP: STEAL EGG ============
task.spawn(function()
  while true do
    task.wait(S.stealDelay)
    if S.stealOn and alive() then
      local ok, err = pcall(function()
        local e = pickEgg()
        if not e then
          S.status = "nunggu telur cocok"
          return
        end

        local tag = (e.rar or "?")
        if e.pet then tag = tag .. " " .. e.pet end
        if e.mut then tag = e.mut .. " " .. tag end

        S.status = "jalan ke " .. tag
        -- kecepatan steal punya slider sendiri
        walkTo(e.pos, 25, S.stealSpeed)
        if not S.stealOn then S.status = "dibatalkan"; return end

        -- ambil: prompt + touch + remote
        pressPromptsNear(26)
        local p = partOf(e.obj)
        if p then touchPart(p) end
        fireMatch({ "steal", "pickup", "grabegg", "takeegg", "collectegg" }, e.obj)
        task.wait(0.4)
        if not S.stealOn then S.status = "dibatalkan"; return end

        if S.returnBase then
          local b = myBase()
          if b then
            S.status = "bawa pulang " .. tag
            walkTo(b, 35, S.stealSpeed)
            if not S.stealOn then S.status = "dibatalkan"; return end
            pressPromptsNear(26)
            fireMatch({ "deposit", "deliver", "placeegg", "storeegg", "submit" }, e.obj)
          end
        end

        S.stolen = S.stolen + 1
        S.lastEgg = tag .. (e.income and (" · " .. money(e.income * (e.mult or 1))) or "")
        S.status = "selesai #" .. S.stolen
      end)
      if not ok then S.status = "error: " .. tostring(err):sub(1, 40) end
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

-- treadmill: kalau tak ada remote train, jalan ke treadmill (bukan teleport)
task.spawn(function()
  while true do
    task.wait(6)
    if S.autoTrain and alive() and not S.stealOn then
      pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
          if (v:IsA("BasePart") or v:IsA("Model")) and lower(v.Name):find("treadmill") then
            local p = posOf(v)
            if p and hrp() and dist(hrp().Position, p) > 12 then
              walkTo(p, 20)
            end
            pressPromptsNear(20)
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

      -- jangan ganggu WalkSpeed saat walkTo sedang mengatur kecepatan steal
      if not moving then
        if S.speedOn then
          h.WalkSpeed = math.clamp(S.speed, 8, 1000)
        elseif h.WalkSpeed > 40 then
          h.WalkSpeed = 16
        end
      end

      -- PlatformStand tidak boleh pernah nyangkut true: itu yang bikin
      -- karakter tampak jatuh-jatuh setelah bergerak
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
      bb.Size = UDim2.new(0, 190, 0, 16 * #lines + 6)
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
        local minIdx = S.espMinRarity
        for _, e in ipairs(scanEggs()) do
          local d = dist(h.Position, e.pos)
          if d <= S.espRange then
            local idx = 0
            if e.rar then
              for i, r in ipairs(RARITY) do if r == e.rar then idx = i break end end
            end
            -- telur tanpa rarity tetap ditampilkan kalau ambang di posisi 1
            if idx >= minIdx or (idx == 0 and minIdx <= 1) then
              local col = (e.rar and RCOLOR[e.rar]) or Color3.fromRGB(190, 195, 205)

              -- baris 1: rarity + nama pet
              local head = e.rar or "Egg"
              if e.pet then head = head .. " · " .. e.pet end
              if e.mut then head = e.mut .. " " .. head end

              -- baris 2: income (dengan pengali mutasi kalau ada)
              local l2
              if e.income then
                local base = money(e.income)
                if e.mut and (e.mult or 1) > 1 then
                  l2 = money(e.income * e.mult) .. "  (" .. base .. " ×" .. e.mult .. ")"
                else
                  l2 = base
                end
              else
                l2 = "income belum diketahui"
              end

              -- baris 3: biome, berat, jarak
              local bits = {}
              if e.biome then bits[#bits + 1] = e.biome end
              local w = kg(e.wt)
              if w then bits[#bits + 1] = w end
              bits[#bits + 1] = math.floor(d) .. "m"

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
            tagBox(m.obj, Color3.fromRGB(255, 160, 60),
              { string.upper(m.kind), math.floor(d) .. "m" })
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
