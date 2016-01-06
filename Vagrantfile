# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # Amount of nodes to start
  nodes = 2

  (1..nodes).each do |i|
    config.vm.define "rexray-#{i}" do |node|
      node.vm.box = "jonasrosland/rexray"

      # Add a SATA controlle with 30 ports to the VM, so REX-Ray can add disks on the fly
      node.vm.provider :virtualbox do |vb|
       vb.customize ["storagectl", :id, "--add", "sata", "--controller", "IntelAhci", "--name", "SATA", "--portcount", 30, "--hostiocache", "on"]
       vb.customize ["modifyvm", :id, "--macaddress1", "auto"]
      end

      # Set the current $PWD as the place where you will
      # store the VMDKs that are attached to the VM.
      dir = "#{ENV['PWD']}/Volumes"

      node.vm.provision "shell", inline: <<-SHELL
        ## Optionally remove REX-Ray
        #rpm -e rexray

        ## Optionally get latest stable REX-Ray
        #sudo curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s stable

        ## Optionally get latest release candidate REX-Ray
        #sudo curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s staged

        ## Optionally update the volume path for pwd Volumes dir
        sed -i '/.*volumePath.*/c\\\x20\x20volumePath: \"#{dir}\"' /etc/rexray/config.yml

        ## Optionally set preemption
        sed -i '/.*preempt.*/c\\\x20\x20\x20\x20\x20\x20preempt: true' /etc/rexray/config.yml

        /bin/systemctl start  docker.service
      SHELL
    end
  end
end
