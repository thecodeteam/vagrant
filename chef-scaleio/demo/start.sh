#!/usr/bin/env bash

brew install wget p7zip

wget -O ./gui/EMC-ScaleIO-gui-2.0-12000-122.noarch.rpm \
    "http://130820808912778549.public.ecstestdrive.com/ScaleIO/EMC-ScaleIO-gui-2.0-12000.122.noarch.rpm"
7z x -o./gui ./gui/EMC-ScaleIO-gui-2.0-12000-122.noarch.rpm
7z x -o./gui ./gui/EMC-ScaleIO-gui-2.0-12000.122.noarch.cpio
chmod +x ./gui/opt/emc/scaleio/gui/run.sh

# Start Chef Server and ScaleIO nodes
vagrant up

# Copy knife private key to host
cp ./secrets/admin.pem ./.chef

# Setup Chef server
knife ssl fetch
knife ssl check

# Upload cookbook dependencies
knife cookbook site install ohai
knife cookbook site install sysctl
knife cookbook upload ohai sysctl scaleio

# Upload ScaleIO Databag, which defines cluster config & topology
knife data bag create scaleio
knife data bag from file scaleio ./data_bags

# Bootstrap Chef managed ScaleIO nodes
for i in centos1 centos2 centos3 centos4
do
    echo "Bootstraping ${i}..."
    port=`vagrant ssh-config ${i} |grep Port | awk '{print $2}'`
    iden=`vagrant ssh-config ${i} |grep IdentityFile | awk '{print $2}'`
    knife bootstrap localhost --ssh-port $port --ssh-user vagrant --sudo --identity-file $iden -N ${i}
    alias knife-ssh-$i="knife ssh localhost --ssh-port $port --manual-list --ssh-user vagrant --identity-file $iden"
done

read -p "Press [Enter] to start add chef recipes to 3 nodes..."

echo "knife node run_list add centos1 'recipe[scaleio::primary_mdm]' 'recipe[scaleio::sds]' 'recipe[scaleio::sdc]'"
knife node run_list add centos1 'recipe[scaleio::primary_mdm]' 'recipe[scaleio::sds]' 'recipe[scaleio::sdc]'

for i in centos2 centos3
do
    echo "knife node run_list add $i 'recipe[scaleio::standby_mdm]' 'recipe[scaleio::sds]' 'recipe[scaleio::sdc]'"
    knife node run_list add $i 'recipe[scaleio::standby_mdm]' 'recipe[scaleio::sds]' 'recipe[scaleio::sdc]'
done

read -p "Press [Enter] to start node Chef clients..."

./demo/open_nodes.sh

read -p "Press [Enter] to monitor cluster..."

./gui/opt/emc/scaleio/gui/run.sh
