vagrant-scaleio
---------------

# Description

Vagrantfile to create a three-VM EMC ScaleIO lab setup.

# Usage

This Vagrant setup will automatically deploy three CentOS 6.5 nodes, download the ScaleIO 1.32 software and install a full ScaleIO cluster.

To use this, you'll need to complete a few steps:

1. `git clone https://github.com/virtualswede/vagrant-scaleio.git`
2. Edit the proxies (if needed)
3. Edit clusterinstall parameter to adjust for different installation methods (default is True which mean a fully working ScaleIO cluster gets installed)
4. Run `vagrant up` (if you have more than one Vagrant Provider on your machine run `vagrant up --provider virtualbox` instead)

Note, the cluster will come up with the default unlimited license for dev and test use.

### SSH
To login to the ScaleIO nodes, use the following commands: ```vagrant ssh mdm1```, ```vagrant ssh mdm2```, or ```vagrant ssh tb```.

### Clusterinstall function

In Vagrantfile there is a variable named `clusterinstall` that control how Vagrant provision ScaleIO during `vagrant up` process. If set to True (defualt) a fully functional ScaleIO cluster is installed with IM, MDM, TB, SDC, SDS on three nodes  If set to False three base VMs is installed with IM running on machined named MDM1. To install your cluster with clusterinstall=False you do `vagrant up` as usual but once complete use your webbrowser and point it to https://192.168.50.12. Login with admin and Scaleio123. From here you can deploy a new ScaleIO cluster using IM. Great for demo and learning purposes.


###Example CSV file for deployment of ScaleIO cluster using IM:
`
IPs,Password,Operating System,Is MDM/TB,Is SDS,SDS Device List,Is SDC
192.168.102.12,vagrant,linux,Primary,Yes,/home/vagrant/scaleio1,Yes
192.168.102.13,vagrant,linux,Secondary,Yes,/home/vagrant/scaleio1,Yes
192.168.102.11,vagrant,linux,TB,Yes,/home/vagrant/scaleio1,Yes
`

# Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.
