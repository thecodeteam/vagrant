#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -k8sv|--K8S_VERSION)
    K8S_VERSION="$2"
    shift
    ;;
    -msip|--master_ip)
    MASTER_IP="$2"
    shift
    ;;
    -n1ip|--node01_ip)
    NODE01_IP="$2"
    shift
    ;;
    -n2ip|--node02_ip)
    NODE02_IP="$2"
    shift
    ;;
    -si|--scaleio_install)
    SCALEIO_INSTALL="$2"
    shift
    ;;
    -sp|--password)
    SCALEIO_PASSWORD="$2"
    shift
    ;;
    -vf|--verify_files)
    VERIFY_FILES="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done
echo K8S_VERSION = "${K8S_VERSION}"
echo MASTER_IP = "${MASTER_IP}"
echo NODE01_IP = "${NODE01_IP}"
echo NODE02_IP = "${NODE02_IP}"
echo SCALEIO_INSTALL = "${SCALEIO_INSTALL}"

echo "Checking Interface State: enp0s8"
INTERFACE_STATE=$(cat /sys/class/net/enp0s8/operstate)
if [ "${INTERFACE_STATE}" == "down" ]; then
  echo "Bringing Up Interface: enp0s8"
  ifup enp0s8
fi

echo "Adding Nodes to /etc/hosts"
echo "${MASTER_IP} master" >> /etc/hosts
echo "${NODE01_IP} node01" >> /etc/hosts
echo "${NODE02_IP} node02" >> /etc/hosts

cat /vagrant/cache/ssh_key.pub >> /home/vagrant/.ssh/authorized_keys
mkdir -p /root/.ssh
cat /vagrant/cache/ssh_key.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

yum makecache fast

if [ "${SCALEIO_INSTALL}" == "true" ]; then
  truncate -s 100GB /home/vagrant/scaleio_disk
  yum install unzip rsync socat docker numactl libaio -y
else
  yum install unzip rsync socat docker -y
fi

sed -i '/MountFlags/,+1 d' /lib/systemd/system/docker.service

systemctl enable docker
systemctl start docker
sleep 5
systemctl status docker
sleep 5

if [ "${SCALEIO_INSTALL}" == "true" ]; then
  cd /vagrant/cache/scaleio

  MDMRPM=`ls -1 | grep "\-mdm\-"`
  SDSRPM=`ls -1 | grep "\-sds\-"`
  SDCRPM=`ls -1 | grep "\-sdc\-"`

  echo "Installing ScaleIO MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=1 rpm -Uv $MDMRPM 2>/dev/null
  echo "Installing ScaleIO SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null
  echo "Installing ScaleIO SDC $SDCRPM"
  MDM_IP=${MASTER_IP},${NODE01_IP} rpm -Uv $SDCRPM 2>/dev/null
fi

#Install Kubernetes Components
/vagrant/scripts/k8s-node.sh -k8sv ${K8S_VERSION} -msip ${MASTER_IP} -n1ip ${NODE01_IP} -n2ip ${NODE02_IP}


if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  #tail -1 $1
fi
