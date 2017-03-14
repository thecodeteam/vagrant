VBOX_VERSION=$(cat /home/vagrant/.vbox_version)

yum install -y kernel-devel kernel-headers make gcc

ln -s /usr/include/linux/version.h /lib/modules/$(uname -r)/build/include/linux/

cd /tmp
mount -o loop /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/vagrant/VBoxGuestAdditions_*.iso
