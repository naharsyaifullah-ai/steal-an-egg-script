#!/usr/bin/env python3
"""Bundle mock env + built script + assertions into one Luau file and run it.

The luau CLI has no dofile/loadfile/io, so everything must be a single chunk.
Exit code is derived from the printed FAIL count.
"""
import pathlib, re, subprocess, sys

SAE = pathlib.Path("/root/sae")
LUAU = "/tmp/luaubin/luau"
BUILT = pathlib.Path("/root/sae/sae.lua")
BUNDLE = pathlib.Path("/tmp/sae_test_bundle.lua")

# rebuild the product first
r = subprocess.run([sys.executable, str(SAE / "build.py")], capture_output=True, text=True)
print(r.stdout.strip())
if r.returncode != 0:
    print(r.stderr)
    sys.exit(1)

harness_pre = SAE / "test/mock_env.lua"
harness_svc = SAE / "test/mock_services.lua"
world = SAE / "test/world.lua"
asserts = sorted((SAE / "test").glob("t_*.lua"))

parts = [
    "-- AUTO-GENERATED TEST BUNDLE, do not edit\n",
    "SAE_TEST = true\n",
    harness_pre.read_text(),
    harness_svc.read_text(),
    world.read_text(),
    "\n-- ===== SCRIPT UNDER TEST =====\n",
    "-- do-end memberi scope sendiri supaya local-register Luau (maks 200)\n",
    "-- tidak meledak ketika script dan harness digabung.\n",
    "do\n",
    BUILT.read_text(),
    "\nend -- script under test\n",
    "\n-- ===== ASSERTIONS =====\n",
]
# Each assertion file gets its own do...end scope: Luau allows only 200 locals
# per function, and the bundled top level blew past that as the suite grew.
for a in asserts:
    parts.append(f"\ndo -- ---- {a.name} ----\n")
    parts.append(a.read_text())
    parts.append(f"\nend -- {a.name}\n")
parts.append("\nREPORT()\n")

BUNDLE.write_text("\n".join(parts))
print(f"bundle: {BUNDLE} {BUNDLE.stat().st_size} bytes")

p = subprocess.run([LUAU, str(BUNDLE)], capture_output=True, text=True)
out = (p.stdout + p.stderr).rstrip()
print(out)

m = re.search(r"PASS (\d+)\s+FAIL (\d+)", out)
if not m:
    print("\n!! no report line — the bundle crashed before REPORT()")
    sys.exit(1)
fails = int(m.group(2))
sys.exit(1 if fails else 0)
