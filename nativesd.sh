#!/sbin/sh
ROM_NAME=PAC

mkdir /tmp
mkdir /tmp/ns
cp /boot/initrd.gz /tmp/
cd /tmp/ns

# unzipping nand kernel and applying modifications

gzip -d -c ../initrd.gz | cpio -i -d

mkdir bin
cd /tmp
cp busybox ns/bin/busybox
cp e2fsck ns/bin/e2fsck
chmod 0777 ns/bin/busybox
chmod 0777 ns/bin/e2fsck

sed -i '/mount yaffs2/s/^/#/
s/#    #/# /g
/on fs/ r initrcmod' ns/init.rc

sed -i '/mtd@misc/s/^/#/' ns/ueventd.htcleo.rc

# checking if partition is nilfs2 and modifying accordingly
# changing auto to ext4 or nilfs2
Mount_Type=`mount | grep "nilfs2" | cut -d ' ' -f 5`

if [ "$Mount_Type" == "nilfs2" ]
then
sed -i 's/auto/nilfs2/1
/optional/a \mkdir /nilfs\
mount nilfs2 /dev/block/mmcblk0p2 /nilfs' ns/init.rc
else
sed -i 's/auto/ext4/1' ns/init.rc

fi

# applying rom name

sed -i "s/rOm/${ROM_NAME}/g" ns/init.rc

# fixing permissions
chmod 0666 ns/init.rc
chmod 0666 ns/ueventd.htcleo.rc
# making new ramdisk and copying over old

cd ns
find .| cpio -o -H newc | gzip -9 > ../initrd.gz
cd /tmp

chmod 0777 initrd.gz

cp initrd.gz /boot/initrd.gz
cp initrd.gz /boot_dir/initrd.gz
