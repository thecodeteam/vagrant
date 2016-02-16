# Playa Mesos

[Playa Mesos][8] helps you quickly create [Apache Mesos][1] test environments.
This project relies on [VirtualBox][5], [Vagrant][6], and an Ubuntu box image
which has Mesos and [Marathon][2] pre-installed. The box image is downloadable for your
convenience, but it can also be built from source using [Packer][9].  There is an external volume capability when using
with VirtualBox provided through [REX-Ray](https://github.com/emccode/rexray).

As an alternative to VirtualBox, it's possible to build and run the image on
VMware [Fusion](https://www.vmware.com/products/fusion/) or [Workstation](https://www.vmware.com/products/workstation/).

## Requirements

* [VirtualBox][5] 5.0.10+
* [Vagrant][6] 1.3+
* [git](http://git-scm.com/downloads) (command line tool)
* [Packer][9] 0.5+ (optional)
* VMware [Fusion](https://www.vmware.com/products/fusion/) or [Workstation](https://www.vmware.com/products/workstation/) (optional)
* [Vagrant Plugin for VMware Fusion or Workstation](https://www.vagrantup.com/vmware) (optional)

## Configuration
The `config.json` file holds all of the configurable parameters.  By default
there is one host deployed running the master and slave services.  Additionally
both Chronos and Marathon frameworks are running.  Set the appropriate hostnames, IP
addresses, VM settings, and other parameters in this file.

### Example All-In-One Master
```json
{
  "platform": "virtualbox",
  "box_name": "playa_mesos_ubuntu_14.04_201601041324",
  "base_url": "http://downloads.mesosphere.io/playa-mesos",
  "hosts": {
    "mesos-master": {
      "ip": "10.141.141.10",
      "vm_ram": "2048",
      "vm_cpus": "2"
    }
	}
}
```

### Example All-In-One Master with External Volumes
The `external_volumes` parameter can be introduced which leverages VirtualBox
to provide external volume support for tasks.  The external volume functionality
means that both the `Mesos containerizer` and `Docker containerizer` can
define external volumes that get attached to tasks.  See [Mesos](https://github.com/emccode/mesos-module-dvdi)
and [Docker](https://github.com/emccode/rexray) for examples.



```json
{
  "platform": "virtualbox",
  "box_name": "playa_mesos_ubuntu_14.04_201601041324",
  "base_url": "http://downloads.mesosphere.io/playa-mesos",
  "hosts": {
    "mesos-master": {
      "ip": "10.141.141.10",
      "vm_ram": "2048",
      "vm_cpus": "2",
      "external_volumes":true
    }
	}
}
```

### Example Master with 3 Slaves and External Volumes
Optionally a more realistic set of nodes can be deployed.  We include an
example below for `mesos-master`, `mesos-slave1`, `mesos-slave2`, and
`mesos-slave3`.  There is a `disable_slave` flag that can be set per node to
determine the personality of the node which is used on `mesos-master`.  
The root `vm_ram` and `vm_cpus` will be applied where configuration is not set
on individual nodes.

```json
{
  "platform": "virtualbox",
  "box_name": "playa_mesos_ubuntu_14.04_201601041324",
  "base_url": "http://downloads.mesosphere.io/playa-mesos",
  "hosts": {
    "mesos-master": {
      "ip": "10.141.141.10",
      "vm_ram": "512",
      "vm_cpus": "1",
      "disable_slave": true
    },
    "mesos-slave1":{
      "ip":"10.141.141.11",
      "external_volumes":true
    },
    "mesos-slave2":{
      "ip":"10.141.141.12",
      "external_volumes":true
    },
    "mesos-slave3":{
      "ip":"10.141.141.13",
      "external_volumes":true
    }
	},
  "vm_ram": "1024",
  "vm_cpus": "1"
}
```

### Other Examples
The `/examples` directory includes `config.json` files that can be used for
other automated configurations. Simply replace the default `conig.json` file
in order to use these.

#### config.json.0.25
In order to deploy `Mesos 0.25` you can use the specific config file, or you
can set the `mesos_release` parameter to `0.25.0-0.2.70.ubuntu1404` in your
existing configuration. Use `apt-cache policy mesos` or alternative methods to
determine the appropriate version setting. Following this a
`vagrant up --provision` will ensure the proper version is installed.

####

## Runtime Note
At any time you can remove a host or add a new host with new
settings.

```bash
vagrant destroy -f mesos-slave1 && vagrant up mesos-slave1
```

## Quick Start

1. [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)

1. [Install Vagrant](http://www.vagrantup.com/downloads.html)

1. (Optional for external volumes) Disable authentication for VirtualBox and start the SOAP Web Service.

  ```bash
  VBoxManage setproperty websrvauthlibrary null
  /Applications/VirtualBox.app/Contents/MacOS/vboxwebsrv -H 0.0.0.0 -v
  ```

1. Clone this repository

  ```bash
  git clone https://github.com/emccode/vagrant
  cd vagrant/playa-mesos
  ```

1. Make sure tests pass

  ```bash
  bin/test
  ```

1. Start the VM

  ```bash
  vagrant up
  ```

1. Connect to the Mesos Web UI on [10.141.141.10:5050](http://10.141.141.10:5050) and the Marathon Web UI on [10.141.141.10:8080](http://10.141.141.10:8080)

1. SSH to the VM

  ```bash
  vagrant ssh mesos-master
  ps -eaf | grep mesos
  exit
  ```

1. Halt the VM

  ```bash
  vagrant halt
  ```

1. Destroy the VM

  ```bash
  vagrant destroy
  ```

## Building the Mesos box image (optional)

1. Install [Packer][9]

  Installing Packer is not completely automatic. Once you have downloaded and
  extracted Packer, you must update your search path so that the `packer`
  executable can be found.

  ```bash
  # EXAMPLE - PACKER LOCATION MUST BE ADJUSTED
  export PATH=$PATH:/path/where/i/extracted/packer/archive/
  ```

1. Destroy any existing VM

  ```bash
  vagrant destroy
  ```

1. Build the Vagrant box image

  ```bash
  bin/build
  ```

1. Start the VM using the local box image

  ```bash
  vagrant up
  ```

The build is controlled with the following files:

* [config.json][21]
* [packer/packer.json][22]
* [lib/scripts/*][23]

For additional information on customizing the build, or creating a new profile,
see [Configuration][15] and the [Packer Documentation][20].

## External Volume Examples
There are two personalities being advertised from the external volume driver.
The first is for native Docker volumes through the `docker` Volume Driver name.
This is where a Docker containerizer is being used.

```bash
docker run -ti --volume-driver=docker -v test:/test busybox
df /test
exit
```

The second is through the Mesos containerizer through the `mesos` Volume Driver
name.  See the following Marathon example `job.json` file.  

```json
{
  "id": "hello-play",
  "cmd": "while [ true ] ; do touch /tmp/hello ; sleep 5 ; done",
  "mem": 32,
  "cpus": 0.1,
  "instances": 1,
  "env": {
    "DVDI_VOLUME_NAME": "test2",
    "DVDI_VOLUME_DRIVER": "mesos",
    "DVDI_VOLUME_OPTS": "size=5"
  }
}
```

Start the job interactively through Marathon.

```bash
vagrant ssh mesos-master
http post http://127.0.0.1:8080/v2/apps < job.json
```

## Documentation

* [Configuration][15]
* [Common Tasks][16]
* [Troubleshooting][17]
* [Known Issues][18]
* [To Do][19]

## Similar Projects

* [vagrant-mesos](https://github.com/everpeace/vagrant-mesos): Vagrant
  provisioning with multinode and EC2 support
* [babushka-mesos](https://github.com/parolkar/mesos-babushka): It is [Babushka](http://babushka.me/) based provisioning of Mesos Cluster which can help you demonstrate [potential](http://vimeo.com/110914075) of mesos.

## Authors

* [Jeremy Lingmann](https://github.com/lingmann) ([@lingmann](https://twitter.com/lingmann))
* [Jason Dusek](https://github.com/solidsnack) ([@solidsnack](https://twitter.com/solidsnack))

VMware Support: [Fabio Rapposelli](https://github.com/frapposelli) ([@fabiorapposelli](https://twitter.com/fabiorapposelli))


[1]: http://incubator.apache.org/mesos/ "Apache Mesos"
[2]: http://github.com/mesosphere/marathon "Marathon"
[3]: http://jenkins-ci.org/ "Jenkins"
[4]: http://zookeeper.apache.org/ "Apache Zookeeper"
[5]: http://www.virtualbox.org/ "VirtualBox"
[6]: http://www.vagrantup.com/ "Vagrant"
[7]: http://www.ansibleworks.com "Ansible"
[8]: https://github.com/mesosphere/playa-mesos "Playa Mesos"
[9]: http://www.packer.io "Packer"
[13]: http://mesosphere.io/downloads "Mesosphere Downloads"
[14]: http://www.ubuntu.com "Ubuntu"
[15]: doc/config.md "Configuration"
[16]: doc/common_tasks.md "Common Tasks"
[17]: doc/troubleshooting.md "Troubleshooting"
[18]: doc/known_issues.md "Known Issues"
[19]: doc/to_do.md "To Do"
[20]: http://www.packer.io/docs "Packer Documentation"
[21]: config.json "config.json"
[22]: packer/packer.json "packer.json"
[23]: lib/scripts "scripts"
[24]: https://github.com/emccode/rexray "REX-Ray"
[25]: https://github.com/emccode/mesos-module-dvdi "mesos-module-dvdi"
