Summary - vagrant-chef-scaleio
==============================

This repository houses a Vagrantfile and Chef configuration files that allow you to deploy, _upgrade_ and scale-up/out a ScaleIO storage environment.  It makes use of the ```chef-server``` to perform host and ScaleIO configuration and ```Vagrant``` to deploy a Chef Server, configure Chef Clients with ScaleIO module, and then deploy additional defined ScaleIO nodes.

With this Vagrantfile, it is possible to deploy pre-defined ScaleIO clusters.  Further, the ScaleIO chef recipe allows you to deploy massive descriptive ScaleIO clusters across any environment, physical or virtual in minutes.

About the Demo
--------------
Demo requirements:

  - [Homebrew](http://brew.sh) - homebrew is available on the Mac platform only
  - [tmux](http://tmux.github.io) - A terminal multiplexer. The demo script uses this to open up connections to the demo nodes
  - [Virtualbox](http://virtualbox.org/)
  - [Vagrant](http://vagrantup.com)

The demonstration script has been provided can be used directly on Mac platforms, or can be used as a reference for manual demonstrations.

Instructions
------------
- git clone https://github.com/codedellemc/vagrant
- cd vagrant-chef-scaleio
- `./demo/start.sh`

Contributors/Sources
--------------------
- Aaron Spiegel
- Eoghan Kelleher
- Jonas Rosland
- Clint Kitson

Contributing
------------
We encourage the community to actively contribute to this module.
- Fork the repository
- Clone
- Add original repository as upstream
- Checkout new branch
- Commit changes
- Push to your repository
- Issue pull request

Licensing
---------
Licensed under the Apache License, Version 2.0 (the “License”); you may not use this file except in compliance with the License. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>  

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Support
-------
Please file bugs and issues at the <a href="https://github.com/codedellemc/vagrant/issues">Github issues</a> page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.

# Maintainer
- Aaron Spiegel
