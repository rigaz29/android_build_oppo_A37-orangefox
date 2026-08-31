# OrangeFox R12.0 (fox_12.1) untuk OPPO A37f

Recovery berbasis OrangeFox untuk OPPO A37f (msm8916, Snapdragon 410), dibangun
di atas device tree dan kernel TWRP 12.1 yang sudah terbukti jalan di perangkat.

Sudah teruji di perangkat: boot, adb + MTP berdampingan, dan **dekripsi
`/data` ber-Adiantum** (`fileencryption=adiantum:adiantum:v1`).

## Isi

```
device/oppo/A37f/     device tree, termasuk prebuilt/Image
patches/              tambalan wajib -- BACA patches/README.md LEBIH DULU
PLAN.md               catatan lengkap: keputusan, angka, dan sebabnya
```

## Kernel

`prebuilt/Image` (18.509.176 B) dibangun dari:

```
github.com/rigaz29/kernel_oppo_msm8939   branch twrp-12.1   29cc5a6be0fe19908d9e68a3b21d5f9ef1e97fa9
Linux version 3.10.108-lineageos-g29cc5a6be0fe
```

Dipakai lewat `OF_FORCE_PREBUILT_KERNEL=1`. Untuk membangun ulang, pakai commit
di atas — sha256 hasilnya harus
`be3c311a623512f426080693c9e6d0cf27bcb71497a263967e55a8ec3d6c1377`.

## Membangun

```sh
# 1. Sync manifest minimal TWRP 12.1
# 2. Ganti pohon recovery
mv bootable/recovery bootable/recovery-twrp
touch bootable/recovery-twrp/.find-ignore          # WAJIB, lihat patches/README.md
git clone https://gitlab.com/OrangeFox/bootable/Recovery.git -b fox_12.1 bootable/recovery
git clone https://gitlab.com/OrangeFox/vendor/recovery.git  -b fox_12.1 vendor/recovery

# 3. Terapkan SEMUA tambalan di patches/README.md

# 4. Bangun
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch omni_A37f-eng
mka recoveryimage -j8
```

Keluaran: `OrangeFox-R12.0-Unofficial-A37f.img` dan `.zip` di `$OUT`.

## Batas ukuran

Partisi recovery **33.554.432 B** (`mmcblk0p23`). Image saat ini 33.093.632 B —
sisa hanya 460.800 B, jadi setiap penambahan harus diukur.

`FOX_EXCLUDE_NANO_EDITOR=1` di `vendorsetup.sh` yang membuatnya muat: nano
beserta basis data terminfo-nya memakan 3.352.091 B, dan terminfo hanya berguna
untuk nano. Tanpa itu image kelebihan 378.880 B.

## Yang tidak boleh diubah tanpa alasan

```
BOARD_RAMDISK_OFFSET := 0x02000000    kernel 18,5 MB melebihi 0x01000000
BOARD_KERNEL_PAGESIZE := 2048
OF_USE_LZMA_COMPRESSION=1             kernel punya RD_LZMA; RD_LZ4 TIDAK diset
TW_MAX_BRIGHTNESS := 255              sama dengan yang dibaca deteksi otomatis
OF_DEFAULT_KEYMASTER_VERSION := 4.1   sama dengan omni_A37f.mk
cmdline: enam parameter ramoops.* + ramoops.ecc=32
```

Jangan pernah menyalakan `OF_SKIP_FBE_DECRYPTION` — ia mematikan dekripsi FBE,
justru kemampuan yang paling penting di perangkat ini.
