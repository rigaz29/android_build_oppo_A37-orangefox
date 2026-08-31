#!/bin/bash
#
# Variabel build OrangeFox untuk OPPO A37f (msm8916).
#
# Rujukan kanonik:
#   gitlab.com/OrangeFox/infrastructure/doc  dev/build_vars.md  (07 Agustus 2026)
# BUKAN wiki.orangefox.tech/dev/building/vars -- halaman itu dirender JS dan
# tidak bisa dibaca apa adanya.
#
# Tiap baris di sini punya alasan. Yang TIDAK diset juga dicatat di bawah,
# supaya tidak ada yang menyalakannya karena ikut-ikutan.

# WAJIB. Tanpa ini seluruh variabel OF_* diabaikan.
export FOX_BUILD_DEVICE=A37f

# Perangkat 32-bit di userspace (armeabi-v7a), meski kernelnya arm64.
# Cocok dengan TARGET_ARCH := arm di BoardConfig.mk:35 dan hasil lunch.
export TARGET_ARCH=arm

# Bukan perangkat Xiaomi/MIUI. Melewati seluruh tambalan khusus MIUI, dan
# otomatis menyalakan sejumlah variabel lain yang mematikan fitur MIUI.
export FOX_VANILLA_BUILD=1

# Kita memakai kernel prebuilt (device/oppo/A37f/prebuilt/Image), bukan
# membangunnya di dalam pohon ini. Tanpa variabel ini build berhenti dengan
# galat 'NO KERNEL CONFIG'.
export OF_FORCE_PREBUILT_KERNEL=1

# Kompresi ramdisk LZMA. Partisi recovery hanya 33.554.432 byte dan TWRP kita
# sudah memakai 32.157.696 -- sisa 1,4 MB. OrangeFox lebih besar dari TWRP,
# jadi ini bukan optimasi melainkan kebutuhan.
# Prasyarat terpenuhi: BOARD_RAMDISK_USE_LZMA := true (BoardConfig.mk:95) dan
# kernel punya CONFIG_RD_LZMA=y + CONFIG_DECOMPRESS_LZMA=y.
# Catatan: CONFIG_RD_LZ4 TIDAK diset, jadi LZ4 bukan pilihan.
export OF_USE_LZMA_COMPRESSION=1

# Buang editor nano beserta basis data terminfo-nya.
#
# Ini yang membuat image muat. Tanpa ini: 33.933.312 B, lebih 378.880 B dari
# batas partisi 33.554.432 B.
#
# nano masuk sebagai paket bawaan TWRP (vendor/twrp/config/packages.mk:10),
# bukan pilihan kita. Variabel ini menyetel TW_EXCLUDE_NANO := true
# (orangefox.mk:416-417) sehingga nano tidak dibangun sama sekali.
#
# Bobotnya (diukur di out/target/product/A37f/recovery/root):
#   system/etc/terminfo   3.124.961 B   (basis data kapabilitas terminal,
#                                        HANYA berguna untuk nano)
#   system/bin/nano         175.000 B
#   system/etc/nano          51.603 B
#   sbin/nano                   527 B
#   ----------------------------------
#   total                 3.352.091 B
#
# Dipilih ketimbang FOX_DRASTIC_SIZE_REDUCTION, yang membuang jauh lebih banyak
# hal yang benar-benar berguna: bash, busybox, zstd, lz4, patchelf, gnutar,
# gnused, fsck.erofs, dan FoxFiles/Tools (OrangeFox_A12.sh:869-887).
# Yang hilang di sini hanya editor teks di dalam recovery.
export FOX_EXCLUDE_NANO_EDITOR=1

export OF_MAINTAINER="rigaz29"

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# ---------------------------------------------------------------------------
# YANG SENGAJA TIDAK DISET
#
#   OF_SCREEN_H / OF_STATUS_H
#     Hanya untuk layar non-16:9 atau bercutout. Perangkat ini 720x1280 =
#     tepat 16:9, diverifikasi lewat 'wm size'.
#
#   FOX_AB_DEVICE / OF_AB_DEVICE_WITH_RECOVERY_PARTITION
#     A37 bukan A/B. Partisinya statis dengan boot (mmcblk0p22) dan recovery
#     (mmcblk0p23) terpisah.
#
#   OF_SKIP_FBE_DECRYPTION / OF_SKIP_FBE_DECRYPTION_SDKVERSION
#     JANGAN. Keduanya justru MEMATIKAN dekripsi FBE. /data perangkat ini
#     terenkripsi Adiantum (fileencryption=adiantum:adiantum:v1) dan TWRP 12.1
#     kita SUDAH berhasil mendekripsinya dengan PIN. Menyalakan ini akan
#     membuang kemampuan yang justru paling penting.
#
#   FOX_DRASTIC_SIZE_REDUCTION
#     Cadangan terakhir, hanya kalau image melebihi 33.554.432 byte setelah
#     LZMA. Ia membuang hampir seluruh biner tambahan OrangeFox. Kalau
#     dipakai, HARUS ditaruh setelah semua export lain.
#
#   FOX_VERSION
#     Sudah usang menurut build_vars.md -- nomor rilis kini ditentukan
#     otomatis.
#
#   OF_PATCH_AVB20 dan variabel MIUI lainnya
#     Bukan perangkat Xiaomi.
