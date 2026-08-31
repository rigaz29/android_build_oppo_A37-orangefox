# Tambalan yang wajib diterapkan

Urutannya penting. Tanpa ketiganya, build gagal atau menghasilkan recovery yang
rusak di perangkat.

## 1. Sistem build — dari hulu OrangeFox

`vendor/recovery/OrangeFox_A12.sh` tidak dirujuk apa pun di pohon. Skrip itu
sendiri yang menjelaskan, baris 186-189:

```
-- You cannot build OrangeFox without patching build/core/Makefile
   in the build system. Aborting!
```

Tanpa tambalan ini build tetap "sukses" tapi hanya menghasilkan `recovery.img`
mentah — tanpa pemaketan OrangeFox dan tanpa zip installer.

```sh
git clone --depth 1 https://gitlab.com/OrangeFox/sync.git /tmp/of-sync
cd <manifest>/build
patch -p1 < /tmp/of-sync/patches/patch-manifest-fox_12.1.diff
```

Menyentuh `core/Makefile`, `core/config.mk`, dan `make/envsetup.sh`.
`build/core` adalah symlink ke `make/core`, jadi `-p1` dari `build/` benar.

## 2. vendor/twrp — dari hulu OrangeFox

```sh
cd <manifest>/vendor/twrp
patch -p1 < /tmp/of-sync/patches/patch-vendor-twrp-fox_12.1.diff
```

Menyisipkan `include bootable/recovery/orangefox_soong.mk` di
`config/BoardConfigSoong.mk`.

## 3. bootable/recovery — khusus A37f

`bootable-recovery-A37f-fixes.diff`

```sh
cd <manifest>/bootable/recovery
patch -p1 < bootable-recovery-A37f-fixes.diff
```

Lima berkas. Semuanya perbaikan yang sebelumnya dikerjakan di pohon TWRP kita
dan HILANG karena pohon `bootable/recovery` OrangeFox adalah clone baru. Ini
kelas kesalahan yang akan berulang setiap kali pohon recovery diganti.

### `minuitwrp/events.cpp` — touchscreen menekan sendiri + kursor di layar

Gejala tanpa tambalan ini: kursor muncul di tengah layar dan sentuhan hantu.

`gui.cpp` menggerakkan kursor dari event EV_REL, dan kode itu IDENTIK di pohon
TWRP maupun OrangeFox — jadi bukan di situ bedanya. Bedanya di penguraian
blacklist. Kompilator menerima:

```
-DTW_INPUT_BLACKLIST="hbtp_vm,lis3dh-accel,compass,light,proximity"
```

Tanda kutipnya ikut menjadi bagian makro, sehingga `EXPAND`/`STRINGIFY`
(`twcommon.h:37-38`) menghasilkan string yang kutipnya ada DI DALAM. Versi
OrangeFox memecah hanya pada `"\n"`, jadi seluruh daftar tetap satu token
berikut kutip dan `strcmp` tak pernah cocok — blacklist mati diam-diam.

Akibatnya `hbtp_vm` ikut dibaca. Perangkat itu punya `Handlers=mouse0` di
`/proc/bus/input/devices` — persis sumber kursornya.

Tambalannya melucuti kutip, lalu memecah pada `,` maupun `\n`.

Terverifikasi di perangkat lewat `/tmp/recovery.log`:

```
I:Blacklisting input device: hbtp_vm
I:Blacklisting input device: light
I:Blacklisting input device: proximity
I:Blacklisting input device: compass
I:Blacklisting input device: lis3dh-accel
```

Sebelum tambalan, tidak satu pun baris ini muncul.

### Empat berkas lain — adb mati total

```
etc/init.rc                komposisi USB awal "mtp,adb", bukan "adb"
etc/init.recovery.usb.rc   idProduct 4EE2/D001 mengikuti komposisi
mtp/ffs/MtpDevHandle.cpp   mFd.reset() sebelum open ulang (f_mtp EBUSY)
partitionmanager.cpp       Release_ADB_FFS() sebelum komposisi gadget diganti
```

Tiga berkas pertama identik dengan basis TWRP sehingga tambalan bersih.
`partitionmanager.cpp` berbeda 1971 baris di OrangeFox; ketiga sisipannya
dikerjakan manual setelah memastikan semua titik jangkarnya ada. Kalau tambalan
ini ditolak di kemudian hari, kerjakan ulang bagian itu dengan cara yang sama —
jangan paksa.

Terverifikasi di perangkat: `sys.usb.config=mtp,adb`, `idProduct=4ee2`,
`functions=mtp,ffs`, adb tersambung dan MTP jalan berdampingan.

## Bukan tambalan, tapi wajib

Setelah `mv bootable/recovery bootable/recovery-twrp`, Soong tetap memindai
pohon lama dan modul yang sama terdefinisi dua kali. Taruh berkas kosong
`.find-ignore` di dalamnya — `build/soong/ui/build/finder.go:53`:

```go
pruneFiles := []string{".out-dir", ".find-ignore"}
```

Reversibel: tukar nama direktori untuk kembali membangun TWRP.
