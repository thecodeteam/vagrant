Vagrant.configure("2") do |config|
# Configure Vagrant to use a minimal CentOS box
  config.vm.box = "centos_6.4"
  config.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v0.1.0/centos64-x86_64-20131030.box"

################################################################################################################################
# For the shell commands to work, make sure you have the ECS-1.20-0.357.el6-install file in the Vagrant folder
################################################################################################################################

# Create the ScaleIO tie-breaker
  config.vm.define "tb" do |tb|
    tb.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
    tb.vm.box = "centos_6.4"
    tb.vm.network "private_network", ip: "192.168.50.13"
    tb.vm.hostname = "tb"
    tb.vm.provision "shell",
      inline: "truncate -s 100GB /home/vagrant/scaleio1 && yum install numactl python-paramiko -y && mkdir -p /opt/scaleio/siinstall && cp /vagrant/ECS-1.20-0.357.el6-install /opt/scaleio/siinstall && cd /opt/scaleio/siinstall && bash ECS-1.20-0.357.el6-install && rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-tb-1.20-0.357.el6.x86_64.rpm && rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-sds-1.20-0.357.el6.x86_64.rpm && MDM_IP=192.168.50.10 rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-sdc-1.20-0.357.el6.x86_64.rpm"
  end

# Create the first ScaleIO Meta-Data Manager
  config.vm.define "mdm1" do |mdm1|
    mdm1.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
    mdm1.vm.box = "centos_6.4"
    mdm1.vm.network "private_network", ip: "192.168.50.11"
    mdm1.vm.hostname = "mdm1"
    mdm1.vm.provision "shell",
      inline: "truncate -s 100GB /home/vagrant/scaleio1 && yum install numactl python-paramiko -y && mkdir -p /opt/scaleio/siinstall && cp /vagrant/ECS-1.20-0.357.el6-install /opt/scaleio/siinstall && cd /opt/scaleio/siinstall && bash ECS-1.20-0.357.el6-install && rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-mdm-1.20-0.357.el6.x86_64.rpm && rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-sds-1.20-0.357.el6.x86_64.rpm && MDM_IP=192.168.50.10 rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-sdc-1.20-0.357.el6.x86_64.rpm && scli --mdm --add_primary_mdm --interface_name eth0 --virtual_ip 192.168.50.10 --primary_mdm_ip 192.168.50.11 --accept_license"
  end

# Create the second ScaleIO Meta-Data Manager
# Make sure you edit YOURLICENSEHERE in the "shell" block to use your ScaleIO license
  config.vm.define "mdm2" do |mdm2|
    mdm2.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
    mdm2.vm.box = "centos_6.4"
    mdm2.vm.network "private_network", ip: "192.168.50.12"
    mdm2.vm.hostname = "mdm2"
    mdm2.vm.provision "shell",
      inline: "truncate -s 100GB /home/vagrant/scaleio1 && yum install numactl python-paramiko -y && mkdir -p /opt/scaleio/siinstall && cp /vagrant/ECS-1.20-0.357.el6-install /opt/scaleio/siinstall && cd /opt/scaleio/siinstall && bash ECS-1.20-0.357.el6-install && rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-mdm-1.20-0.357.el6.x86_64.rpm && rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-sds-1.20-0.357.el6.x86_64.rpm && MDM_IP=192.168.50.10 rpm -Uvh /opt/scaleio/siinstall/ECS/packages/ecs-sdc-1.20-0.357.el6.x86_64.rpm && scli --add_secondary_mdm --mdm_ip 192.168.50.10 --interface_name eth0 --secondary_mdm_ip 192.168.50.12 && scli --add_tb --mdm_ip 192.168.50.10 --tb_ip 192.168.50.13 && scli --switch_to_cluster_mode --mdm_ip 192.168.50.10 && scli --mdm --set_license --license=YOURLICENSEHERE --mdm_ip 192.168.50.10 && scli --add_protection_domain --mdm_ip 192.168.50.10 --protection_domain_name pdomain && scli --add_sds --mdm_ip 192.168.50.10 --sds_ip 192.168.50.11 --device_name /home/vagrant/scaleio1 --sds_name sds1 --protection_domain_name pdomain && scli --add_sds --mdm_ip 192.168.50.10 --sds_ip 192.168.50.12 --device_name /home/vagrant/scaleio1 --sds_name sds2 --protection_domain_name pdomain && scli --add_sds --mdm_ip 192.168.50.10 --sds_ip 192.168.50.13 --device_name /home/vagrant/scaleio1 --sds_name sds3 --protection_domain_name pdomain && echo \"Waiting for 30 seconds to make sure the SDSs are created\" && sleep 30 && scli --add_volume --mdm_ip 192.168.50.10 --size_gb 3 --volume_name vol1 --protection_domain_name pdomain && scli --map_volume_to_sdc --mdm_ip 192.168.50.10 --volume_name vol1 --sdc_ip 192.168.50.10 && scli --map_volume_to_sdc --mdm_ip 192.168.50.10 --volume_name vol1 --sdc_ip 192.168.50.12 && scli --map_volume_to_sdc --mdm_ip 192.168.50.10 --volume_name vol1 --sdc_ip 192.168.50.13"
  end

end
