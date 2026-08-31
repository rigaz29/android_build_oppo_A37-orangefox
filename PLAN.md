# OrangeFox R12 (fox_12.1) untuk OPPO A37f

Ditulis ulang 31 Agustus 2026. Menggantikan rencana 12 Agustus seluruhnya —
yang lama ditulis sebelum TWRP 12.1, FBE, dan Adiantum ada, dan sebagian besar
premisnya sudah tidak berlaku. Riwayat versi lamanya ada di git.

Setiap angka di sini diambil dari sumber resmi OrangeFox atau diukur di
perangkat, bukan dari ingatan.

---

## 0. Temuan yang mengubah seluruh rencana

**Pohon TWRP kita SUDAH merupakan basis OrangeFox fox_12.1.**

`orangefox_sync.sh` (v028, 20260814) baris 48 dan 63-72:

```
MIN_MANIFEST="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"

do_fox_121() {
    BASE_VER=12;
    FOX_BRANCH="fox_12.1";
    TWRP_BRANCH="twrp-12.1";       <- basis manifest
    DEVICE_BRANCH="android-12.1";
}
```

Dan pohon `/root/twrp12` kita:

```
manifest url : https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git
branch       : twrp-12.1
```

**Identik.** OrangeFox bukan pohon terpisah — ia basis TWRP yang sama dengan
dua penukaran di atasnya:

| | |
|---|---|
| `bootable/recovery` | DIGANTI `gitlab.com/OrangeFox/bootable/Recovery.git` branch `fox_12.1` |
| `vendor/recovery` | DITAMBAH dari `gitlab.com/OrangeFox/vendor/recovery.git` branch `fox_12.1` |
| `system/update_engine` | satu tambalan (sync script v021) |

Kedua repo diverifikasi punya branch `fox_12.1`.

Konsekuensinya: **tidak perlu sync 45 GB dari nol.** Yang perlu diunduh hanya
dua repo itu.

---

## 1. Keadaan yang sudah terbukti, dan itu modal terbesarnya

Rencana lama menandai ini sebagai *"asumsi terbesar plan ini"*:

> "Userspace Android 11/12 di kernel 3.10 — ⚠️ BELUM terbukti"

**Sudah terbukti, dan sudah dirilis.** TWRP 3.7.1_12 untuk A37f:

```
rilis   github.com/rigaz29/android_build_oppo_A37-twrp/releases
        tag twrp-3.7.1_12-20260831, 32.157.696 byte
```

Yang berjalan di perangkat, bukan dugaan:

```
UI dan sentuh normal          adb + MTP hidup bersamaan
dekripsi FBE AES DAN Adiantum screen timeout, kecerahan penuh
ramoops ecc=32                partisi terverifikasi seluruhnya
```

Device tree-nya matang, sudah melewati banyak perbaikan yang tercatat
alasannya masing-masing. **Itu titik awal OrangeFox, bukan `TeamWin/android_device_oppo_A37f`
android-9.0 seperti rencana lama.**

### Kernel

```
repo   rigaz29/kernel_oppo_msm8939 branch twrp-12.1
HEAD   29cc5a6be0fe
Image  18.509.176 byte
```

Memuat: AIO FunctionFS (adb+MTP), Adiantum + NEON arm64 + DIRECT_KEY, f2fs
+201 commit, PSI, workingset, lockref, vmacache, RADIO_IRIS.

⚠️ `prebuilt/Image` sengaja TIDAK ada di repo device tree — bangun dari branch
kernel di atas dengan `lineageos_a37f_defconfig`.

---

## 2. Enkripsi: berbalik dari rencana lama

Rencana lama §2.1 menyatakan enkripsi "bukan masalah" karena `/data` tidak
terenkripsi, lalu menyimpulkan `fox_11.0` sama sahnya dengan `fox_12.1`.

**Keduanya sudah tidak berlaku:**

```
ro.crypto.type        file
fstab.qcom            fileencryption=adiantum:adiantum:v1
```

- `fox_12.1` menjadi **wajib**, bukan sekadar disarankan.
- `OF_DEFAULT_KEYMASTER_VERSION`, `TW_INCLUDE_CRYPTO`, dan variabel dekripsi
  lain yang dicoret rencana lama harus **dinilai ulang**.
- Prasyarat kernelnya sudah ada: `FS_POLICY_FLAG_DIRECT_KEY` (`b4799b06c556`),
  karena libfscrypt selalu menyalakan flag itu untuk Adiantum dan kernel
  tanpa dukungannya menolak `-EINVAL`.

Modal kita: **TWRP 12.1 sudah mendekripsi Adiantum dengan PIN**, lengkap dengan
blob vendor yang diperlukan (`qseecomd`, `keymaster@4.1`, `libQSEEComAPI`).
Yang perlu dibuktikan tinggal apakah OrangeFox memakai jalur yang sama.

---

## 3. Ruang disk

```
wiki OrangeFox   "You need at least 45GB of disk space for the fox_12.1"
tersedia         42 GB
/root/twrp12     42 GB  (.repo 8 GB, prebuilts 20 GB)
```

Angka 45 GB itu untuk **sync dari nol**. Karena basisnya sudah ada, kebutuhan
sebenarnya jauh lebih kecil — tapi belum diukur, dan itu harus jadi langkah
pertama, bukan asumsi.

Dua pendekatan, dan pilihannya menentukan sisanya:

**A. Salin pohon TWRP lalu konversi.** Aman — TWRP tetap bisa dibangun. Tapi
menggandakan 42 GB, dan tidak muat.

**B. Konversi di tempat, dengan `bootable/recovery` disimpan.** Hemat, tapi
pohon TWRP berhenti bisa dibangun sampai dikembalikan. Karena TWRP sudah
dirilis dan device tree-nya aman di GitHub, risikonya kecil.

Rekomendasi: **B**, dengan `bootable/recovery` TWRP dipindahkan (bukan dihapus)
supaya bisa ditukar balik.

---

## 4. Fase

### Fase 0 — Ukur, jangan asumsikan — **SELESAI**
- [x] Ukur ukuran `OrangeFox/bootable/Recovery` dan `OrangeFox/vendor/recovery`
      (clone `--depth=1`), lalu hitung kebutuhan nyata
- [x] Putuskan A atau B berdasarkan angka itu

**Selesai bila:** kebutuhan disk diketahui angkanya, bukan diperkirakan.

### Fase 1 — Konversi pohon — **SELESAI**
- [x] `mv bootable/recovery bootable/recovery-twrp` (simpan, jangan hapus)
- [x] Clone `OrangeFox/bootable/Recovery.git -b fox_12.1` → `bootable/recovery`
- [x] Clone `OrangeFox/vendor/recovery.git -b fox_12.1` → `vendor/recovery`
- [x] Terapkan tambalan `update_engine` yang dilakukan sync script v021

**Selesai bila:** `vendor/recovery` ada dan `lunch` menerima produk A37f.

### Fase 2 — Device tree — **SELESAI**
Basisnya device tree TWRP 12.1 kita yang sudah terbukti, BUKAN android-9.0.

- [x] Salin `device/oppo/A37f` dari `android_build_oppo_A37-twrp`
- [x] `prebuilt/Image` ← dibangun dari kernel branch `twrp-12.1` (`29cc5a6be0fe`),
      18.509.176 B
- [x] `vendorsetup.sh` dibuat, 8 variabel, tiap baris beralasan
- [x] Variabel dibaca dari `gitlab.com/OrangeFox/infrastructure/doc`
      `dev/build_vars.md` (968 baris, 07 Agustus 2026), bukan dari wiki

Yang sudah terbukti dan JANGAN diubah tanpa alasan:

```
BOARD_RAMDISK_OFFSET := 0x02000000    kernel 18,5 MB melebihi 0x01000000
BOARD_KERNEL_PAGESIZE := 2048
cmdline dengan enam parameter ramoops.*, termasuk ramoops.ecc=32
recovery.fstab dan twrp.flags -- seluruh alamat sudah diverifikasi terhadap
  tabel partisi perangkat
```

#### Tiga hambatan yang harus dibereskan, dan sebabnya

**1. Modul Soong terdefinisi dua kali.** `mv bootable/recovery
bootable/recovery-twrp` di Fase 1 tidak cukup — Soong memindai SELURUH pohon,
jadi kedua pohon mendefinisikan `soong-libaosprecovery_defaults`,
`soong-libminuitwrp_defaults`, dan `soong-libguitwrp_defaults`.

Solusinya berkas kosong `bootable/recovery-twrp/.find-ignore`. Mekanismenya di
`build/soong/ui/build/finder.go:53`:

```go
pruneFiles := []string{".out-dir", ".find-ignore"}
```

Dipilih ketimbang menghapus pohon TWRP, karena reversibel: tukar nama direktori
untuk kembali membangun TWRP.

**2. `OF_DEFAULT_KEYMASTER_VERSION` wajib.** `orangefox.mk:646` menolak
`TW_FORCE_KEYMASTER_VER` tanpa pasangannya. Diisi `4.1`, sama dengan
`keymaster_ver=4.1` di `omni_A37f.mk:20`. Bedanya TWRP menyetelnya sebagai
properti produk, OrangeFox saat jalan lewat `twrp.cpp:478`.

**3. `TW_MAX_BRIGHTNESS` wajib.** `orangefox.mk:708` menolak build tanpanya —
padahal flag ini justru kita CABUT dari TWRP untuk memperbaiki bug kecerahan.

Yang menyelesaikan tanpa mengembalikan bug: `data.cpp:1373-1391` di pohon
OrangeFox punya struktur sama dengan TWRP — kalau flag tidak ada, ia membaca
`/sys/class/leds/lcd-backlight/max_brightness` sendiri. Perangkat melaporkan
**255** (dibaca langsung lewat adb). Jadi `TW_MAX_BRIGHTNESS := 255` menghasilkan
angka yang PERSIS SAMA dengan deteksi otomatis. Bug lama berasal dari nilai 100
warisan device tree TWRP 9.0, bukan dari keberadaan flag-nya.

#### Hambatan keempat: sistem build harus ditambal

Build "berhasil" tapi tidak ada zip OrangeFox. Sebabnya
`vendor/recovery/OrangeFox_A12.sh` tidak dirujuk apa pun di pohon. Skrip itu
sendiri yang menjelaskan, baris 186-189:

```
-- You cannot build OrangeFox without patching build/core/Makefile
   in the build system. Aborting!
```

Patch resminya ada di `gitlab.com/OrangeFox/sync` → `patches/patch-manifest-fox_12.1.diff`,
diterapkan `patch -p1` dari direktori `build/` (`build/core` adalah symlink ke
`make/core`). Ia memasang empat pemanggilan hook di `core/Makefile`, mendefinisikan
`FOX_VENDOR` di `core/config.mk:616`, dan menambah fungsi di `make/envsetup.sh`.
Uji kering bersih tanpa fuzz.

Repo yang sama juga memuat `patches/patch-vendor-twrp-fox_12.1.diff`, dan isinya
**identik** dengan yang dikerjakan manual di Fase 1 — penyisipan
`include bootable/recovery/orangefox_soong.mk` tepat di atas
`SOONG_CONFIG_NAMESPACES += twrpVarsPlugin`.

**Selesai bila:** build menghasilkan `.img` dan `.zip`. ✅

### Fase 3 — Ukuran image — **SELESAI**
Partisi recovery **33.554.432 byte** (`mmcblk0p23`, 32768 KB di `/proc/partitions`).

Perjalanan angkanya:

| Tahap | Ukuran | Sisa |
|---|---|---|
| Tanpa pemaketan OrangeFox | 33.521.664 | 32.768 |
| Dengan pemaketan OrangeFox | 33.933.312 | **−378.880 (GAGAL)** |
| Setelah nano dibuang | **33.095.680** | **458.752** |

Defisitnya hanya 378 KB, jadi `FOX_DRASTIC_SIZE_REDUCTION` terlalu kasar — ia
membuang bash, busybox, zstd, lz4, patchelf, gnutar, gnused, fsck.erofs, dan
FoxFiles/Tools sekaligus (`OrangeFox_A12.sh:869-887`).

Sasaran yang tepat: **nano beserta basis data terminfo-nya**.

```
system/etc/terminfo   3.124.961 B   hanya berguna untuk nano
system/bin/nano         175.000 B
system/etc/nano          51.603 B
sbin/nano                   527 B
----------------------------------
total                 3.352.091 B
```

nano bukan pilihan kita — ia paket bawaan TWRP di
`vendor/twrp/config/packages.mk:10`. `FOX_EXCLUDE_NANO_EDITOR=1` menyetel
`TW_EXCLUDE_NANO := true` (`orangefox.mk:416-417`) sehingga nano tidak dibangun
sama sekali. Yang hilang hanya editor teks di dalam recovery.

`recovery/root` juga dibersihkan lebih dulu — skrip OrangeFox sendiri yang
menyarankannya di baris 1383, karena berkas dari build sebelumnya tetap ikut
masuk ramdisk kalau direktori itu tidak dikosongkan.

Catatan: `TW_EXTRA_LANGUAGES := false` ternyata TIDAK menghapus
`twres/languages` (masih 2,4 MB). Belum diperlukan, dicatat sebagai cadangan
kalau nanti ruang mepet lagi.

### Fase 4 — Verifikasi sebelum menyentuh perangkat — **SELESAI**
- [x] Ukuran 33.095.680 ≤ 33.554.432 (sisa 458.752 B, 98,6% terpakai)
- [x] sha256 kernel di dalam image **identik** dengan `prebuilt/Image`:
      `be3c311a623512f426080693c9e6d0cf27bcb71497a263967e55a8ec3d6c1377`
- [x] Kernel: `3.10.108-lineageos-g29cc5a6be0fe` — persis HEAD `twrp-12.1`
- [x] cmdline memuat keenam `ramoops.*` **dan** `ecc=32` — byte per byte
      identik dengan TWRP yang sudah berjalan
- [x] Semua offset header sama dengan TWRP: `kaddr 0x80008000`,
      `raddr 0x82000000`, `tags 0x80000100`, `page 2048`
- [x] Ramdisk terkompresi LZMA (magic `5d 00 00 80`), 43.199.744 → 14.372.172 B
- [x] Blob dekripsi ada: `qseecomd`, `android.hardware.keymaster@4.1-service`,
      `vendor/lib/libQSEEComAPI.so`, `keystore2`, `vold_prepare_subdirs`,
      `libsoftkeymasterdevice.so`, gatekeeper software
- [x] `recovery.fstab:26` memuat `fileencryption=adiantum:adiantum:v1`
- [x] `twrp.flags:19` memuat perbaikan `/usb-otg` kita
- [x] **Tanpa `adb_keys`**, `ro.secure=0`, `ro.debuggable=1` — sesuai
      ketentuan akses adb terbuka
- [x] Kedua jalur symlink partisi ada di perangkat: `/dev/block/by-name/recovery`
      (dipakai installer zip) dan `/dev/block/bootdevice/by-name/recovery`
      (dipakai fstab kita), keduanya → `mmcblk0p23`

Selisih terhadap ramdisk TWRP yang terbukti jalan, di luar gambar tema:

```
hilang di OrangeFox : libssh.so, libssl.so, me.twrp.twrpapp.apk, nano, nano.rc
tambahan            : FFiles/OF_*.zip, decrypt, magiskboot, resetprop, openaes,
                      mmgui, setgovernor, fox.cfg, ... (perkakas OrangeFox)
```

Artefak:

```
OrangeFox-R12.0-Unofficial-A37f.img   33.095.680 B
  sha256 f7256966ae53ce4ba6bbf13df2765982bf4c5afcdc917adc0cc2dcc718c7ce65
  md5    dced8e26fa65354141825a781e98f237
OrangeFox-R12.0-Unofficial-A37f.zip   46.509.654 B
```

Keduanya sudah disalin ke `/sdcard/` di perangkat (md5 diverifikasi cocok
setelah transfer) dan ke `/root/los23/share/`.

### Fase 5a — Regresi pertama di perangkat: input & adb — **DIPERBAIKI**

Gejala yang dilaporkan: touchscreen menekan sendiri, dan ada kursor di tengah
layar. Ditambah adb tidak hidup sama sekali.

**Akar masalahnya satu**: `bootable/recovery` OrangeFox adalah clone BARU, jadi
lima berkas yang pernah kita perbaiki di pohon TWRP hilang seluruhnya. Ini kelas
kesalahan yang akan berulang setiap kali pohon recovery diganti.

**Kursor + sentuhan hantu.** `gui.cpp` menggerakkan kursor dari event EV_REL, dan
kode itu IDENTIK di kedua pohon — jadi bukan di situ bedanya. Bedanya di
`minuitwrp/events.cpp`. Kompilator menerima:

```
-DTW_INPUT_BLACKLIST="hbtp_vm,lis3dh-accel,compass,light,proximity"
```

Tanda kutipnya ikut menjadi bagian makro, sehingga `EXPAND`/`STRINGIFY`
(`twcommon.h:37-38`) menghasilkan string yang kutipnya ada DI DALAM. Versi
OrangeFox memecah hanya pada `"\n"`, jadi seluruh daftar tetap satu token
berikut kutip dan `strcmp` tak pernah cocok — blacklist mati diam-diam.
Akibatnya `lis3dh-accel` (akselerometer) ikut dibaca dan memancarkan EV_REL
terus-menerus. Perbaikan kita: lucuti kutip, lalu pecah pada `,` maupun `\n`.

**adb mati.** Empat berkas sisanya, seluruhnya pekerjaan koeksistensi adb+MTP:

```
etc/init.rc                komposisi awal "mtp,adb", bukan "adb"
etc/init.recovery.usb.rc   idProduct 4EE2/D001 mengikuti komposisi
mtp/ffs/MtpDevHandle.cpp   mFd.reset() sebelum open ulang (f_mtp EBUSY)
partitionmanager.cpp       Release_ADB_FFS() sebelum komposisi diganti
```

Tiga berkas pertama identik dengan basis TWRP sehingga patch bersih.
`partitionmanager.cpp` berbeda 1971 baris di OrangeFox, jadi ketiga sisipannya
dikerjakan manual setelah memastikan semua titik jangkarnya ada.

Terverifikasi di dalam image hasil build:

```
init.rc:135                    setprop sys.usb.config mtp,adb   (identik TWRP)
init.recovery.usb.rc:30,38     idProduct 4EE2 / D001
system/bin/recovery            string "Stopping adbd to release FunctionFS"
system/lib/libminuitwrp.so     string "hbtp_vm,lis3dh-accel,..."
```

Ukuran setelah perbaikan: **33.093.632 B**, sisa 460.800 B.

### Fase 5 — Uji di perangkat
- [ ] Boot, UI tampil, sentuh normal
- [ ] **Dekripsi `/data` ber-Adiantum dengan PIN** — ini ujian yang menentukan
- [ ] adb berfungsi; MTP kalau OrangeFox mendukungnya
- [ ] Kecerahan: pastikan penuh, bukan 39% seperti bug TWRP lama
- [ ] `/sys/fs/pstore` terisi setelah panic

⚠️ TWRP yang sekarang JANGAN ditimpa sampai OrangeFox terbukti. Uji lewat
`fastboot boot` kalau bisa, atau siapkan `twrp-3.7.1_12-A37f-20260831.img`
untuk dikembalikan.

---

## 5. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Image > 32 MB | tidak bisa di-flash | LZMA dulu, DRASTIC terakhir; TWRP kita sisa 1,4 MB jadi marginnya tipis |
| OrangeFox tidak mendekripsi Adiantum | recovery tak berguna | TWRP sudah bisa; bandingkan jalur keduanya. Kernelnya sama, jadi bedanya pasti di userspace |
| Konversi merusak pohon TWRP | TWRP tak bisa dibangun | `bootable/recovery` dipindah bukan dihapus; device tree aman di GitHub; rilis sudah terbit |
| Disk 42 GB vs 45 GB | sync gagal di tengah | Fase 0 mengukur kebutuhan NYATA lebih dulu |
| Kewajiban GPL | pelanggaran lisensi | Sumber kernel sudah publik; rilis OrangeFox harus menautkannya seperti rilis TWRP |

---

## 6. Yang sengaja TIDAK dikerjakan

| | Alasan |
|---|---|
| `fox_14.1` | wiki: butuh ≥ 85 GB, dan ditandai *EXPERIMENTAL*; A37 lahir dengan Android 5.1 |
| `fox_11.0` | alasan memilihnya sudah gugur — lihat §2, `/data` kini terenkripsi |
| `fox_9.0` | tidak ada lagi di sync script sejak v015 (2022) |
| Membangun kernel di dalam pohon OrangeFox | pakai biner yang sudah teruji, alasan sama seperti TWRP: recovery menjalankan kernel identik dengan yang menulis ramoops |
| Fitur MIUI (`OF_PATCH_AVB20`, dll.) | bukan perangkat Xiaomi |

---

## 7. Rujukan

```
sync script  gitlab.com/OrangeFox/sync  orangefox_sync.sh  v028 (20260814)
wiki         wiki.orangefox.tech/dev/building
bootable     gitlab.com/OrangeFox/bootable/Recovery  branch fox_12.1
vendor       gitlab.com/OrangeFox/vendor/recovery    branch fox_12.1
device tree  github.com/rigaz29/android_build_oppo_A37-twrp
kernel       github.com/rigaz29/kernel_oppo_msm8939  branch twrp-12.1
```
