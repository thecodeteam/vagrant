# vagrant-rexray

This is a Vagrant environment for REX-Ray and Docker, used as a quick way
to get started with and learn how data persistence for containers works, and
You can see it as a way to learn how to use REX-Ray as a volume plugin for Docker.

It uses the VirtualBox storage driver that's in REX-Ray, essentially hotplugging
SATA devices to the Vagrant VM.

## Installation
```
git clone https://github.com/jonasrosland/vagrant-rexray
vagrant up
```

## Usage
When the Vagrant environment is up and running, you can now run `vagrant ssh`
to get into the VM, and run normal REX-Ray or Docker commands:

### REX-Ray
Get information on the existing volumes:

`rexray volume get`

Create a new volume:

`rexray volume create --size=20 --volumename=test`

Delete a volume:

`rexray volume remove --volumeid=b4219d9e-c835-431f-8ed8-a7f4a3838ddf`

### Docker

Start a new container with a REX-Ray volume attached:

```
sudo docker run -it --volume-driver=rexray -v test:/test busybox /bin/sh
# ls /
bin   dev   etc   home  proc  root  sys   *test*  tmp   usr   var
```
