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

### Fase 0 — Ukur, jangan asumsikan
- [ ] Ukur ukuran `OrangeFox/bootable/Recovery` dan `OrangeFox/vendor/recovery`
      (clone `--depth=1`), lalu hitung kebutuhan nyata
- [ ] Putuskan A atau B berdasarkan angka itu

**Selesai bila:** kebutuhan disk diketahui angkanya, bukan diperkirakan.

### Fase 1 — Konversi pohon
- [ ] `mv bootable/recovery bootable/recovery-twrp` (simpan, jangan hapus)
- [ ] Clone `OrangeFox/bootable/Recovery.git -b fox_12.1` → `bootable/recovery`
- [ ] Clone `OrangeFox/vendor/recovery.git -b fox_12.1` → `vendor/recovery`
- [ ] Terapkan tambalan `update_engine` yang dilakukan sync script v021

**Selesai bila:** `vendor/recovery` ada dan `lunch` menerima produk A37f.

### Fase 2 — Device tree
Basisnya device tree TWRP 12.1 kita yang sudah terbukti, BUKAN android-9.0.

- [ ] Salin `device/oppo/A37f` dari `android_build_oppo_A37-twrp`
- [ ] `prebuilt/Image` ← bangun dari kernel branch `twrp-12.1` (`29cc5a6be0fe`)
- [ ] Sesuaikan `omni_A37f.mk` ke konvensi penamaan fox_12.1
- [ ] Baca variabel `OF_*` **dari repo `vendor/recovery` yang baru di-clone**,
      bukan dari wiki — halaman wiki `dev/building/vars` dirender JS dan tidak
      bisa diambil apa adanya

Yang sudah terbukti dan JANGAN diubah tanpa alasan:

```
BOARD_RAMDISK_OFFSET := 0x02000000    kernel 18,5 MB melebihi 0x01000000
BOARD_KERNEL_PAGESIZE := 2048
cmdline dengan enam parameter ramoops.*, termasuk ramoops.ecc=32
recovery.fstab dan twrp.flags -- seluruh alamat sudah diverifikasi terhadap
  tabel partisi perangkat
```

### Fase 3 — Ukuran image
Partisi recovery **33.554.432 byte**. TWRP kita 32.157.696 (sisa 1.396.736).
OrangeFox lebih besar dari TWRP, jadi ini kendala nyata.

Tuas, urut dari yang paling ampuh:

```
OF_USE_LZMA_COMPRESSION=1     kernel punya RD_LZMA (RD_LZ4 tidak diset)
TW_EXTRA_LANGUAGES := false   sudah dipakai di TWRP kita, hemat ~485 KB
FOX_DRASTIC_SIZE_REDUCTION=1  cadangan terakhir, HARUS setelah export lain
```

### Fase 4 — Verifikasi sebelum menyentuh perangkat
- [ ] Ukuran ≤ 33.554.432
- [ ] sha256 kernel di dalam image **identik** dengan hasil build sendiri
- [ ] cmdline memuat keenam `ramoops.*` **dan** `ecc=32`
- [ ] Pustaka yang dibutuhkan biner recovery lengkap
- [ ] Blob dekripsi ada: `qseecomd`, `keymaster@4.1`, `libQSEEComAPI`

### Fase 5 — Uji di perangkat
- [ ] Boot, UI tampil, sentuh normal
- [ ] **Dekripsi `/data` ber-Adiantum dengan PIN** — ini ujian yang menentukan
- [ ] adb berfungsi; MTP kalau OrangeFox mendukungnya
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
