# REX-Ray + Ceph RBD

This is a Vagrant environment using `VirtualBox` and
`Virtual Media` as storage for Ceph to be consumed by REX-Ray along with
Docker as the container runtime.  This can be used as a quick way
to get started working with Ceph and REX-Ray.

The `RBD` storage driver within REX-Ray is attaching RADOS Block Devices (RBD)
to the Vagrant VMs.  This enables the persistent volumes to be
moved between containers, which allow container hosts to be immutable and
containers to remain non-persistent.

## Installation

### Clone the repo
```
git clone https://github.com/codedellemc/vagrant
cd vagrant/ceph
vagrant up
```

## Usage
When the Vagrant environment is up and running, you can now run
`vagrant ssh ceph-admin` to get into the VM.  Since REX-Ray requires root
privileges for mounting, etc you can at this point issue something similar to
`sudo -i` to ensure you are running as root.

You can check the status of the Ceph cluster with `ceph -s`. You should be
able to immediately run commands like `rexray volume create` and
`rexray volume ls`, or do the same thing with docker via `docker volume create`
and `docker volume ls`

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
other. Setting all to false will result in no new rexray being installed,
leaving whatever happens to be pre-installed in the vagrant box.

When using `install_rex_from_source`, it is also possible to modify the
`build_rexray` script to point to different branches or repo forks for both
rexray and libstorage.

## REX-Ray
Consult the full REX-Ray documentation [here](http://rexray.readthedocs.org/en/stable/).

Get information on the existing volumes:

`rexray volume ls`

Create a new volume:

`rexray volume create --size=20 test`

Delete a volume:

`rexray volume remove test`

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
