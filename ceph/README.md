# REX-Ray + Ceph RBD

This Vagrant environment uses `VirtualBox` and `Virtual Media` as storage for
Ceph to be consumed by REX-Ray. Docker is used as the container runtime allowing
a quick way to get started using Ceph and REX-Ray. 

The `RBD` storage driver within REX-Ray is attaching RADOS Block Devices (RBD)
to the Vagrant VMs. This enables the persistent volumes to be moved between
containers, which allow container hosts to be immutable and containers to remain
non-persistent.

The environment uses 3 Virtual Machines. One machine labeled as `ceph-admin` to
be used for running the containers and checking cluster status. The other two
machines, `ceph-server-1` and `ceph-server-2` are providing storage.

## Installation

### Clone the repo
```
git clone https://github.com/codedellemc/vagrant
cd vagrant/ceph
ssh-add ~/.vagrant.d/insecure_private_key
vagrant up
```

**NOTE**: The VMs contain the default Vagrant insecure SSH public key, such that
`vagrant ssh` works by default. However, the `ceph-admin` VM needs to be able to
SSH to the other VMs in order to configure Ceph via `ceph-deploy`. In order to
do this, the Vagrant SSH private key must be in your local SSH agent. Configuration of the Ceph cluster will not work without this step. The most
typical way to accomplish this on a nix-like machine is by running the command:

```
ssh-add ~/.vagrant.d/insecure_private_key
```


## Usage
When the Vagrant environment is up and running, run `vagrant ssh ceph-admin` to
get into the VM.  Since REX-Ray requires root privileges for mounting, etc,
run the rest of the lab as root:

```
sudo -i
```

Check the status of the Ceph cluster with:

```
ceph -s
```

The REX-Ray command line is available at this time:

```
rexray volume create <name> --size=X
rexray volume ls
```

The Docker Command line can be invoked as well for volume operation

```
docker volume create -d rexray --name <name> --opt=size=X
docker volume ls
```

Go to the [Application Demo of {code} Labs](https://github.com/codedellemc/labs#application-demo) to look at running applications like Postgres.


## Options
There are optional fields in the `Vagrantfile` that can be modified or
commented and uncommented.

- Determine how many Ceph nodes to start
 - `server_nodes`
- Install the latest stable release
 - `install_latest_stable_rex = true`
- Install the latest staged release
 - `install_latest_staaged_rex = true`
- Install rex from from source
 - `install_rex_from_source = true`

Only one of the install options is intended to be set to true at one time.
Setting multiple to true will result in wasted work, as each one overwrites the
other. Setting all to `false` will result in rexray not being installed,
leaving whatever happens to be pre-installed in the vagrant box.

When using `install_rex_from_source`, it is also possible to modify the
`build_rexray` script to point to different branches or repo forks for both
rexray and libstorage.

## REX-Ray
Consult the full REX-Ray documentation [here](http://rexray.readthedocs.org/en/stable/).

Get information on the existing volumes:

```
rexray volume ls
```

Create a new volume:

```
rexray volume create --size=20 test
```

Delete a volume:

```
rexray volume remove test
```

## Docker
Consult the Docker and REX-Ray documentation [here](http://rexray.readthedocs.io/en/stable/user-guide/schedulers/#docker).  

You can also create volumes directly from the Docker CLI.  The
following command created a volume of `20GB` size with name of
`test`.

```
sudo docker volume create --driver=rexray --name=test --opt=size=20
```

Start a new container with a REX-Ray volume attached, and
detach the volume when the container stops:

```
sudo docker run -it --volume-driver=rexray -v test:/test busybox /bin/sh
# ls /
bin   dev   etc   home  proc  root  sys   *test*  tmp   usr   var
# exit
```

## That's it!
