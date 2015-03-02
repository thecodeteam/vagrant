vagrant-scaleio
---------------

# Description

Vagrantfile to create a three-VM EMC ScaleIO lab setup.

# Usage

To use this, you'll need to complete a few steps:

1. Click on the "Download ZIP" link on the right side of this page and unpack the zipfile somewhere on your computer, or use `git clone https://github.com/virtualswede/vagrant-scaleio.git` if you have Git installed.
2. Download the latest 1.31 ScaleIO bits from EMC as per instructions below (you'll need an EMC support account) 
3. Place this zip file in the same directory as the `Vagrantfile` in this repo.
4. Unzip the files in the zip, and place them next to the `Vagrantfile`.  On most modern \*nix/Mac you could do easily with `unzip ScaleIO_1.31_RHEL6_Download.zip && mv ScaleIO_1.31_RHEL6_Download/*.rpm ./`
5. Edit the proxies (if needed)
6. Edit clusterinstall parameter to adjust for different installation methods (default is True which mean a fully working ScaleIO cluster gets installed)
6. Run `vagrant up` (if you have more than one Vagrant Provider on your machine run `vagrant up --provider virtualbox` instead)

### Clusterinstall function

In Vagrantfile there is a variable named `clusterinstall` that control how Vagrant provision ScaleIO during `vagrant up` process. If set to True (defualt) a fully functional ScaleIO cluster is installed with IM, MDM, TB, SDC, SDS on three nodes  If set to False three base VMs is installed with IM running on machined named MDM1. To install your cluster with clusterinstall=False you do `vagrant up` as usual but once complete use your webbrowser and point it to https://192.168.50.12. Login with admin and Scaleio123. From here you can deploy a new ScaleIO cluster using IM. Great for demo and learning purposes.

### How to download ScaleIO binaries (as of version 1.31.1)

https://download.emc.com/downloads/DL57934_ScaleIO-1.31.1-Gateway-for-Linux-Software-Download.zip

https://download.emc.com/downloads/DL57941_ScaleIO-1.31.1-Components-for--RHEL-6.x-Download.zip

Above URLs will change when new ScaleIO releases are available. For now the only tested version is the one available at above links. Newer versions within 1.31.x series will likely work if you edit yor Vagrantfile.
In your Vagranfile you can edit the following to adopt it to other versions of ScaleIO. Find the text per below and edit it:


### version of installation package

`version = "1.31-1277.3"`

###OS Version of package

`os="el6"`


###Example CSV file for deployment of ScaleIO cluster using IM:
`
IPs,Password,Operating System,Is MDM/TB,Is SDS,SDS Device List,Is SDC
192.168.102.12,vagrant,linux,Primary,Yes,/home/vagrant/scaleio1,Yes
192.168.102.13,vagrant,linux,Secondary,Yes,/home/vagrant/scaleio1,Yes
192.168.102.11,vagrant,linux,TB,Yes,/home/vagrant/scaleio1,Yes
`

Note, the cluster will come up with the default 30 day testing license, which should be fine for most uses.

# Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.
