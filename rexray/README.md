# vagrant-rexray

This is a Vagrant environment using `VirtualBox` and
`Virtual Media` as storage for REX-Ray along with
Docker as the container runtime.  This can be used as a quick way
to get started with and learn how data persistence for containers
works.

The `VirtualBox` storage driver that's in REX-Ray, is essentially hot-plugging
SATA devices to the Vagrant VMs.  This enables the persistent volumes to be
moved between containers, which allow container hosts to be immutable and
containers to remain non-persistent.

Requirements
- Vagrant installed
- VirtualBox 5.0.10+
- Internet connection

## Installation
### VirtualBox SOAP Web Service
There is documentation for that `VirtualBox` driver that shows some of the
pre-requisites for running the driver.  Detailed instructions are available
[here](http://rexray.readthedocs.org/en/stable/user-guide/storage-providers/virtualbox/).

There are two suggested steps to prepare the `VirtualBox` host OS to be able to
receive communication from the guests that are running REX-Ray.  

1. Remove authentication
 - `VBoxManage setproperty websrvauthlibrary null`
2. Start the web service using the following command.  Update the
path according to your local environment.
 - `/Applications/VirtualBox.app/Contents/MacOS/vboxwebsrv -H 0.0.0.0 -v`

### Clone the repo
```
git clone https://github.com/emccode/vagrant
cd vagrant/rexray
vagrant up
```

## Usage
When the Vagrant environment is up and running, you can now run `vagrant ssh rexray-1`
to get into the VM.  Since REX-Ray requires root privileges for
mounting, etc you can at this point issue something similar to
`sudo su` to ensure you are running as root.

By default Volumes will be created in a directory called
`Volumes` in the `pwd` where you do a `vagrant up` from.  This is
adjustable based on the `/etc/rexray/config.yml` file.

## Options
There are optional fields in the `Vagrantfile` that can be
commented and uncommented.  The default behavior is to only
update the volume path.

- Determine how many nodes to start
 - `nodes`
- Remove the currently installed REX-Ray
 - `rpm -e rexray`
- Install the latest stable release
 - `sudo curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s stable`
- Install the latest staged release
 - `sudo curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s staged`
- Update the volume path
 - `sed -i '/.*volumePath.*/c\\\x20\x20volumePath: \"#{dir}\"' /etc/rexray/config.yml`
- Enable volume mount pre-emption
 - `sed -i '/.*preempt.*/c\\\x20\x20\x20\x20\x20\x20preempt: true' /etc/rexray/config.yml`

## REX-Ray
Consult the full REX-Ray documentation [here](http://rexray.readthedocs.org/en/stable/).
Get information on the existing volumes:

`rexray volume get`

Create a new volume:

`rexray volume create --size=20 --volumename=test`

Delete a volume:

`rexray volume remove --volumeid=b4219d9e-c835-431f-8ed8-a7f4a3838ddf`

## Docker
Consult the Docker and REX-Ray documentation [here](http://rexray.readthedocs.org/en/stable/user-guide/third-party/docker/).  

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
