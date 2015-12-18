# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "jonasrosland/rexray"

  # Add a SATA controller with 30 ports to the VM, so REX-Ray can add disks on the fly
  config.vm.provider :virtualbox do |vb|
   vb.customize ["storagectl", :id, "--add", "sata", "--controller", "IntelAhci", "--name", "SATA", "--portcount", 30, "--hostiocache", "on"]
  end

  # Set the current $PWD as the place where you will
  # store the VMDKs that are attached to the VM.
  # Ugly code and will work on a fix later.
  dir = "echo #{ENV['PWD']} | sed 's/\\\//\\\\\\//g'"
  config.vm.provision "shell", inline: <<-SHELL
    #{dir} > /root/dir.txt
    sed -i 's/.*volumePath.*/  volumePath: '$(cat /root/dir.txt)' /g' /etc/rexray/config.yml
    rm -f /root/dir.txt
  SHELL
end
