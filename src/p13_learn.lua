-- ============ PEMANTAU BELAJAR OTOMATIS ============
-- Menyalakan rekaman lalu menunggu pengguna mengambil satu telur dengan tangan
-- sendiri. Begitu ada telur yang benar-benar berpindah ke karakter (atau hilang
-- saat pengguna berdiri di sisinya), rekaman terakhir dipakai sebagai resep.

local LEARN = {
  active   = false,
  started  = nil,
  watching = {},          -- obj -> {pos, t}
  done     = false,
}

local function snapshotNearby()
  local h = hrp(); if not h then return end
  LEARN.watching = {}
  for _, e in ipairs(scanEggs()) do
    if not e.mine and dist(h.Position, e.pos) < 120 then
      LEARN.watching[e.obj] = { pos = e.pos, t = tick() }
    end
  end
end

function startLearning()
  local ok = SPY.install()
  SPY.recording = true
  SPY.log = {}
  SPY.prompts = {}
  SPY.fires = 0
  LEARN.active = true
  LEARN.done = false
  LEARN.started = tick()
  snapshotNearby()
  S.status = ok and "MODE BELAJAR: ambil 1 telur manual"
    or "hook gagal — masih bisa belajar dari prompt/sentuhan"
  return ok
end

function stopLearning()
  LEARN.active = false
  SPY.recording = false
  S.status = "mode belajar berhenti"
end

-- pantau: apakah salah satu telur yang diawasi kini terbawa pengguna?
task.spawn(function()
  while true do
    task.wait(0.35)
    if LEARN.active and alive() then
      pcall(function()
        local h = hrp(); if not h then return end
        local c = char()

        for obj, info in pairs(LEARN.watching) do
          local taken = false

          if not obj.Parent then
            -- hilang: hanya dihitung kalau pengguna sedang di sisinya
            if dist(h.Position, info.pos) < 18 then taken = true end
          else
            local p = obj.Parent
            while p do
              if p == c then taken = true break end
              p = p.Parent
            end
            -- atau telur ikut bergerak bersama pemain (dibawa)
            if not taken then
              local np = posOf(obj)
              if np and (np - info.pos).Magnitude > 12 and dist(h.Position, np) < 14 then
                taken = true
              end
            end
          end

          if taken then
            SPY.learnFrom(obj, LEARN.started)
            -- v6: resep langsung ditulis ke berkas — AJARI cukup sekali,
            -- sesi berikutnya memuatnya otomatis
            pcall(function()
              if SPY.saveRecipe() then
                SPY.note = SPY.note .. " · tersimpan di berkas"
              end
            end)
            SPY.lastPickup = tostring(obj.Name)
            LEARN.active = false
            LEARN.done = true
            SPY.recording = false
            S.status = "TERPELAJARI: " .. SPY.note:sub(1, 46)
            return
          end
        end

        -- perbarui daftar awasan tiap 3 detik supaya telur baru ikut terpantau
        if tick() - (LEARN.lastSnap or 0) > 3 then
          LEARN.lastSnap = tick()
          local h2 = hrp()
          if h2 then
            for _, e in ipairs(scanEggs()) do
              if not e.mine and not LEARN.watching[e.obj]
                and dist(h2.Position, e.pos) < 120 then
                LEARN.watching[e.obj] = { pos = e.pos, t = tick() }
              end
            end
          end
        end
      end)
    end
  end
end)
