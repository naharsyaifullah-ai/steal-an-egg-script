-- ---- t_00_load.lua ----
sect("0. muat & inisialisasi")
check("tabel ekspor tersedia", type(SAE) == "table", type(SAE))
check("loop background terdaftar", spawnedCount() >= 5, spawnedCount())
check("GUI dibuat di CoreGui", SAE.gui ~= nil and SAE.gui.Parent == MOCK.CoreGui)
check("4 tab terbentuk",
  SAE.tabs.STEAL and SAE.tabs.FARM and SAE.tabs.PLAYER and SAE.tabs.ESP)
check("halaman STEAL aktif saat awal",
  SAE.pages.STEAL.Visible == true and SAE.pages.FARM.Visible == false)
