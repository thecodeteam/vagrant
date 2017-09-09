echo "Install and Configure Mesos Node"
echo "Setting Local IP as Environment Variable"
ENP0S8IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
echo "Stopping firewalld Service"
systemctl stop firewalld
systemctl disable firewalld
echo "Add Mesos Repos"
rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
export LIBPROCESS_IP=$ENP0S8IP
echo "Installing and Configuring Mesos Node"
yum -y install mesos
systemctl stop mesos-master
systemctl disable mesos-master
bash -c "echo 'docker,mesos' > /etc/mesos-slave/containerizers"
bash -c "echo 'docker' > /etc/mesos-slave/image_providers"
bash -c "echo 'filesystem/linux,docker/runtime' > /etc/mesos-slave/isolation"
bash -c "echo '15mins' > /etc/mesos-slave/executor_registration_timeout"
bash -c "echo zk://192.168.50.11:2181/mesos > /etc/mesos/zk"
bash -c "echo $ENP0S8IP > /etc/mesos-slave/hostname"
bash -c "echo $ENP0S8IP > /etc/mesos-slave/ip"
systemctl enable mesos-slave
systemctl restart mesos-slave
