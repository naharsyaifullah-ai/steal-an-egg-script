# Steal An Egg — Script Delta

Script untuk game Roblox **Steal An Egg** (by *and Collect Rare Pets*), dipakai lewat executor seperti Delta di HP.

## Cara pakai

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/naharsyaifullah-ai/steal-an-egg-script/main/sae.lua"))()
```

Copy satu baris di atas ke executor → Execute.

## Fitur

**Tab STEAL**
- Auto steal telur dengan **filter rarity** — 10 tier chip: Common, Uncommon, Rare, Epic, Legendary, Mythic, Cosmic, Secret, Eternal, Divine (warna sesuai rarity)
- Tombol cepat: Semua / Kosong / Top 3 (Secret+Eternal+Divine)
- Filter berat minimum (kg)
- Prioritas telur mutasi: Spirit Bloom > Rainbow > Golden > Bloom > Silver
- Auto bawa pulang ke base + setor
- Slider jeda antar steal

**Tab FARM**
- Auto hatch, auto claim uang, auto treadmill, auto upgrade, auto sell
- Tombol manual: hatch sekarang, claim semua, tekan prompt terdekat

**Tab PLAYER**
- Speed slider 16–1000 stud (dibatasi keras di 1000)
- Gerak halus pakai BodyVelocity — **bukan teleport**
- Anti Trap — menghindar otomatis dari trap/spike/net
- Anti Bat / Guard — menjauh saat musuh mendekat
- Anti Stun / Ragdoll, No Fall Damage
- Slider radius hindar
- Tombol STOP darurat (matikan semua sekaligus)

**Tab ESP**
- ESP telur: warna rarity + nama mutasi + berat + jarak
- ESP trap (merah), ESP bat/guard, ESP pemain lain
- Panel info: hitung telur/trap/musuh/remote di server

**Tab PREDIKSI**
- Hitung mundur reset telur — periode **diukur sendiri** dari perubahan isi map, bukan angka hafalan. Kalau game punya timer sendiri di layar, itu yang dipakai
- Peluang terukur per rarity (% reset yang memuatnya + perkiraan waktu tunggu). Rarity yang belum pernah terlihat ditulis apa adanya, tidak dikarang
- Alarm instan + lokasi + jarak saat telur langka muncul
- Auto kejar telur langka
- Tombol **Cek data 'telur berikutnya'** — menggeledah server: kalau data telur berikutnya tidak direplikasi ke klien, script bilang terang-terangan bahwa prediksi rarity pasti memang mustahil
- Hook pengumuman se-server saat telur langka spawn

## Soal "prediksi rarity"

Spawn Secret / Eternal / Divine di game ini adalah **undian acak tiap reset**, bukan jadwal tetap. Tidak ada cara jujur untuk bilang "Divine muncul jam 14:32". Script ini hanya melaporkan yang benar-benar bisa diukur dari server: periode reset, peluang empiris dari reset yang tercatat, dan deteksi instan. Kalau datanya belum ada, tampilannya kosong — bukan angka palsu.

## Verifikasi

Script diuji pakai interpreter Luau asli di atas mock environment Roblox (Instance, Vector3, Humanoid, RemoteEvent, ProximityPrompt):

- **190 assertion lulus, 0 gagal** (mode test)
- **5 assertion lulus** (mode produksi: tanpa flag test tidak ada global bocor, semua toggle OFF → nol remote tertembak)

Yang dibuktikan antara lain: `Stag` terbaca `Secret` bukan `Rare` (bug substring), filter rarity yang tidak ada di map mengembalikan nil bukan salah ambil, gerak tidak pernah melebihi speed×waktu (bukti bukan teleport), anti-trap benar mengubah vektor arah, dan loop tidak crash saat karakter mati / map kosong.

Jalankan sendiri:

```bash
python3 test/run.py        # mode test  → 190 assertion
python3 test/run_prod.py   # mode produksi → 5 assertion
```

## Struktur

Script dirakit dari beberapa bagian supaya mudah dirawat:

```
src/p01_head.lua          state, tabel rarity, mutasi, warna
src/p02_scan.lua          deteksi telur/trap/musuh/base
src/p03_move.lua          remote indexer + gerak halus (glide)
src/p09_predict.lua       mesin prediksi siklus
src/p04_loops.lua         loop steal, farm, player
src/p10_predict_loop.lua  loop pengamat + auto kejar
src/p05_ui_base.lua       tema & jendela
src/p06_ui_comp.lua       komponen UI (toggle, slider, tab)
src/p07_ui_pages.lua      isi tab STEAL/FARM/PLAYER/ESP
src/p11_predict_ui.lua    isi tab PREDIKSI
src/p08_export.lua        hook test (mati di produksi)
build.py                  perakit → sae.lua
```

Build ulang: `python3 build.py`

## Peringatan

Memakai executor/script di Roblox melanggar Terms of Service dan bisa berujung ban. Pakai akun cadangan. Nama objek dan remote di game ditebak dari pola umum — kalau game update dan namanya berubah, buka tab ESP untuk lihat apakah angka telur/remote masih terbaca.

## Lisensi

MIT
