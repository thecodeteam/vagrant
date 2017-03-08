vagrant-scaleio
---------------

# Description

Automatically deploy ScaleIO in an isolated environment on top of VirtualBox.

Environment Details:

- Three CentOS 7.1 nodes
- Each node gets installed with the latest the ScaleIO software
- Configuration happens automatically to have a fully redundant ScaleIO cluster.

Optional Software Installations for Containers (read usage instructions below):

- [Docker](https://docker.com)
- [REX-Ray](https://github.com/codedellemc/rexray)
- [Apache Mesos](http://mesos.apache.org/) and [Marathon by Mesosphere](https://github.com/mesosphere/marathon)

## Requirements:

VirtualBox and Vagrant

For optional proxy setup, make sure you have the `vagrant-proxyconf` plugin installed.

## Usage

Set the following Environment Variables to `true` or `false` for your needs (must use `export`)

 - `SCALEIO_CLUSTER_INSTALL` - Default is `true`. If `true` a fully working ScaleIO cluster is installed. False only installs IM on node MDM1.
 - `SCALEIO_DOCKER_INSTALL` - Default is `true`.
 - `SCALEIO_REXRAY_INSTALL` - Default is `true`.
 - `SCALEIO_MESOS_INSTALL` - Default is `false`. Set to `true` to automatically install Apache Mesos and Marathon.

1. `git clone https://github.com/codedellemc/vagrant.git`
2. `cd vagrant/scaleio`
3. Edit the proxies (if needed)
4. `vagrant up` (if you have more than one Vagrant Provider on your machine run `vagrant up --provider virtualbox` instead)

Note, the cluster will come up with the default unlimited license for dev and test use.

### SSH

To login to the ScaleIO nodes, use the following commands: `vagrant ssh mdm1`, `vagrant ssh mdm2`, or `vagrant ssh tb`.

### Cluster install function

In the Vagrantfile, there is a variable named `clusterinstall` that controls how Vagrant provisions ScaleIO during `vagrant up` process.

By default this is set to `true` and can be overridden using `export SCALEIO_CLUSTER_INSTALL=false`.

If `true`, a fully functional ScaleIO cluster is installed with IM, MDM, TB, SDC and SDS on three nodes.

If set to `False`, three base VMs are installed with IM running on the machine named MDM1. To install your cluster when using `clusterinstall=False` you do `vagrant up` as usual but once complete use your web browser and point it to https://192.168.50.12. Login with `admin` and `Scaleio123`. From here you can deploy a new ScaleIO cluster using IM, great for demo and learning purposes.

### Example CSV file for deployment of ScaleIO cluster using IM:

```
IPs,Password,Operating System,Is MDM/TB,Is SDS,SDS Device List,Is SDC
192.168.50.12,vagrant,linux,Primary,Yes,/home/vagrant/scaleio1,Yes
192.168.50.13,vagrant,linux,Secondary,Yes,/home/vagrant/scaleio1,Yes
192.168.50.11,vagrant,linux,TB,Yes,/home/vagrant/scaleio1,Yes
```

### Docker, REX-Ray, and Mesos Installation

Docker and REX-Ray will automatically be installed on all three nodes but can be overridden using the Environment Variables above. Each will configure REX-Ray to use libStorage to manage ScaleIO volumes for persistent applications in containers.

To run a container with persistent data stored on ScaleIO, from any of the cluster nodes you can run the following examples:

Run Busybox with a volume mounted at `/data`:
```
docker -it --volume-driver=rexray -v data:/data busybox
```

Run Redis with a volume mounted at `/data`:
```
docker run -d --volume-driver=rexray -v redis-data:/data redis
```

Run MySQL with a volume mounted at `/var/lib/mysql`:
````
docker run -d --volume-driver=rexray -v mysql-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw mysql
````

Visit the [{code} Labs](https://github.com/codedellemc/labs) for more examples using Postgres and Minecraft.

For [Apache Mesos](http://mesos.apache.org/) and [Marathon by Mesosphere](https://github.com/mesosphere/marathon)  instructions for deploying containers, visit the [{code} Labs](https://github.com/codedellemc/labs) and try [Storage Persistence with Postgres using Mesos, Marathon, Docker, and REX-Ray](Storage Persistence with Postgres using Mesos, Marathon, Docker, and REX-Ray). Mesos and Marathon Web GUIs will be accessible from `http://192.168.50.12:5050` and `http://192.168.50.12:8080`.

#### Docker High Availability

Since the nodes all have access to the ScaleIO environment, fail over services with REX-Ray are available by stopping a container with a persistent volume on one host, and start it on another. Docker's integration with REX-Ray will automatically map the same volume to the new container, and your application can continue working as intended.

### ScaleIO GUI

The ScaleIO GUI is automatically extracted and put into the `vagrant/scaleio/gui` directory, just run `run.sh` and it should start up. Connect to your instance with the credentials outlined in the [Cluster install function](# Cluster install function).

The end result will look something like this:

![alt text](docs/images/scaleio-docker-rexray.png)

# Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.

# Contribution Rules

Create a fork of the project into your own repository. Make all your necessary changes and create a pull request with a description on what was added or removed and details explaining the changes in lines of code. If approved, project owners will merge it.

# Support

Please file bugs and issues on the [GitHub issues page](https://github.com/codedellemc/vagrant/issues). This is to help keep track and document everything related to this repo. For general discussions and further support you can join the [{code} by Dell EMC Community Slack](http://community.codedellemc.com/). The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.
