# Steal An Egg — Script Delta

Script untuk game Roblox **Steal An Egg** (by *and Collect Rare Pets*), dipakai lewat executor seperti Delta di HP.

## Cara pakai

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/naharsyaifullah-ai/steal-an-egg-script/main/sae.lua"))()
```

Copy satu baris di atas ke executor → Execute.

## Yang diperbaiki di v5

Auto steal tetap gagal di v3 dan v4 karena keduanya **menebak** nama remote (`steal`, `pickup`, `grab`, …). Menebak bukan jalan keluar. v5 berhenti menebak dan **merekam cara ambil yang sebenarnya** dari tanganmu sendiri:

1. Tab STEAL → tekan **AJARI: ambil 1 telur manual**
2. Ambil satu telur seperti biasa (jalan ke telur, tekan tombol ambil di game)
3. Begitu telur benar-benar terbawa, script mencatat panggilan mana yang dipakai — nama remote, metode (`FireServer`/`InvokeServer`), dan **posisi argumen** mana yang berisi objek telur
4. Auto steal memutar ulang panggilan itu apa adanya, dengan telur berbeda disisipkan ke posisi yang benar

Kalau ternyata pengambilan tidak memakai remote sama sekali, script mengenalinya juga: `ProximityPrompt` saja, atau murni sentuhan. Dalam kedua kasus itu ia **tidak** menembak remote apa pun — menembak remote secara buta bisa memicu anti-cheat, dan itu yang gagal sebelumnya.

Toggle **Tembak remote tebakan** sekarang **mati secara default**. Nyalakan hanya kalau belum pernah diajari.

Perubahan lain: script benar-benar mendekat sampai `Jarak mendekat sebelum ambil` (default 6 stud) sebelum mencoba, dengan sampai 3 kali koreksi jarak — jarak terlalu jauh adalah penyebab paling umum prompt dan sentuhan tidak berefek.

## Yang diperbaiki di v4

**1. Gerak: terbang DATAR, bukan jalan kaki dan bukan naik ke langit.**
v3 keliru menggantinya jadi jalan kaki — lambat sekali. v4 kembali terbang, tapi komponen Y kecepatan dipaksa **0** sehingga meluncur horizontal di ketinggian yang sama. `PlatformStand` tidak dipakai (itu penyebab ragdoll di v2). Kalau target beda ketinggian, naik/turun dibatasi 18 stud/detik. Ada toggle **Mode jalan kaki** kalau memang mau jalan.

**2. Steal benar-benar mengambil telur.**
v3 menembak prompt sekali lalu langsung pulang, sering dengan tangan kosong. v4:
- mendekat, lalu **koreksi jarak** kalau masih jauh
- menekan prompt **di dalam objek telur** (bukan cuma yang di sekitar), dengan `HoldDuration` dinolkan dan `MaxActivationDistance` dinaikkan — tanpa ini `fireproximityprompt` sering tidak berefek
- menyentuh **semua part** telur, bukan satu
- menembak remote dengan tiga bentuk argumen: objek, nama, tanpa argumen
- mengulang sampai `Usaha ambil per telur` kali
- **memverifikasi** telur benar-benar terbawa sebelum pulang; gagal dicatat sebagai gagal dan cari telur lain

**3. Tidak lagi mundar-mandir di base.**
Telur yang sudah ada di base sendiri atau sedang dibawa ditandai `milikku` dan tidak dipilih lagi. Radiusnya bisa diatur (`Radius abaikan base`).

**4. ESP: rarity + nama pet + income $/s.**
Database naik dari 80 ke **106 pet**: 10 biome + **Titan Temple** (Update 2, 29–30 Agu 2026) + **Monster Egg** 12 pet. Untuk pet yang income-nya memang tidak dipublikasikan, label menulis rarity + "income tak dipublikasikan" — bukan mengarang angka.

**5. "Pet belum ada di database" padahal petnya terdaftar.**
Masalahnya bukan datanya kurang — pencocokan nama yang terlalu sempit. Versi sebelumnya hanya membaca nama objek dan label teks. Game bisa menyimpan nama pet di tempat lain, jadi sekarang scanner membaca **lima sumber**:

- nama objek
- **nama induk sampai 3 tingkat** (`OniTigerNest > Egg`)
- **Attribute** objek dan part anaknya (`PetName = "Leviathan"`)
- **nama part anak** (`KitsuneMesh`)
- StringValue / TextLabel

Awalan ukuran (`Huge`, `Monstrous`, `Giant`) dan variasi penulisan (`Egg_Kitsune`, `EGG KITSUNE`, `Egg-Kitsune`, `Kitsune Egg (Divine)`) juga ditangani.

Kalau masih ada yang tak cocok, tab ESP punya tombol **Lihat nama asli telur**: menampilkan nama mentah tiap objek telur, nama induk, nama anak, dan Attribute-nya, menandai mana yang cocok (`OK kitsune`) dan mana yang tidak (`?? TAK COCOK`), lalu menyalin daftarnya ke clipboard. Ada juga **Lihat objek terdekat (semua)** untuk kasus telurnya sama sekali tidak terdeteksi.

## Fitur

**Tab STEAL**
- **AJARI: ambil 1 telur manual** — merekam cara ambil yang benar, lalu diputar ulang. Ini yang membuat auto steal bekerja
- Tombol `Berhenti merekam` dan `Lihat cara ambil terpelajari` (disalin ke clipboard)
- Toggle **Tembak remote tebakan** (mati default)
- Slider **Jarak mendekat sebelum ambil**
- Auto steal dengan filter rarity 10 tier chip (warna sesuai rarity)
- Tombol cepat: Semua / Kosong / Top 3 / Cosmic+
- **Slider kecepatan steal** sendiri (16–1000 stud)
- Slider jeda antar steal, jarak maksimum telur, **usaha ambil per telur**, **radius abaikan base**
- Filter **income minimum** (skala $0 → $1B/s) dan berat minimum
- Toggle **ambil telur tak dikenal** (pet di luar database)
- Prioritas telur mutasi: Spirit Bloom 3× > Rainbow 2.5× > Golden 2× > Bloom 1.5× > Silver 1.25×
- Auto bawa pulang ke base + setor, hanya setelah telur terbukti terbawa

**Tab FARM**
- Auto hatch, auto claim uang, auto treadmill, auto upgrade, auto sell
- Tombol manual: hatch, claim, tekan prompt terdekat

**Tab PLAYER**
- Toggle **Mode jalan kaki** (default: terbang datar)
- Speed 16–1000 stud
- Anti Trap & Anti Bat/Guard — menggeser jalur, tetap horizontal
- Anti Stun/Ragdoll, No Fall Damage, slider radius hindar
- **Perbaiki karakter** — lepas sisa gaya + PlatformStand kalau karakter terhuyung
- STOP semua (darurat), Reset karakter

**Tab ESP**
- ESP telur: rarity + nama pet + income $/s + mutasi + biome + berat + jarak
- ESP trap, bat/guard, pemain lain
- Slider rarity minimum & jarak ESP, toggle tampilkan telur tak dikenal
- Panel isi map: jumlah telur, berapa yang income-nya diketahui, berapa milik sendiri, rincian per rarity, telur termahal, ukuran database
- **Diagnosa nama**: `Lihat nama asli telur` dan `Lihat objek terdekat (semua)`

**Tab PREDIKSI**
- Hitung mundur reset telur — periode **diukur sendiri** dari perubahan isi map, bukan angka hafalan. Kalau game punya timer sendiri di layar, itu yang dipakai
- Peluang terukur per rarity (% reset yang memuatnya + perkiraan waktu tunggu). Rarity yang belum pernah terlihat ditulis apa adanya
- Alarm instan + lokasi + jarak saat telur langka muncul, plus auto kejar
- Tombol **Cek data 'telur berikutnya'** — menggeledah server: kalau data telur berikutnya tidak direplikasi ke klien, script bilang terang-terangan bahwa prediksi rarity pasti memang mustahil
- Hook pengumuman se-server saat telur langka spawn

## Soal "prediksi rarity"

Spawn Secret / Eternal / Divine adalah **undian acak tiap reset**, bukan jadwal tetap. Tidak ada cara jujur untuk bilang "Divine muncul jam 14:32". Script hanya melaporkan yang bisa diukur dari server: periode reset, peluang empiris dari reset yang tercatat, dan deteksi instan. Kalau datanya belum ada, tampilannya kosong — bukan angka palsu.

## Verifikasi

Diuji pakai interpreter Luau asli di atas mock environment Roblox (Instance, Vector3, Humanoid dengan `MoveTo`, Attribute, RemoteEvent, ProximityPrompt, fisika terbang & jalan):

- **389 assertion lulus, 0 gagal** (mode test)
- **5 assertion lulus** (mode produksi: tanpa flag test tidak ada global bocor, semua toggle OFF → nol remote tertembak)

Yang dibuktikan antara lain:

- perekam menangkap `RF_EggInteract:FireServer("Grab", <telur>)`, membuat cetakan dengan literal `"Grab"` dipertahankan dan slot telur sebagai placeholder, lalu memutarnya ulang untuk telur **berbeda** dengan objek yang benar di posisi argumen yang benar
- tanpa resep dan dengan `blindFire` mati: **nol** remote ditembak, hanya prompt + sentuhan
- resep "prompt saja" mencegah tembakan remote **walau** `blindFire` dinyalakan
- pemantau mendeteksi telur yang benar-benar terambil pengguna, lalu resepnya langsung terpakai untuk telur lain
- ketinggian karakter tidak bergeser >1 stud selama terbang datar, dan komponen Y kecepatan = 0 (bukti "lurus, tidak ke atas")
- `PlatformStand` tidak pernah true (bukti tidak ragdoll/jatuh-jatuh)
- berdiri di sebelah telur **tidak** dihitung berhasil memegang; telur yang hilang saat kita 500 stud jauhnya tidak diklaim sebagai hasil kita
- saat server menolak memberi telur: `stolen` tetap 0, kegagalan dicatat, remote deposit **tidak** ditembak
- telur di base sendiri / di tangan sendiri tidak dipilih ulang
- telur bernama `Egg` di dalam `OniTigerNest` terbaca Eternal $600M/s; Attribute `PetName = "Leviathan"` terbaca Cosmic $220K/s; `KitsuneMesh` sebagai nama part anak juga terbaca
- 7 variasi penulisan nama dan 4 awalan ukuran (`HugeKitsuneEgg`, `MonstrousTRexEgg`, …) semuanya tercocokkan
- `KingMammoth` bukan `Mammoth`, `SandSpider` bukan `Spider`, `MechaDreadscale` beda entri dari `Dreadscale`, `BearTrap` bukan telur Bear

Jalankan sendiri:

```bash
python3 test/run.py        # mode test  → 389 assertion
python3 test/run_prod.py   # mode produksi → 5 assertion
```

## Struktur

```
src/p01_head.lua          state, tabel rarity, mutasi, warna
src/p00_db.lua            database 106 pet: rarity + income per detik
src/p02_scan.lua          deteksi telur/trap/musuh/base + pencocokan nama
src/p03_move.lua          remote indexer + terbang datar & jalan kaki
src/p12_spy.lua           perekam cara ambil (hook remote) + putar ulang
src/p09_predict.lua       mesin prediksi siklus
src/p04_loops.lua         loop steal (ambil + verifikasi), farm, player, ESP
src/p13_learn.lua         mode belajar: pantau telur terambil pengguna
src/p10_predict_loop.lua  loop pengamat + auto kejar
src/p05_ui_base.lua       tema & jendela
src/p06_ui_comp.lua       komponen UI (toggle, slider, tab)
src/p07_ui_pages.lua      isi tab STEAL/FARM/PLAYER/ESP + diagnosa nama
src/p11_predict_ui.lua    isi tab PREDIKSI
src/p08_export.lua        hook test (mati di produksi)
build.py                  perakit → sae.lua
```

Build ulang: `python3 build.py`

## Sumber data pet

106 pet, diambil 5 Sep 2026 lewat you.com dari tiga sumber yang saling dicek:

- **Eldorado** "all pets index" — 80 pet di 10 biome
- **Joytify + Timesaver.gg** — 8 pet **Titan Temple** (Update 2 "Monsters Are Coming", 29–30 Agu 2026): Crustacia $130K/s, Spideron $95K/s, Bladehide $750K/s, Mantaris $11M/s, Rhinotaur $17.5M/s, Mutant Shark $215M/s, Gorilla King $880M/s, Nightflame (Divine, belum diindeks)
- **IGN All_Pets** — 12 pet **Monster Egg** (Scorpio → Dreadscale + 6 varian Mecha). IGN mencatat income-nya "Unknown", jadi di database nilainya `nil` dan ESP mengakuinya, kecuali Dreadscale (~$8B/s dari satu sumber)

Angka income adalah **nilai dasar** pet. Di game, berat/ukuran telur ikut menentukan money/s akhir, jadi ini patokan — bukan hasil persis. Kalau game menambah pet baru, tambahkan barisnya di `src/p00_db.lua`.

## Peringatan

Memakai executor/script di Roblox melanggar Terms of Service dan bisa berujung ban. Pakai akun cadangan.

## Lisensi

MIT
