1|# Steal An Egg — Script Delta
2|
3|Script untuk game Roblox **Steal An Egg** (by *and Collect Rare Pets*), dipakai lewat executor seperti Delta di HP.
4|
5|## Cara pakai
6|
7|```lua
8|loadstring(game:HttpGet("https://raw.githubusercontent.com/naharsyaifullah-ai/steal-an-egg-script/main/sae.lua"))()
9|```
10|
11|Copy satu baris di atas ke executor → Execute.
12|
13|## Yang diperbaiki di v4

Laporan: *"steal ga bekerja, hop itu terbang tapi lurus ga terbang ke atas, malah jalan bego sekali, steal ga ke-steal malah mundar-mandir di base, ESP tulisannya belum diketahui."* Semua ditangani:

**1. Gerak: terbang DATAR, bukan jalan kaki dan bukan naik ke langit.**
v3 keliru menggantinya jadi jalan kaki — lambat sekali. v4 kembali terbang, tapi komponen Y kecepatan dipaksa **0** sehingga meluncur horizontal di ketinggian yang sama. `PlatformStand` tidak dipakai (itu penyebab ragdoll di v2). Kalau target beda ketinggian, naik/turun dibatasi 18 stud/detik. Ada toggle **Mode jalan kaki** kalau memang mau jalan.

**2. Steal benar-benar mengambil telur.**
v3 menembak prompt sekali lalu langsung pulang, sehingga sering pulang dengan tangan kosong. v4:
- mendekat, lalu **koreksi jarak** kalau masih jauh
- menekan prompt **di dalam objek telur** (bukan cuma yang di sekitar), dengan `HoldDuration` dinolkan dan `MaxActivationDistance` dinaikkan — tanpa ini `fireproximityprompt` sering tidak berefek
- menyentuh **semua part** telur, bukan satu
- menembak remote dengan tiga bentuk argumen: objek, nama, dan tanpa argumen
- mengulang sampai `Usaha ambil per telur` kali
- **memverifikasi** telur benar-benar terbawa sebelum pulang; kalau gagal, dicatat sebagai gagal dan cari telur lain

**3. Tidak lagi mundar-mandir di base.**
Telur yang sudah ada di base sendiri atau sedang dibawa ditandai `milikku` dan tidak dipilih lagi. Radius penjagaan bisa diatur (`Radius abaikan base`).

**4. ESP tidak lagi menulis "belum diketahui".**
Database naik dari 80 ke **106 pet**: 10 biome + **Titan Temple** (Update 2, 29–30 Agu 2026) + **Monster Egg** 12 pet. Untuk pet yang income-nya memang tidak dipublikasikan, label menulis rarity + "income tak dipublikasikan" — bukan mengarang angka. Telur yang benar-benar di luar database memakai nama objeknya.

## Fitur
38|
39|**Tab STEAL**
40|- Auto steal dengan filter rarity 10 tier chip (warna sesuai rarity)
41|- Tombol cepat: Semua / Kosong / Top 3 / Cosmic+
42|- **Slider kecepatan steal** sendiri (16–1000 stud)
43|- Slider jeda antar steal & jarak maksimum telur
44|- Filter **income minimum** (skala $0 → $1B/s) dan berat minimum
45|- Prioritas telur mutasi: Spirit Bloom 3× > Rainbow 2.5× > Golden 2× > Bloom 1.5× > Silver 1.25×
46|- Auto bawa pulang ke base + setor
47|
48|**Tab FARM**
49|- Auto hatch, auto claim uang, auto treadmill, auto upgrade, auto sell
50|- Tombol manual: hatch, claim, tekan prompt terdekat
51|
52|**Tab PLAYER**
53|- Speed jalan 16–1000 stud
54|- Anti Trap & Anti Bat/Guard — menggeser jalur, tetap di tanah
55|- Anti Stun/Ragdoll, No Fall Damage, slider radius hindar
56|- **Perbaiki karakter** — lepas semua sisa gaya + PlatformStand kalau karakter terhuyung
57|- STOP semua (darurat), Reset karakter
58|
59|**Tab ESP**
60|- ESP telur: rarity + nama pet + income $/s + mutasi + biome + berat + jarak
61|- ESP trap, bat/guard, pemain lain
62|- Slider rarity minimum & jarak ESP
63|- Panel isi map: jumlah telur, rincian per rarity, telur termahal saat ini
64|
65|**Tab PREDIKSI**
66|- Hitung mundur reset telur — periode **diukur sendiri** dari perubahan isi map, bukan angka hafalan. Kalau game punya timer sendiri di layar, itu yang dipakai
67|- Peluang terukur per rarity (% reset yang memuatnya + perkiraan waktu tunggu). Rarity yang belum pernah terlihat ditulis apa adanya, tidak dikarang
68|- Alarm instan + lokasi + jarak saat telur langka muncul
69|- Auto kejar telur langka
70|- Tombol **Cek data 'telur berikutnya'** — menggeledah server: kalau data telur berikutnya tidak direplikasi ke klien, script bilang terang-terangan bahwa prediksi rarity pasti memang mustahil
71|- Hook pengumuman se-server saat telur langka spawn
72|
73|## Soal "prediksi rarity"
74|
75|Spawn Secret / Eternal / Divine di game ini adalah **undian acak tiap reset**, bukan jadwal tetap. Tidak ada cara jujur untuk bilang "Divine muncul jam 14:32". Script ini hanya melaporkan yang benar-benar bisa diukur dari server: periode reset, peluang empiris dari reset yang tercatat, dan deteksi instan. Kalau datanya belum ada, tampilannya kosong — bukan angka palsu.
76|
77|## Verifikasi
78|
79|Script diuji pakai interpreter Luau asli di atas mock environment Roblox (Instance, Vector3, Humanoid dengan `MoveTo`, RemoteEvent, ProximityPrompt, fisika jalan):
80|
81|- **246 assertion lulus, 0 gagal** (mode test)
82|- **5 assertion lulus** (mode produksi: tanpa flag test tidak ada global bocor, semua toggle OFF → nol remote tertembak)
83|
84|Yang dibuktikan antara lain: telur polos tanpa label terbaca rarity + income benar 10/10; `KingMammoth` tidak keliru jadi `Mammoth`, `SandSpider` tidak jadi `Spider`, `IceDragon` tidak jadi `LavaDragon`; `BearTrap` tidak dianggap telur Bear; ketinggian karakter tidak berubah selama jalan (bukti tidak terbang); `PlatformStand` tidak pernah true (bukti tidak jatuh-jatuh); label ESP memuat rarity, nama pet, `$220K/s`, biome, jarak.
85|
86|Jalankan sendiri:
87|
88|```bash
89|python3 test/run.py        # mode test  → 246 assertion
90|python3 test/run_prod.py   # mode produksi → 5 assertion
91|```
92|
93|## Struktur
94|
95|```
96|src/p01_head.lua          state, tabel rarity, mutasi, warna
97|src/p00_db.lua            database 80 pet: rarity + income per detik
98|src/p02_scan.lua          deteksi telur/trap/musuh/base
99|src/p03_move.lua          remote indexer + jalan di tanah (MoveTo)
100|src/p09_predict.lua       mesin prediksi siklus
101|src/p04_loops.lua         loop steal, farm, player, ESP
102|src/p10_predict_loop.lua  loop pengamat + auto kejar
103|src/p05_ui_base.lua       tema & jendela
104|src/p06_ui_comp.lua       komponen UI (toggle, slider, tab)
105|src/p07_ui_pages.lua      isi tab STEAL/FARM/PLAYER/ESP
106|src/p11_predict_ui.lua    isi tab PREDIKSI
107|src/p08_export.lua        hook test (mati di produksi)
108|build.py                  perakit → sae.lua
109|```
110|
111|Build ulang: `python3 build.py`
112|
113|## Sumber data pet
114|
115|Rarity dan income tiap pet diambil dari index komunitas (Eldorado, 31 Agu 2026): 80 pet di 10 biome, 10 tier rarity Common → Divine, plus 6 pet Brainrot dari telur Shop terbatas. Kalau game update dan menambah pet baru, tambahkan barisnya di `src/p00_db.lua`.
116|
117|## Peringatan
118|
119|Memakai executor/script di Roblox melanggar Terms of Service dan bisa berujung ban. Pakai akun cadangan. Kalau game mengganti nama objek/remote, buka tab ESP dan lihat panel isi map — angka "dikenali" menunjukkan berapa telur yang berhasil dicocokkan ke database.
120|
121|## Lisensi
122|
123|MIT
124|