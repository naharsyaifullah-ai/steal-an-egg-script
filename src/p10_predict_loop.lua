-- ============ LOOP PENGAMAT SIKLUS ============
-- Belajar periode reset dari perubahan nyata isi map, bukan dari angka hafalan.
task.spawn(function()
  -- ambil sidik jari awal supaya reset pertama tidak dihitung palsu
  local ok0 = pcall(function() PRED.sig = (eggSignature()) end)
  if not ok0 then PRED.sig = nil end

  while true do
    task.wait(1)
    if PRED.watch then
      pcall(function()
        PRED.liveTimer = findLiveTimer()

        local sig, eggs = eggSignature()

        -- reset terdeteksi kalau isi map berubah drastis (mirip < 35%)
        if PRED.sig and sig ~= PRED.sig then
          local sim = similarity(PRED.sig, sig)
          if sim < 0.35 and #eggs > 0 then
            local now = tick()
            -- tolak deteksi ganda dalam 20 detik (gemerlap render, bukan reset)
            if not PRED.lastReset or (now - PRED.lastReset) > 20 then
              PRED.lastReset = now
              table.insert(PRED.resetTimes, now)
              while #PRED.resetTimes > 40 do table.remove(PRED.resetTimes, 1) end
              PRED.period = computePeriod()
              PRED.observed = PRED.observed + 1

              -- catat rarity apa saja yang muncul di reset ini
              local seen = {}
              for _, e in ipairs(eggs) do
                if e.rar and not seen[e.rar] then
                  seen[e.rar] = true
                  PRED.counts[e.rar] = (PRED.counts[e.rar] or 0) + 1
                  PRED.seenNames[e.rar] = e.obj.Name
                end
              end

              -- alarm untuk rarity yang dipantau
              for _, e in ipairs(eggs) do
                if e.rar and PRED.notify[e.rar] then
                  pushAlert(e, "reset")
                end
              end
            end
          end
        end
        PRED.sig = sig

        -- deteksi instan: telur langka muncul di luar siklus reset
        for _, e in ipairs(eggs) do
          if e.rar and PRED.notify[e.rar] then
            local fresh = true
            for _, a in ipairs(PRED.alerts) do
              if a.name == e.obj.Name and (tick() - a.t) < 60 then fresh = false break end
            end
            if fresh then pushAlert(e, "muncul") end
          end
        end
      end)
    end
  end
end)

-- auto kejar telur langka begitu terdeteksi
task.spawn(function()
  while true do
    task.wait(1.5)
    if PRED.watch and PRED.autoGo and alive() and not S.stealOn then
      pcall(function()
        local target = nil
        for _, e in ipairs(scanEggs()) do
          if e.rar and PRED.notify[e.rar] then
            if not target or eggScore(e) > eggScore(target) then target = e end
          end
        end
        if target then
          S.status = "kejar " .. target.rar .. (target.mut and (" " .. target.mut) or "")
          glideTo(target.pos, 25)
          pressPromptsNear(26)
          local p = partOf(target.obj)
          if p then touchPart(p) end
          fireMatch({ "steal", "pickup", "grabegg", "takeegg", "collectegg" }, target.obj)
          task.wait(0.5)
          local b = myBase()
          if b and S.returnBase then
            glideTo(b, 30)
            pressPromptsNear(26)
            fireMatch({ "deposit", "deliver", "placeegg", "storeegg", "submit" }, target.obj)
          end
        end
      end)
    end
  end
end)
