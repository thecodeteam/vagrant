# Created by Jonas Rosland, @virtualswede & Matt Cowger, @mcowger
# Modified to work with ScaleIO IM by Magnus Nilsson, @swevm
# Many thanks to this post by James Carr: http://blog.james-carr.org/2013/03/17/dynamic-vagrant-nodes/

# vagrant box
vagrantbox="centos_6.5"

# vagrant box url
vagrantboxurl="https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box"

# scaleio admin password
password="Scaleio123"
# add your domain here
domain = 'scaleio.local'

# add your nodes here
nodes = ['tb', 'mdm1', 'mdm2']

# add your IPs here
network = "192.168.102"

clusterip = "#{network}.10"
tbip = "#{network}.11"
firstmdmip = "#{network}.12"
secondmdmip = "#{network}.13"

# version of installation package
version = "1.31-1277.3"

#OS Version of package
os="el6"

# installation folder
siinstall = "/opt/scaleio/siinstall"

# packages folder
packages = "/opt/scaleio/siinstall/ECS/packages"
# package name, was ecs for 1.21, is now EMC-ScaleIO from 1.30
packagename = "EMC-ScaleIO"

# fake device
device = "/home/vagrant/scaleio1"

# loop through the nodes and set hostname
scaleio_nodes = []
subnet=10
nodes.each { |node_name|
  (1..1).each {|n|
    subnet += 1
    scaleio_nodes << {:hostname => "#{node_name}"}
  }
}

Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?("vagrant-proxyconf")
    #config.proxy.http     = "http://proxy.example.com:3128/"
    #config.proxy.https    = "http://proxy.example.com:3128/"
    #config.proxy.no_proxy = "localhost,127.0.0.1,.example.com"
  end
  scaleio_nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = "#{vagrantbox}"
      node_config.vm.box_url = "#{vagrantboxurl}"
      node_config.vm.host_name = "#{node[:hostname]}.#{domain}"
      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "1024"]
      end
      if node[:hostname] == "tb"
        node_config.vm.network "private_network", ip: "#{tbip}"
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/tb.sh"
          s.args   = "-o #{os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -i #{siinstall}"
        end
      end

      if node[:hostname] == "mdm1"
        node_config.vm.network "private_network", ip: "#{firstmdmip}"
        node_config.vm.network "forwarded_port", guest: 6611, host: 6611
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/mdm1.sh"
          s.args   = "-o #{os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -i #{siinstall} -p #{password}"
        end
      end

      if node[:hostname] == "mdm2"
        node_config.vm.network "private_network", ip: "#{secondmdmip}"
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/mdm2.sh"
          s.args   = "-o #{os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -i #{siinstall} -t #{tbip} -p #{password}"
        end
      end
    end
  end
end
