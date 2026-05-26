#!/bin/bash

set -e

if [ "$1" = "clean" ]; then
   sudo rm -rf build
   rm -f DATUM-box.iso
   exit 0
fi

mkdir build
cd build

wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.5.0-amd64-netinst.iso
echo "b2be60c555e328b4fa5ebb2d0e5c7ee6bc3eb4250c4dcfd3f78b8d9aec596efdf9f14f10a898c280eb252d50bbac91ea0a2bba29736df0d4985d50d4c8d77519  debian-13.5.0-amd64-netinst.iso" | sha512sum -c

xorriso -osirrox on -indev debian-13.5.0-amd64-netinst.iso -extract / debianfiles
chmod +w -R debianfiles/install.amd/
gunzip debianfiles/install.amd/initrd.gz
cp ../preseed.cfg ../post_config.sh ../happen_bashrc .
echo preseed.cfg | cpio -H newc -o -A -F debianfiles/install.amd/initrd
echo post_config.sh | cpio -H newc -o -A -F debianfiles/install.amd/initrd
echo happen_bashrc | cpio -H newc -o -A -F debianfiles/install.amd/initrd
gzip debianfiles/install.amd/initrd
chmod -w -R debianfiles/install.amd/

chmod +w debianfiles/isolinux/isolinux.cfg
cat > debianfiles/isolinux/isolinux.cfg << 'EOF'
default auto
timeout 1
prompt 0

label auto
  menu label ^Automated Install
  kernel /install.amd/vmlinuz
  append initrd=/install.amd/initrd.gz auto=true priority=critical --- quiet
EOF
chmod -w debianfiles/isolinux/isolinux.cfg

chmod +w debianfiles/boot/grub/grub.cfg
cat > debianfiles/boot/grub/grub.cfg << 'EOF'
set default=0
set timeout=1

menuentry "Automated Install" {
    linux  /install.amd/vmlinuz auto=true priority=critical --- quiet
    initrd /install.amd/initrd.gz
}
EOF
chmod -w debianfiles/boot/grub/grub.cfg

cd debianfiles
chmod +w md5sum.txt
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
chmod -w md5sum.txt
cd ..

dd if=debian-13.5.0-amd64-netinst.iso bs=1 count=432 of=isohdpfx.bin

xorriso -as mkisofs \
		-r -V 'Debian 13.5.0 amd64 n' \
		-o ../DATUM-box.iso \
		-J -joliet-long -cache-inodes \
		-isohybrid-mbr isohdpfx.bin \
		-b isolinux/isolinux.bin -c isolinux/boot.cat \
		-boot-load-size 4 -boot-info-table -no-emul-boot \
		-eltorito-alt-boot \
		-e boot/grub/efi.img \
		-no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
		debianfiles