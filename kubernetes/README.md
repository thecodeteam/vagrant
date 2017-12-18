vagrant-kubernetes
---------------

### Description

Automatically deploy Kubernetes in an isolated environment on top of VirtualBox to test containers with persistent applications using ScaleIO. This is intended for testing functionality of Kubernetes 1.9.0 and how it can utilize ScaleIO as a storage platform via the csi-scaleio plugin.

Environment Details:

- Three CentOS 7.3 nodes
- Kubernetes 1.9.0
- ScaleIO 2.0.1

### Requirements:

- VirtualBox 5
- Vagrant
- 8GB+ memory


### Usage

Set the following environment variables depending on your needs:

 - `K8S_VERSION` - Default is `1.9.0`. Set to version tag of Kubernetes release you would like to install.
 - `NODE_MEMORY` - Default is `3072`. Recommended memory is at least 1024MB for node01 and node02. Master will always use 2048MB
 - `SCALEIO_INSTALL` - Default is `true`. If `true` will deploy a 3-node ScaleIO cluster.
 - `VERIFY_FILES` - Default is `true`. This will verify the ScaleIO package is available for download.

Start cluster in 3 steps:
1. `git clone https://github.com/thecodeteam/vagrant`
2. `cd vagrant/kubernetes`
3. `vagrant up` (if you have more than one Vagrant Provider on your machine run `vagrant up --provider virtualbox` instead)

### SSH

To get into any of the nodes, run the following from the vagrant/kubernetes directory:
- `vagrant ssh master`
- `vagrant ssh node01`
- `vagrant ssh node02`.

### Kubernetes Example

1. `vagrant up`
2. `vagrant ssh master`
3. `./tmux.sh`
4. `kubectl apply -f csi-scaleio`
5. `./pvc-create.sh vol01`
6. `kubectl get pvc`
7. `kubectl get pv`
8. `kubectl apply -f redis01.yaml`

### ScaleIO GUI

The ScaleIO GUI is automatically extracted and put into the `vagrant/kubernetes/scaleio-gui` directory, just run `run.sh` and it should start up. You will need Java JRE as a dependency. Connect to your instance at 192.168.50.11 with the credentials admin/Scaleio123


### Troubleshooting

If anything goes wrong during the deployment, run `vagrant destroy -f` to remove all the VMs and then `vagrant up` again to restart the deployment.

### Contribution Rules

Create a fork of the project into your own repository. Make all your necessary changes and create a pull request with a description on what was added or removed and details explaining the changes in lines of code. If approved, project owners will merge it.

### Support

Please file bugs and issues on the [GitHub issues page](https://github.com/thecodeteam/vagrant/issues). This is to help keep track and document everything related to this repo. For general discussions and further support you can join the [{code} Community Slack](http://community.thecodeteam.com/) and ask questions in the #kubernetes, #project-csi, and #scaleio channels. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.
