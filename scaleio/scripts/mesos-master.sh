echo "Installing Mesos Master and Marathon"
echo "Setting Local IP as Environment Variable"
ENP0S8IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
echo "Stopping firewalld Service"
systemctl stop firewalld
systemctl disable firewalld
echo "Add Mesos Repos"
rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
echo "Installing and Configuring Zookeeper"
export LIBPROCESS_IP=$ENP0S8IP
yum -y install mesosphere-zookeeper
bash -c "echo 1 > /var/lib/zookeeper/myid"
bash -c "echo server.1=$ENP0S8IP:2888:3888 >> /etc/zookeeper/conf/zoo.cfg"
systemctl enable zookeeper
systemctl start zookeeper
echo "Installing and Configuring Mesos Master"
yum -y install mesos
bash -c "echo zk://$ENP0S8IP:2181/mesos > /etc/mesos/zk"
bash -c "echo 1 > /etc/mesos-master/quorum"
bash -c "echo $ENP0S8IP > /etc/mesos-master/hostname"
bash -c "echo $ENP0S8IP > /etc/mesos-master/ip"
bash -c "echo rexcluster > /etc/mesos-master/cluster"
systemctl enable mesos-master
systemctl stop mesos-slave
systemctl disable mesos-slave
systemctl restart mesos-master
echo "Installing and Configuring Marathon"
yum -y install marathon
mkdir -p /etc/marathon/conf/
bash -c "echo $ENP0S8IP > /etc/marathon/conf/hostname"
bash -c "echo external_volumes > /etc/marathon/conf/enable_features"
systemctl enable marathon
systemctl restart marathon
