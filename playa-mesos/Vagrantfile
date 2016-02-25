# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing
VAGRANTFILE_API_VERSION = '2'

PM_ROOT = File.dirname(__FILE__)
PM_CONFIG = File.expand_path(File.join(File.dirname(__FILE__), 'config.json'))
require_relative File.join(PM_ROOT, 'lib', 'ruby', 'playa_settings')
pmconf = PlayaSettings.new(PM_CONFIG)

box_url = "#{pmconf.base_url}/#{pmconf.box_name}-#{pmconf.platform}.box"

# #############################################################################
# Vagrant VM Definitions
# #############################################################################

ENV['VAGRANT_DEFAULT_PROVIDER'] = pmconf.platform

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  hosts = pmconf.hosts

  hosts.each_key do |hostname|
    config.vm.define hostname do |node|

      node.vm.hostname = hostname

      hostip = hosts[hostname]["ip"]

      # Create a private network, which allows host-only access to the machine
      # using a specific IP.
      node.vm.network :private_network, ip: hostip

      # If true, then any SSH connections made will enable agent forwarding.
      # Default value: false
      node.ssh.forward_agent = true

      # Every Vagrant virtual environment requires a box to build off of.
      node.vm.box = pmconf.box_name

      # There are two levels of caching here.
      # 1. If pmconf.box_local is set, then the file referenced by pmconf.box_url
      #    was found in the Packer build path (packer/builds/*.box) and Vagrant's
      #    vm.box_url is set to that path. To force retrieving the box
      #    from the URL again, simply remove the Packer builds directory.
      # 2. Vagrant only retrieves box images from vm.box_url if it does not have
      #    a local copy in ~/.vagrant.d/boxes/$BOX_NAME. These can be removed
      #    with the command: "vagrant box remove $BOX_NAME"
      node.vm.box_url = pmconf.box_local ? pmconf.box_local : box_url

      # Note: You'll want a decent amount of memory for your mesos master/slave
      # VM. The strict minimum, at least while the VM is provisioned, is the
      # amount necessary to compile mesos and the jenkins plugin. 2048m+ is
      # recommended.  The CPU count can be lowered, but you may run into issues
      # running the Jenkins Mesos Framework if you do so.
      node.vm.provider :virtualbox do |vb|
        vb.name = hostname
        vb.customize ['modifyvm', :id, '--memory', hosts[hostname]["vm_ram"] ? hosts[hostname]["vm_ram"] : pmconf.vm_ram]
        vb.customize ['modifyvm', :id, '--cpus',   hosts[hostname]["vm_cpus"] ? hosts[hostname]["vm_cpus"] : pmconf.vm_cpus]
        vb.customize ["storagectl", :id, "--add", "sata", "--controller", "IntelAhci", "--name", "SATA", "--portcount", 30, "--hostiocache", "on"]
        vb.customize ["modifyvm", :id, "--macaddress1", "auto"]
      end
      node.vm.provider :vmware_fusion do |v|
        v.vmx['memsize'] = pmconf.vm_ram
        v.vmx['numvcpus'] = pmconf.vm_cpus
      end
      node.vm.provider :vmware_workstation do |v|
        v.vmx['memsize'] = pmconf.vm_ram
        v.vmx['numvcpus'] = pmconf.vm_cpus
      end

      # Make the project root available to the guest VM.
      # node.vm.synced_folder '.', '/vagrant'

      dir = "#{ENV['PWD']}/Volumes"

      master_ip = hosts["mesos-master"]["ip"]

      # Only provision if explicitly request with 'provision' or 'up --provision'
      if ARGV.any? { |arg| arg =~ /^(--)?provision$/ }
        node.vm.provision :shell do |shell|
          shell.path = 'lib/scripts/common/mesosflexinstall'
          arg_array = ['--slave-hostname', hostip]

          # If mesos_release exists in the node.json file, pass the '--rel'
          # argument and a version to mesosflexinstall. Otherwise, do nothing.
          if pmconf.instance_variable_get(:@settings).include?('mesos_release')
            arg_array += ['--rel', pmconf.mesos_release]
          end

          # Using an array for shell args requires Vagrant 1.4.0+
          # TODO: Set as array directly when Vagrant 1.3 support is dropped
          shell.args = arg_array.join(' ')
        end
      end

      if hostname == "mesos-master"
        node.vm.provision "shell", inline: <<-SHELL
          echo #{master_ip} > /etc/mesos-master/advertise_ip
          service mesos-master restart
          apt-get install -y httpie
        SHELL
      end

      if hosts[hostname]["disable_slave"] == true
        node.vm.provision "shell", inline: <<-SHELL
          service mesos-slave stop
          echo manual > /etc/init/mesos-slave.override
        SHELL
      end

      if hostname != "mesos-master"
        node.vm.provision "shell", inline: <<-SHELL
          service marathon stop
          echo manual > /etc/init/marathon.override
          service chronos stop
          echo manual > /etc/init/chronos.override
          service mesos-master stop
          echo manual > /etc/init/zookeeper.override
          service zookeeper stop
          echo manual > /etc/init/mesos-master.override
          service mesos-slave stop

          rm -Rf /tmp/mesos/meta

          echo #{hostip} > /etc/mesos-slave/hostname
          echo #{hostip} > /etc/mesos-slave/ip
          echo MASTER=zk://#{master_ip}:2181/mesos > /etc/default/mesos-slave
          service mesos-slave start
        SHELL
      end

      if hosts[hostname]["external_volumes"] == true
        node.vm.provision "shell", inline: <<-SHELL
          sudo curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s staged

          sudo tee -a /etc/rexray/config.yml << EOF
rexray:
  storageDrivers:
  - virtualbox
  modules:
    default-docker:
      host: "unix:///run/docker/plugins/docker.sock"
      rexray:
        volume:
          mount:
            preempt: true
    mesos:
      type: docker
      host: "unix:///run/docker/plugins/mesos.sock"
      rexray:
        volume:
          mount:
            preempt: true
            ignoreUsedCount: true
virtualbox:
  endpoint: http://10.0.2.2:18083
  tls: false
  volumePath: /Users/user/VirtualBox Volumes
  controllerName: SATA
EOF

          sed -i '/.*volumePath.*/c\\\x20\x20volumePath: \"#{dir}\"' /etc/rexray/config.yml

          wget -nv --directory-prefix=/usr/lib https://github.com/emccode/mesos-module-dvdi/releases/download/v0.4.0/libmesos_dvdi_isolator-0.26.0.so 1&>2
          sudo tee -a /usr/lib/dvdi-mod.json << EOF
{
  "libraries": [
    {
      "file": "/usr/lib/libmesos_dvdi_isolator-0.26.0.so",
      "modules": [
        {
          "name": "com_emccode_mesos_DockerVolumeDriverIsolator"
        }
      ]
    }
  ]
}
EOF

          echo file:///usr/lib/dvdi-mod.json > /etc/mesos-slave/modules
          echo posix/cpu,posix/mem,com_emccode_mesos_DockerVolumeDriverIsolator > /etc/mesos-slave/isolation
          curl -sSL https://dl.bintray.com/emccode/dvdcli/install | sh -

          sudo rexray start
        SHELL
      end

      if !hosts[hostname].has_key?("disable_slave") || hosts[hostname]["disable_slave"] == false
        node.vm.provision "shell", inline: <<-SHELL
          service mesos-slave restart
        SHELL
      end

    end
  end
end
