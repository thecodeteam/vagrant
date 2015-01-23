# Created by Jonas Rosland, @virtualswede & Matt Cowger, @mcowger
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
network = "192.168.50"

clusterip = "#{network}.10"
tbip = "#{network}.11"
firstmdmip = "#{network}.12"
secondmdmip = "#{network}.13"

# version of installation package
version = "1.31-258.2.el6"

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
        node_config.vm.provision "shell",
          inline: "truncate -s 100GB #{device} && yum install numactl libaio -y && mkdir -p #{siinstall} && cp /vagrant/#{packagename}-*-#{version}.* #{siinstall} && cd #{siinstall} && rpm -Uvh #{packagename}-tb-#{version}.x86_64.rpm && rpm -Uvh #{packagename}-sds-#{version}.x86_64.rpm && MDM_IP=#{firstmdmip},#{secondmdmip} rpm -Uvh #{packagename}-sdc-#{version}.x86_64.rpm"
      end

      if node[:hostname] == "mdm1"
        node_config.vm.network "private_network", ip: "#{firstmdmip}"
        node_config.vm.network "forwarded_port", guest: 6611, host: 6611
        node_config.vm.provision "shell",
          inline: "truncate -s 100GB #{device} && yum install numactl libaio -y && mkdir -p #{siinstall} && cp /vagrant/#{packagename}-*-#{version}.* #{siinstall} && cd #{siinstall} && rpm -Uvh #{packagename}-mdm-#{version}.x86_64.rpm && rpm -Uvh #{packagename}-sds-#{version}.x86_64.rpm && MDM_IP=#{firstmdmip},#{secondmdmip} rpm -Uvh #{packagename}-sdc-#{version}.x86_64.rpm && scli --mdm --add_primary_mdm --primary_mdm_ip #{firstmdmip} --accept_license"
      end

      if node[:hostname] == "mdm2"
        node_config.vm.network "private_network", ip: "#{secondmdmip}"
        node_config.vm.provision "shell",
          inline: "truncate -s 100GB #{device} && yum install numactl libaio -y && mkdir -p #{siinstall} && cp /vagrant/#{packagename}-*-#{version}.* #{siinstall} && cd #{siinstall} && rpm -Uvh #{packagename}-mdm-#{version}.x86_64.rpm && rpm -Uvh #{packagename}-sds-#{version}.x86_64.rpm && MDM_IP=#{firstmdmip},#{secondmdmip} rpm -Uvh #{packagename}-sdc-#{version}.x86_64.rpm && scli --login --mdm_ip #{firstmdmip} --username admin --password admin && scli --mdm_ip #{firstmdmip} --set_password --old_password admin --new_password #{password} && scli --mdm_ip #{firstmdmip} --login --username admin --password #{password} && scli --add_secondary_mdm --mdm_ip #{firstmdmip} --secondary_mdm_ip #{secondmdmip} && scli --add_tb --mdm_ip #{firstmdmip} --tb_ip #{tbip} && scli --switch_to_cluster_mode --mdm_ip #{firstmdmip} && scli --add_protection_domain --mdm_ip #{firstmdmip} --protection_domain_name pdomain && scli --add_sds --mdm_ip #{firstmdmip} --sds_ip #{firstmdmip} --device_path #{device} --sds_name sds1 --protection_domain_name pdomain && scli --add_sds --mdm_ip #{firstmdmip} --sds_ip #{secondmdmip} --device_path #{device} --sds_name sds2 --protection_domain_name pdomain && scli --add_sds --mdm_ip #{firstmdmip} --sds_ip #{tbip} --device_path #{device} --sds_name sds3 --protection_domain_name pdomain && echo \"Waiting for 30 seconds to make sure the SDSs are created\" && sleep 30 && scli --add_volume --mdm_ip #{firstmdmip} --size_gb 8 --volume_name vol1 --protection_domain_name pdomain && scli --map_volume_to_sdc --mdm_ip #{firstmdmip} --volume_name vol1 --sdc_ip #{firstmdmip} --allow_multi_map && scli --map_volume_to_sdc --mdm_ip #{firstmdmip} --volume_name vol1 --sdc_ip #{secondmdmip} --allow_multi_map && scli --map_volume_to_sdc --mdm_ip #{firstmdmip} --volume_name vol1 --sdc_ip #{tbip} --allow_multi_map"
      end
    end
  end
end
