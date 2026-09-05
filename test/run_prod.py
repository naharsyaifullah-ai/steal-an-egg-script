#!/usr/bin/env python3
"""Production-mode check: load the script WITHOUT the SAE_TEST flag and prove
that (a) it still runs clean, (b) it leaks no SAE global into the game env."""
import pathlib, re, subprocess, sys

SAE = pathlib.Path("/root/sae")
LUAU = "/tmp/luaubin/luau"
BUILT = pathlib.Path("/root/sae/sae.lua")
BUNDLE = pathlib.Path("/tmp/sae_prod_bundle.lua")

parts = [
    "-- PRODUCTION MODE BUNDLE (no SAE_TEST flag)\n",
    (SAE / "test/mock_env.lua").read_text(),
    (SAE / "test/mock_services.lua").read_text(),
    (SAE / "test/world.lua").read_text(),
    "\n-- ===== SCRIPT UNDER TEST =====\n",
    BUILT.read_text(),
    """
-- ===== PRODUCTION ASSERTIONS =====
sect("P. mode produksi (tanpa flag test)")
local env = getfenv(0)
check("tidak ada global SAE yang bocor",
  rawget(env, "SAE") == nil, tostring(rawget(env, "SAE")))
check("loop tetap terdaftar", spawnedCount() >= 5, spawnedCount())
check("GUI tetap terbentuk", MOCK.CoreGui:FindFirstChild("SAE_Hub_v2") ~= nil)

-- jalankan semua loop 10 detik tanpa satu pun fitur menyala:
-- tidak boleh ada error dan tidak boleh ada remote tertembak
for _, r in pairs(R) do rawget(r, "_p")._fired = nil end
local ok = pcall(function() stepScheduler(100, 0.1) end)
check("idle 10 detik tanpa error", ok == true)
local anyFired = false
for _, r in pairs(R) do if rawget(r, "_p")._fired then anyFired = true end end
check("tidak ada remote tertembak saat semua fitur OFF", anyFired == false)
REPORT()
""",
]
BUNDLE.write_text("\n".join(parts))
p = subprocess.run([LUAU, str(BUNDLE)], capture_output=True, text=True)
out = (p.stdout + p.stderr).rstrip()
print(out)
m = re.search(r"PASS (\d+)\s+FAIL (\d+)", out)
if not m:
    print("!! crashed before REPORT()")
    sys.exit(1)
sys.exit(1 if int(m.group(2)) else 0)
