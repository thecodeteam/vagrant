# -*- mode: ruby -*-
# vi: set ft=ruby :
# Created by Jonas Rosland, @virtualswede
# Many thanks to this post by James Carr: http://blog.james-carr.org/2013/03/17/dynamic-vagrant-nodes/

################################################################################################################################
# For the shell commands to work, make sure you have the ECS-1.21-0.20.el6-install file in the Vagrant folder
# Also make sure you edit the license below
################################################################################################################################

# add your license here
license="YOURLICENSEHERE"

# add your domain here
domain = 'scaleio.local'
 
# add your nodes here
nodes = ['tb', 'mdm1', 'mdm2']

# add your IPs here
network = "192.168.50"

clusterip = "#{network}.10"
tbip = "#{network}.11"
firstmdmip = "#{network}.12"
secondmdmip = "#{network}.13"

# version of installation package
version = "1.21-0.20.el6"

# installation folder
siinstall = "/opt/scaleio/siinstall"

# packages folder
packages = "/opt/scaleio/siinstall/ECS/packages"

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
  scaleio_nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = "centos_6.4"
      node_config.vm.box_url = 'https://github.com/2creatives/vagrant-centos/releases/download/v0.1.0/centos64-x86_64-20131030.box'
      node_config.vm.host_name = "#{node[:hostname]}.#{domain}"
      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "1024"]
      end
      if node[:hostname] == "tb"
        node_config.vm.network "private_network", ip: "#{tbip}"
        node_config.vm.provision "shell",
          inline: "truncate -s 100GB #{device} && yum install numactl libaio -y && mkdir -p #{siinstall} && cp /vagrant/ECS-#{version}-install #{siinstall} && cd #{siinstall} && bash ECS-#{version}-install && rpm -Uvh #{packages}/ecs-tb-#{version}.x86_64.rpm && rpm -Uvh #{packages}/ecs-sds-#{version}.x86_64.rpm && MDM_IP=#{clusterip} rpm -Uvh #{packages}/ecs-sdc-#{version}.x86_64.rpm"
      end  

      if node[:hostname] == "mdm1"
        node_config.vm.network "private_network", ip: "#{firstmdmip}"
        node_config.vm.provision "shell",
          inline: "truncate -s 100GB #{device} && yum install numactl libaio python-paramiko bash-completion -y && mkdir -p #{siinstall} && cp /vagrant/ECS-#{version}-install #{siinstall} && cd #{siinstall} && bash ECS-#{version}-install && rpm -Uvh #{packages}/ecs-mdm-#{version}.x86_64.rpm && rpm -Uvh #{packages}/ecs-sds-#{version}.x86_64.rpm && MDM_IP=#{clusterip} rpm -Uvh #{packages}/ecs-sdc-#{version}.x86_64.rpm && scli --mdm --add_primary_mdm --interface_name eth1 --virtual_ip #{clusterip} --primary_mdm_ip #{firstmdmip} --accept_license"
      end  

      if node[:hostname] == "mdm2"
        node_config.vm.network "private_network", ip: "#{secondmdmip}"
        node_config.vm.provision "shell",
          inline: "truncate -s 100GB #{device} && yum install numactl libaio python-paramiko bash-completion -y && mkdir -p #{siinstall} && cp /vagrant/ECS-#{version}-install #{siinstall} && cd #{siinstall} && bash ECS-#{version}-install && rpm -Uvh #{packages}/ecs-mdm-#{version}.x86_64.rpm && rpm -Uvh #{packages}/ecs-sds-#{version}.x86_64.rpm && MDM_IP=#{clusterip} rpm -Uvh #{packages}/ecs-sdc-#{version}.x86_64.rpm && scli --add_secondary_mdm --mdm_ip #{firstmdmip} --interface_name eth1 --secondary_mdm_ip #{secondmdmip} && scli --add_tb --mdm_ip #{clusterip} --tb_ip #{tbip} && scli --switch_to_cluster_mode --mdm_ip #{clusterip} && scli --mdm --set_license --license=#{license} --mdm_ip #{clusterip} && scli --add_protection_domain --mdm_ip #{clusterip} --protection_domain_name pdomain && scli --add_sds --mdm_ip #{clusterip} --sds_ip #{firstmdmip} --device_name #{device} --sds_name sds1 --protection_domain_name pdomain && scli --add_sds --mdm_ip #{clusterip} --sds_ip #{secondmdmip} --device_name #{device} --sds_name sds2 --protection_domain_name pdomain && scli --add_sds --mdm_ip #{clusterip} --sds_ip #{tbip} --device_name #{device} --sds_name sds3 --protection_domain_name pdomain && echo \"Waiting for 30 seconds to make sure the SDSs are created\" && sleep 30 && scli --add_volume --mdm_ip #{clusterip} --size_gb 3 --volume_name vol1 --protection_domain_name pdomain && scli --map_volume_to_sdc --mdm_ip #{clusterip} --volume_name vol1 --sdc_ip #{clusterip} && scli --map_volume_to_sdc --mdm_ip #{clusterip} --volume_name vol1 --sdc_ip #{secondmdmip} && scli --map_volume_to_sdc --mdm_ip #{clusterip} --volume_name vol1 --sdc_ip #{tbip}" 
      end      
    end
  end
end
