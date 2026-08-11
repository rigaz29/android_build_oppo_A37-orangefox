# OrangeFox untuk OPPO A37f dengan device tree dan kernel sendiri

Tujuan: recovery yang **bisa membaca ramoops** — sama seperti sub-proyek TWRP —
tetapi dengan antarmuka dan alat OrangeFox. Kernelnya kernel kita, yang sudah punya
patch `pstore/ram`.

Ditulis 11 Agustus 2026. Sub-proyek dari
[`android_build_oppo_A37-21`](https://github.com/rigaz29/android_build_oppo_A37-21).
Rujukan: [wiki build OrangeFox](https://wiki.orangefox.tech/dev/building) ·
[GitLab OrangeFox](https://gitlab.com/OrangeFox).

---

## 0. Kewajiban GPL — dibaca lebih dulu, bukan belakangan

Wiki OrangeFox menegaskannya berulang kali, dan ini bukan formalitas:

> if you make any unofficial release of OrangeFox for public use, and you have
> patched or edited any part of the OrangeFox source code or vendor tree or device
> tree to build that release, you MUST also release all the patched source code …
> your patched code cannot be "private".

Rencana ini **mengedit device tree** (menukar kernel, cmdline, offset). Jadi kalau
build-nya dibagikan ke publik — termasuk lewat link unduh — device tree hasil suntingan
itu wajib publik juga.

Kita sudah patuh secara kebetulan: device tree dan kernel kita memang sudah publik di
GitHub (`rigaz29/rb_device_oppo_A37`, `rigaz29/kernel_oppo_msm8939`). Yang perlu
ditambah hanya **device tree recovery OrangeFox-nya sendiri** — harus di-push ke repo
publik sebelum build-nya dibagikan, bukan sesudah.

Kalau build-nya hanya untuk perangkat sendiri dan tidak dibagikan, kewajiban ini tidak
terpicu. Tapi mengingat sub-proyek ini lahir dari kebutuhan diagnosis yang link-nya
sudah beberapa kali dibagikan, anggap saja akan dibagikan.

---

## 1. Kenapa OrangeFox, kalau TWRP sudah direncanakan

Keduanya menyelesaikan masalah yang sama (kernel prebuilt tanpa patch `pstore/ram`),
jadi ini soal pilihan alat, bukan kebutuhan teknis yang berbeda.

| | TWRP (`/root/a37-twrp`) | OrangeFox (di sini) |
|---|---|---|
| Device tree A37f | **ada**, `TeamWin/android_device_oppo_A37f` `android-9.0` | **tidak ada** — subgrup device OrangeFox hanya `nothing`, `oneplus`, `qcom` |
| Basis manifest | `twrp-9.0`, sepadan dengan device tree | `fox_11.0` / `fox_12.1` — harus mengadaptasi device tree android-9.0 |
| Disk | tree lebih kecil | **≥ 45 GB** untuk `fox_12.1` (wiki) |
| Ongkos | rendah, tukar prebuilt | menengah — adaptasi device tree + variabel `OF_*` |

⚠️ **Jujur soal urutan:** TWRP jalan yang lebih pendek ke tujuan (membaca ramoops).
OrangeFox layak dikerjakan kalau antarmuka dan alatnya yang diinginkan, bukan kalau
yang dicari sekadar ramoops secepatnya. Kalau tujuannya diagnosis mendesak, kerjakan
`/root/a37-twrp` dulu.

---

## 2. Fakta yang sudah diverifikasi

| | |
|---|---|
| Branch yang didukung | `fox_11.0`, `fox_12.1`, `fox_14.1` (dari `orangefox_sync.sh`) |
| `fox_9.0` | **ADA tapi TERLARANG** — di `legacy/`, ditandai *"totally obsolete … absolutely unsupported … do NOT use any of them"* |
| `fox_14.1` | wiki: *"You really should avoid building the 14.x branch"*, butuh ≥ 85 GB |
| Device tree OrangeFox A37f | **tidak ada** (subgrup device: `nothing`, `oneplus`, `qcom`) |
| Sumber adaptasi | `TeamWin/android_device_oppo_A37f` `android-9.0` @ `98a46b3ae` |
| fstab TWRP | **sudah format v2** (`flags=display="Persist";backup=1`) — kompatibel dengan fox_11/12.1, jadi adaptasinya jauh lebih ringan dari dugaan |
| Kernel kita | `Image` 18.327.160 B, sha256 `be170546…` — identik dengan kernel di `boot.img` dan `recovery.img` LOS 21; memuat patch `pstore/ram` + `CONFIG_DETECT_HUNG_TASK` |
| Kompresi ramdisk | kernel kita `CONFIG_RD_LZMA=y` dan `CONFIG_DECOMPRESS_LZMA=y` → `OF_USE_LZMA_COMPRESSION=1` **tersedia**. `CONFIG_RD_LZ4` tidak diset |
| Partisi recovery | 33.554.432 B (32 MB) |
| Mesin | RAM 11 GB, swap 15 GB, disk tersedia **35 GB** |

### 2.1 Enkripsi bukan masalah — dan itu menyederhanakan banyak hal

Sebagian besar kesulitan build OrangeFox di wiki berputar di dekripsi: `stuck on the
logo (indicating a decryption problem)`, `OF_DEFAULT_KEYMASTER_VERSION`,
`TW_INCLUDE_CRYPTO`. Semuanya **tidak berlaku** di sini — `/data` A37 kita TIDAK
terenkripsi (fstab tanpa `encryptable=`).

Konsekuensinya penting untuk pemilihan branch: alasan utama memilih basis yang lebih
baru adalah dukungan keymaster/dekripsi ROM modern. Karena itu gugur, `fox_11.0` jadi
sama sahnya dengan `fox_12.1` untuk kebutuhan kita.

### 2.2 ⚠️ Dua risiko ukuran, dan keduanya lebih tajam dari di TWRP

**a. Kernel melebihi offset ramdisk** — sama seperti di plan TWRP:

```
BOARD_RAMDISK_OFFSET := 0x01000000   = 16.777.216 B
kernel kita             18.327.160 B   MELEBIHI 1.549.944 B
```

Mitigasi: naikkan ke `0x02000000`. Belum terbukti di perangkat; LK OPPO tertutup.

**b. Image OrangeFox lebih besar dari TWRP**, sementara partisi tetap 32 MB dan kernel
kita 2,1 MB lebih besar dari kernel prebuilt TWRP. Wiki menyediakan tuas, urut dari
yang paling ampuh:

```
OF_USE_LZMA_COMPRESSION=1     ← tersedia, kernel kita punya RD_LZMA
FOX_DRASTIC_SIZE_REDUCTION=1  ← harus SETELAH semua export lain
TW_EXTRA_LANGUAGES :=
TW_INCLUDE_NTFS_3G :=
TW_EXCLUDE_TZDATA := true
TW_EXCLUDE_LPDUMP := true
```

### 2.3 Sync tidak boleh sebagai root, dan kita root

Wiki: *"do NOT run this as root"*. Skrip `orangefox_sync.sh` sendiri tidak memuat
pemeriksaan `id -u`/`EUID` (sudah dicek), jadi kemungkinan ini peringatan karena `repo`
yang rewel. Rencana: coba sebagai root; kalau `repo` menolak, buat pengguna biasa dan
jalankan sync sebagai pengguna itu. Jangan memaksa dengan flag yang mematikan
pemeriksaan tanpa tahu apa yang diperiksanya.

---

## 3. Fase

### Fase 0 — Ruang, sumber, dan keputusan branch
- [ ] **Kosongkan disk lebih dulu.** Tersedia 35 GB, `fox_12.1` butuh ≥ 45 GB.
      Salin keluar artefak yang masih dibutuhkan dari `/root/los21/out` (ROM,
      `boot.img`, `recovery.img`, `obj/KERNEL_OBJ/arch/arm64/boot/Image`,
      `installed-files.txt`), lalu hapus `out/` (77 GB → sisa ± 112 GB).
      **Jangan** hapus `/root/los21`.
- [ ] Pilih branch: **`fox_12.1`** (aktif didukung) atau **`fox_11.0`** (lebih dekat ke
      device tree android-9.0, disk lebih ringan). §2.1 menjelaskan kenapa keduanya
      sama sahnya di sini. Rekomendasi: mulai `fox_12.1`; turun ke `fox_11.0` kalau
      adaptasi device tree ternyata mahal.
- [ ] Sync lewat `orangefox_sync.sh`, bukan `repo init` langsung — skripnya menarik
      manifest minimal **dan** vendor OrangeFox sekaligus.
- [ ] Kalau `repo` menolak jalan sebagai root (§2.3), buat pengguna biasa dulu.

**Kriteria selesai:** sync bersih, `vendor/recovery` (vendor OrangeFox) ada, disk
sisa ≥ 15 GB.

### Fase 1 — Device tree OrangeFox A37f
- [ ] Salin `TeamWin/android_device_oppo_A37f` `android-9.0` → `device/oppo/A37f`
- [ ] Ganti `omni_A37f.mk` → `twrp_A37f.mk` atau `omni_*` sesuai konvensi branch yang
      dipilih (fox_12.1 memakai `twrp_`), dan sesuaikan `AndroidProducts.mk`
- [ ] `prebuilt/Image` ← kernel kita (18.327.160 B, `be170546…`)
- [ ] `prebuilt/dt.img` ← `dt.img` kita (`459a2a6d…`). Milik TWRP berbeda
      (`57c924d8…`) meski ukurannya sama; device tree harus sepadan dengan kernelnya
- [ ] `BOARD_RAMDISK_OFFSET := 0x02000000` (§2.2a)
- [ ] cmdline: tambah enam parameter `ramoops.*` seperti di `BoardConfig.mk` LOS kita;
      buang `msm_rtb.filter` (CONFIG_MSM_RTB mati); pertahankan `console=ttyHSL0`
- [ ] `vendorsetup.sh` dengan variabel `OF_*` — lihat Fase 2

**Kriteria selesai:** `lunch` menerima produk A37f tanpa error konfigurasi.

### Fase 2 — Variabel OrangeFox yang relevan untuk perangkat ini
Ditetapkan dari wiki, dengan alasan tiap baris:

```sh
export FOX_BUILD_DEVICE=A37f          # wajib, kalau tidak variabel OF_* diabaikan
export FOX_VANILLA_BUILD=1            # bukan perangkat Xiaomi/MIUI
export OF_USE_LZMA_COMPRESSION=1      # kernel punya RD_LZMA (§2.2b)
export OF_FORCE_PREBUILT_KERNEL=1     # kita memakai kernel prebuilt; cegah "NO KERNEL CONFIG"
export USE_CCACHE=1                   # ccache 7,5 GB sudah ada di /root/.ccache
export CCACHE_EXEC=/usr/bin/ccache
```

**Yang SENGAJA tidak diset**, supaya tidak ada yang menyalakannya karena ikut-ikutan:

| Variabel | Kenapa tidak |
|---|---|
| `FOX_AB_DEVICE` | A37 bukan A/B — partisinya statis dengan `boot` dan `recovery` terpisah |
| `FOX_VIRTUAL_AB_DEVICE` | bukan VAB |
| `OF_PATCH_AVB20` | khusus perangkat MIUI A-only |
| `OF_DEFAULT_KEYMASTER_VERSION` | `/data` tidak terenkripsi (§2.1) — tidak ada dekripsi untuk digagalkan |
| `FOX_DRASTIC_SIZE_REDUCTION` | cadangan, hanya kalau image melebihi 32 MB. Harus **setelah** semua export lain |

**Kriteria selesai:** build rc=0, `out/target/product/A37f/OrangeFox-unofficial-A37f.img` ada.

### Fase 3 — Verifikasi artefak sebelum menyentuh perangkat
- [ ] Ukuran image ≤ 33.554.432 B
- [ ] cmdline di dalam image memuat keenam parameter `ramoops.*`
- [ ] sha256 kernel di dalam image **identik** dengan `be170546…` — ini yang
      membuktikan kernel kita benar-benar terpakai, bukan prebuilt TWRP
- [ ] ramdisk memuat `init.rc` yang me-mount `/sys/fs/pstore`

### Fase 4 — Uji di perangkat tanpa mengorbankan TWRP
- [ ] `fastboot boot OrangeFox-unofficial-A37f.img` — jalan dari RAM, partisi utuh
- [ ] `adb shell ls -la /sys/fs/pstore` ← **uji kontrol**, lebih penting dari `cat`
- [ ] Kalau boot dan pstore terisi: baru pertimbangkan flash permanen
- [ ] Kalau dibagikan ke publik: push device tree OrangeFox ke repo publik (§0)

**Penanda sukses:** `/sys/fs/pstore` **tidak kosong**.

---

## 4. Risiko yang diakui

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Tidak ada device tree OrangeFox A37f | seluruh Fase 1 jadi pekerjaan adaptasi | fstab TWRP sudah format v2, jadi bagian tersulitnya sudah beres |
| Kernel 18,3 MB vs offset 16 MB | recovery tidak boot | offset `0x02000000`; belum terbukti di perangkat |
| Image > 32 MB | build gagal atau tidak bisa di-flash | LZMA dulu, `FOX_DRASTIC_SIZE_REDUCTION` terakhir |
| Userspace Android 11/12 di kernel 3.10 | recovery tidak boot | ⚠️ **BELUM terbukti** — `recovery.img` LOS 21 (basis A14) sudah dibangun tapi belum pernah di-boot di perangkat, karena selama ini yang dipakai TWRP. Ini asumsi terbesar plan ini |
| `repo` menolak sebagai root | sync gagal | buat pengguna biasa (§2.3) |
| Disk 35 GB vs kebutuhan 45 GB | sync gagal di tengah | Fase 0 mengosongkan 77 GB lebih dulu |
| Kewajiban GPL | pelanggaran lisensi kalau dibagikan | §0 — push device tree sebelum membagikan |

## 5. Yang sengaja TIDAK dikerjakan

| | Alasan |
|---|---|
| `fox_9.0` meski cocok dengan device tree | upstream menandainya *"do NOT use"* dan tanpa dukungan; memulai proyek di atas basis yang pemeliharanya sendiri menolak adalah utang sejak hari pertama |
| `fox_14.1` | wiki: hindari kecuali perangkat lahir dengan A14+; A37 lahir dengan Android 5.1, dan butuh ≥ 85 GB |
| Dukungan enkripsi | `/data` tidak terenkripsi; menambah keymaster hanya menambah variabel |
| Fitur MIUI | bukan perangkat Xiaomi |
| Membangun kernel dari sumber di tree OrangeFox | pakai biner yang sudah teruji, alasan sama dengan Jalur A di plan TWRP — recovery menjalankan kernel identik dengan yang menulis buffer ramoops |
