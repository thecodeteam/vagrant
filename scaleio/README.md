vagrant-scaleio
---------------

# Description

Vagrantfile to create a three-VM EMC ScaleIO lab setup.

# Usage

This Vagrant setup will automatically deploy three CentOS 7.1 nodes, download the ScaleIO 2.0 software and install a full ScaleIO cluster.

Added to this we can also automate the installation of [Docker](https://docker.com) and [REX-Ray](https://github.com/emccode/rexray) onto this cluster, so you can demonstrate containers on top of ScaleIO.

To use this, you'll need to complete a few steps:

1. `git clone https://github.com/emccode/vagrant.git`
2. `cd vagrant/scaleio`
2. Edit the proxies (if needed)
3. Edit the `clusterinstall` parameter to adjust for different installation methods (default is True which mean a fully working ScaleIO cluster gets installed)
3. Edit the `rexrayinstall` parameter to adjust enable or disable installation of [Docker](https://docker.com) and [REX-Ray](https://github.com/emccode/rexray) (default is True)
4. Run `vagrant up` (if you have more than one Vagrant Provider on your machine run `vagrant up --provider virtualbox` instead)

Note, the cluster will come up with the default unlimited license for dev and test use.

### SSH
To login to the ScaleIO nodes, use the following commands: ```vagrant ssh mdm1```, ```vagrant ssh mdm2```, or ```vagrant ssh tb```.

### Cluster install function

In Vagrantfile there is a variable named `clusterinstall` that controls how Vagrant provisions ScaleIO during `vagrant up` process.

If set to `True` (default), a fully functional ScaleIO cluster is installed with IM, MDM, TB, SDC and SDS on three nodes.

If set to `False`, three base VMs are installed with IM running on the machine named MDM1. To install your cluster when using `clusterinstall=False` you do `vagrant up` as usual but once complete use your web browser and point it to https://192.168.50.12. Login with admin and Scaleio123. From here you can deploy a new ScaleIO cluster using IM, great for demo and learning purposes.

### Example CSV file for deployment of ScaleIO cluster using IM:
`
IPs,Password,Operating System,Is MDM/TB,Is SDS,SDS Device List,Is SDC
192.168.50.12,vagrant,linux,Primary,Yes,/home/vagrant/scaleio1,Yes
192.168.50.13,vagrant,linux,Secondary,Yes,/home/vagrant/scaleio1,Yes
192.168.50.11,vagrant,linux,TB,Yes,/home/vagrant/scaleio1,Yes
`

### Docker install function

Automatically installs Docker and REX-Ray on all three nodes, and configures REX-Ray to use libStorage to manage ScaleIO volumes for persistent containers.

To run a container with persistent data stored on ScaleIO, from any of the cluster nodes you can run the following examples:

`sudo docker run -d --volume-driver=rexray -v redis-data:/data redis`
`sudo docker run -d --volume-driver=rexray -v mysql-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw mysql
`

You might need to restart Docker for this to work right after you've installed ScaleIO by running:
`sudo service docker restart`

### ScaleIO GUI

The ScaleIO GUI is automatically extracted and put into the `vagrant/scaleio/gui` directory, just run `run.sh` and it should start up. Connect to your instance with the credentials outlined in the [Cluster install function](# Cluster install function).

The end result will look something like this:

![alt text](docs/images/scaleio-docker-rexray.png)

# Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.

# Maintainer
- Jonas Rosland
