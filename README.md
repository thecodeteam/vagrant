Vagrantfile to create a three-VM EMC ScaleIO lab setup.

To use this, you'll need to complete a few steps:

1. Download the latest 1.31 ScaleIO bits from EMC (you'll need an EMC support account) [from here](https://download.emc.com/downloads/DL56658_ScaleIO-1.31.0-Components-for--RHEL-6.x-Download.zip)
2. Place this zip file in the same directory as the `Vagrantfile` in this repo.
3. Unzip the files in the zip, and place them next to the `Vagrantfile`.  On most modern \*nix/Mac you could do easily with `unzip ScaleIO_1.31_RHEL6_Download.zip && mv ScaleIO_1.31_RHEL6_Download/*.rpm ./`
4. Edit the proxies (if needed)
4. Run `vagrant up`

Note, the cluster will come up with the default 30 day testing license, which should be fine for most uses.
