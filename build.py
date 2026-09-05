#!/usr/bin/env python3
"""Assemble the Steal An Egg Delta script from src/ parts, then syntax-check it.

Order matters: helpers must be defined before the loops and UI that call them.
"""
import pathlib, subprocess, sys, shutil

ROOT = pathlib.Path(__file__).resolve().parent
SRC = ROOT / "src"
OUT = ROOT / "sae.lua"

PARTS = [
    "p01_head.lua",          # state, rarity table, mutations, colours
    "p00_db.lua",            # pet/egg database: rarity + income per second
    "p02_scan.lua",          # eggs / traps / hostiles / base detection
    "p03_move.lua",          # remote indexer + flat hover / ground walking
    "p12_spy.lua",           # remote spy: record the real pickup call
    "p09_predict.lua",       # cycle-prediction engine
    "p04_loops.lua",         # steal / farm / player loops
    "p13_learn.lua",         # learn-by-watching the user pick one egg
    "p10_predict_loop.lua",  # watcher loop + auto chase
    "p05_ui_base.lua",       # theme + window
    "p06_ui_comp.lua",       # toggle / slider / tab components
    "p07_ui_pages.lua",      # STEAL / FARM / PLAYER / ESP pages
    "p11_predict_ui.lua",    # PREDIKSI page
    "p08_export.lua",        # test hook (inert in production)
]

chunks = []
for name in PARTS:
    p = SRC / name
    if not p.exists():
        sys.exit(f"missing part: {p}")
    chunks.append(p.read_text())

body = "\n\n".join(chunks)
OUT.write_text(body)

lines = body.count("\n") + 1
print(f"written: {OUT} {len(body.encode())} bytes / {lines} lines")

# Real parser beats hand-rolled brace counting for Lua.
compiler = shutil.which("luau-compile") or "/tmp/luaubin/luau-compile"
if pathlib.Path(compiler).exists():
    # --binary emits bytecode on stdout: keep it as bytes (not text) and
    # discard it, or Python chokes decoding it as UTF-8.
    r = subprocess.run([compiler, "--binary", str(OUT)],
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if r.returncode == 0:
        print("luau-compile: OK")
    else:
        print("luau-compile: FAILED")
        print(r.stderr.decode("utf-8", "replace")[:3000])
        sys.exit(1)
else:
    print("luau-compile: not available (skipped)")

# Mirror to the public web root when it exists, so the HTTP link stays current.
mirror = pathlib.Path("/root/gerbang-ai/public/sae2.lua")
if mirror.parent.exists():
    mirror.write_text(body)
    print(f"mirrored: {mirror}")
