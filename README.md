vagrant-scaleio
---------------

# Description

Vagrantfile to create a three-VM EMC ScaleIO lab setup.

# Usage

To use this, you'll need to complete a few steps:

1. Click on the "Download ZIP" link on the right side of this page and unpack the zipfile somewhere on your computer, or use `git clone https://github.com/virtualswede/vagrant-scaleio.git` if you have Git installed.
2. Download the latest 1.31 ScaleIO bits from EMC (you'll need an EMC support account) [from here](https://download.emc.com/downloads/DL56658_ScaleIO-1.31.0-Components-for--RHEL-6.x-Download.zip)
3. Place this zip file in the same directory as the `Vagrantfile` in this repo.
4. Unzip the files in the zip, and place them next to the `Vagrantfile`.  On most modern \*nix/Mac you could do easily with `unzip ScaleIO_1.31_RHEL6_Download.zip && mv ScaleIO_1.31_RHEL6_Download/*.rpm ./`
5. Edit the proxies (if needed)
6. Run `vagrant up`

Note, the cluster will come up with the default 30 day testing license, which should be fine for most uses.

# Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.
