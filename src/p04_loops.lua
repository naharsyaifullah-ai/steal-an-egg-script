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
        S.status = "menuju " .. (e.rar or "?") .. (e.mut and (" " .. e.mut) or "")
        glideTo(e.pos, 20)
        -- toggle bisa dimatikan saat masih di tengah jalan: batalkan sisa langkah
        -- supaya tidak ada remote yang tertembak setelah user menekan OFF
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
            S.status = "bawa pulang"
            glideTo(b, 30)
            if not S.stealOn then S.status = "dibatalkan"; return end
            pressPromptsNear(26)
            fireMatch({ "deposit", "deliver", "placeegg", "storeegg", "submit" }, e.obj)
          end
        end

        S.stolen = S.stolen + 1
        S.lastEgg = (e.rar or "?") .. (e.mut and (" " .. e.mut) or "")
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

-- treadmill: kalau tak ada remote train, berdiri di treadmill (bukan TP jauh)
task.spawn(function()
  while true do
    task.wait(6)
    if S.autoTrain and alive() and not S.stealOn then
      pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
          if (v:IsA("BasePart") or v:IsA("Model")) and lower(v.Name):find("treadmill") then
            local p = posOf(v)
            if p and hrp() and dist(hrp().Position, p) > 12 then
              glideTo(p, 15)
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
      if S.speedOn then
        h.WalkSpeed = math.clamp(S.speed, 16, 1000)
      elseif h.WalkSpeed > 40 then
        h.WalkSpeed = 16
      end
      if S.antiStun then
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if h.PlatformStand and not moving then h.PlatformStand = false end
        h.Sit = false
      end
      if S.noFall then
        h:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        local hp = hrp()
        if hp and hp.Velocity.Y < -120 then
          hp.Velocity = Vector3.new(hp.Velocity.X, -20, hp.Velocity.Z)
        end
      end
    end)
  end
end)

-- anti-bat pasif: kalau musuh terlalu dekat & tidak sedang gerak, mundur
task.spawn(function()
  while true do
    task.wait(0.4)
    if (S.antiBat or S.antiTrap) and alive() and not moving then
      pcall(function()
        local h = hrp(); if not h then return end
        local push = Vector3.zero
        if S.antiBat then
          for _, m in ipairs(scanHostiles()) do
            local d = h.Position - m.pos
            if d.Magnitude < 14 then push = push + d.Unit end
          end
        end
        if S.antiTrap then
          for _, t in ipairs(scanTraps()) do
            local d = h.Position - t.pos
            if d.Magnitude < 12 then push = push + d.Unit end
          end
        end
        if push.Magnitude > 0 then
          local bv = Instance.new("BodyVelocity")
          bv.MaxForce = Vector3.new(1e5, 0, 1e5)
          bv.Velocity = push.Unit * 55
          bv.Parent = h
          task.wait(0.18)
          bv:Destroy()
        end
      end)
    end
  end
end)

-- ============ ESP ============
local espF = Instance.new("Folder")
espF.Name = "SAE_ESP"
espF.Parent = CoreGui

local function tagBox(inst, color, label)
  local adornee = inst:IsA("Model") and inst or inst
  local hl = Instance.new("Highlight")
  hl.Adornee = adornee
  hl.FillColor = color
  hl.OutlineColor = color
  hl.FillTransparency = 0.65
  hl.OutlineTransparency = 0
  hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  hl.Parent = espF

  if label then
    local p = partOf(inst)
    if p then
      local bb = Instance.new("BillboardGui")
      bb.Adornee = p
      bb.Size = UDim2.new(0, 150, 0, 20)
      bb.StudsOffset = Vector3.new(0, 2.4, 0)
      bb.AlwaysOnTop = true
      bb.Parent = espF
      local tl = Instance.new("TextLabel")
      tl.Size = UDim2.new(1, 0, 1, 0)
      tl.BackgroundTransparency = 1
      tl.Text = label
      tl.Font = Enum.Font.GothamBold
      tl.TextSize = 12
      tl.TextColor3 = color
      tl.TextStrokeTransparency = 0.4
      tl.Parent = bb
    end
  end
end

task.spawn(function()
  while true do
    task.wait(2.5)
    pcall(function()
      espF:ClearAllChildren()
      local h = hrp(); if not h then return end

      if S.espEgg then
        for _, e in ipairs(scanEggs()) do
          if dist(h.Position, e.pos) < 3000 then
            local col = (e.rar and RCOLOR[e.rar]) or Color3.fromRGB(200, 200, 200)
            local lbl = (e.rar or "Egg")
            if e.mut then lbl = e.mut .. " " .. lbl end
            if e.wt > 0 then lbl = lbl .. " · " .. string.format("%.0fkg", e.wt) end
            lbl = lbl .. " · " .. math.floor(dist(h.Position, e.pos)) .. "m"
            tagBox(e.obj, col, lbl)
          end
        end
      end
      if S.espTrap then
        for _, t in ipairs(scanTraps()) do
          if dist(h.Position, t.pos) < 900 then tagBox(t.obj, Color3.fromRGB(255, 90, 90), "TRAP") end
        end
      end
      if S.espGuard then
        for _, m in ipairs(scanHostiles()) do
          if dist(h.Position, m.pos) < 1200 then
            tagBox(m.obj, Color3.fromRGB(255, 160, 60), string.upper(m.kind))
          end
        end
      end
      if S.espPlayer then
        for _, pl in ipairs(Players:GetPlayers()) do
          if pl ~= LP and pl.Character then
            local pp = pl.Character:FindFirstChild("HumanoidRootPart")
            if pp then
              tagBox(pl.Character, Color3.fromRGB(90, 200, 255),
                pl.Name .. " · " .. math.floor(dist(h.Position, pp.Position)) .. "m")
            end
          end
        end
      end
    end)
  end
end)
