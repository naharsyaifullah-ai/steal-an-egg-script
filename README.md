# Steal An Egg — Script Delta

Script untuk game Roblox **Steal An Egg** (by *and Collect Rare Pets*), dipakai lewat executor seperti Delta di HP.

## Cara pakai

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/naharsyaifullah-ai/steal-an-egg-script/main/sae.lua"))()
```

Copy satu baris di atas ke executor → Execute.

## Yang diperbaiki di v3

Tiga keluhan nyata dari pemakaian v2, semuanya sudah dibetulkan dan diuji:

**1. "Cuma bisa steal yang Uncommon doang."**
Penyebabnya: v2 membaca rarity dari label teks pada telur. Game tidak memasang label itu, jadi hampir semua telur terbaca `nil` dan filter menolaknya — yang lolos hanya telur yang teksnya kebetulan memuat kata rarity. v3 memakai **database 80 pet** (10 biome): nama objek dipetakan langsung ke rarity dan income resmi. Telur polos tanpa satu pun label teks sekarang terbaca benar. Diuji: 10/10 tier memilih telur yang tepat.

**2. "Steal-nya kok terbang, dan malah jatuh-jatuh."**
Penyebabnya: v2 memakai `BodyVelocity` + `PlatformStand` — itu memang melayang, dan begitu gaya dilepas karakter terhuyung karena kaki dimatikan. v3 jalan pakai `Humanoid:MoveTo()`: animasi jalan normal, fisika normal. Diuji: ketinggian karakter **tidak berubah sama sekali** selama perjalanan, tidak ada `BodyVelocity`/`BodyGyro`, dan `PlatformStand` tidak pernah dinyalakan. Anti-trap sekarang **menggeser titik tujuan**, bukan mendorong badan.

**3. "Speed steal-nya diatur di tab steal."**
Sudah: slider **Kecepatan saat steal** terpisah dari kecepatan jalan biasa di tab PLAYER.

**4. "ESP-nya perbaiki, jadi tahu egg ini Cosmic dan apa pet-nya, duit per detiknya."**
ESP sekarang 3 baris per telur:

```
Rainbow Divine · Kitsune
$4.5B/s  ($1.8B/s ×2.5)
Cherry · 3.24Mkg · 72m
```

Rarity + mutasi + nama pet, income sudah dikali pengali mutasi, lalu biome, berat, jarak. Plus slider **Rarity minimum** supaya layar tidak penuh telur Common.

## Fitur

**Tab STEAL**
- Auto steal dengan filter rarity 10 tier chip (warna sesuai rarity)
- Tombol cepat: Semua / Kosong / Top 3 / Cosmic+
- **Slider kecepatan steal** sendiri (16–1000 stud)
- Slider jeda antar steal & jarak maksimum telur
- Filter **income minimum** (skala $0 → $1B/s) dan berat minimum
- Prioritas telur mutasi: Spirit Bloom 3× > Rainbow 2.5× > Golden 2× > Bloom 1.5× > Silver 1.25×
- Auto bawa pulang ke base + setor

**Tab FARM**
- Auto hatch, auto claim uang, auto treadmill, auto upgrade, auto sell
- Tombol manual: hatch, claim, tekan prompt terdekat

**Tab PLAYER**
- Speed jalan 16–1000 stud
- Anti Trap & Anti Bat/Guard — menggeser jalur, tetap di tanah
- Anti Stun/Ragdoll, No Fall Damage, slider radius hindar
- **Perbaiki karakter** — lepas semua sisa gaya + PlatformStand kalau karakter terhuyung
- STOP semua (darurat), Reset karakter

**Tab ESP**
- ESP telur: rarity + nama pet + income $/s + mutasi + biome + berat + jarak
- ESP trap, bat/guard, pemain lain
- Slider rarity minimum & jarak ESP
- Panel isi map: jumlah telur, rincian per rarity, telur termahal saat ini

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

Script diuji pakai interpreter Luau asli di atas mock environment Roblox (Instance, Vector3, Humanoid dengan `MoveTo`, RemoteEvent, ProximityPrompt, fisika jalan):

- **246 assertion lulus, 0 gagal** (mode test)
- **5 assertion lulus** (mode produksi: tanpa flag test tidak ada global bocor, semua toggle OFF → nol remote tertembak)

Yang dibuktikan antara lain: telur polos tanpa label terbaca rarity + income benar 10/10; `KingMammoth` tidak keliru jadi `Mammoth`, `SandSpider` tidak jadi `Spider`, `IceDragon` tidak jadi `LavaDragon`; `BearTrap` tidak dianggap telur Bear; ketinggian karakter tidak berubah selama jalan (bukti tidak terbang); `PlatformStand` tidak pernah true (bukti tidak jatuh-jatuh); label ESP memuat rarity, nama pet, `$220K/s`, biome, jarak.

Jalankan sendiri:

```bash
python3 test/run.py        # mode test  → 246 assertion
python3 test/run_prod.py   # mode produksi → 5 assertion
```

## Struktur

```
src/p01_head.lua          state, tabel rarity, mutasi, warna
src/p00_db.lua            database 80 pet: rarity + income per detik
src/p02_scan.lua          deteksi telur/trap/musuh/base
src/p03_move.lua          remote indexer + jalan di tanah (MoveTo)
src/p09_predict.lua       mesin prediksi siklus
src/p04_loops.lua         loop steal, farm, player, ESP
src/p10_predict_loop.lua  loop pengamat + auto kejar
src/p05_ui_base.lua       tema & jendela
src/p06_ui_comp.lua       komponen UI (toggle, slider, tab)
src/p07_ui_pages.lua      isi tab STEAL/FARM/PLAYER/ESP
src/p11_predict_ui.lua    isi tab PREDIKSI
src/p08_export.lua        hook test (mati di produksi)
build.py                  perakit → sae.lua
```

Build ulang: `python3 build.py`

## Sumber data pet

Rarity dan income tiap pet diambil dari index komunitas (Eldorado, 31 Agu 2026): 80 pet di 10 biome, 10 tier rarity Common → Divine, plus 6 pet Brainrot dari telur Shop terbatas. Kalau game update dan menambah pet baru, tambahkan barisnya di `src/p00_db.lua`.

## Peringatan

Memakai executor/script di Roblox melanggar Terms of Service dan bisa berujung ban. Pakai akun cadangan. Kalau game mengganti nama objek/remote, buka tab ESP dan lihat panel isi map — angka "dikenali" menunjukkan berapa telur yang berhasil dicocokkan ke database.

## Lisensi

MIT
