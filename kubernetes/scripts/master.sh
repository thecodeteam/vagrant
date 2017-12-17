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

mkdir -p /vagrant/cache

if [ ! -f /vagrant/cache/ssh_key ]; then
  ssh-keygen -b 2048 -t rsa -f /vagrant/cache/ssh_key -q -N ""
fi
cp /vagrant/cache/ssh_key /home/vagrant/.ssh/id_rsa
chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa
mkdir -p /root/.ssh && chmod 700 /root/.ssh
cp /vagrant/cache/ssh_key /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

yum makecache fast

if [ "${SCALEIO_INSTALL}" == "true" ]; then
  truncate -s 100GB /home/vagrant/scaleio_disk
  yum install unzip rsync socat tmux docker bc numactl libaio  -y
else
  yum install unzip rsync socat tmux docker -y
fi

sed -i '/MountFlags/,+1 d' /lib/systemd/system/docker.service

systemctl enable docker
systemctl start docker
sleep 5
systemctl status docker
sleep 5

if [ "${SCALEIO_INSTALL}" == "true" ]; then
  if [ "${VERIFY_FILES}" == "true" ]; then
    URL="http://downloads.emc.com/emc-com/usa/ScaleIO/ScaleIO_Linux_v2.0.zip"

    echo "Verifying that the SIO package is available from downloads.emc.com"
    echo "If you don't want this to happen set VERIFY_FILES to false in the Vagrantfile"
    if curl --output /dev/null --silent --head --fail "$URL"; then
      echo "URL exists: $URL. Continuing."
    else
      echo "URL does not exist: $URL. Please try to run \"vagrant up\" again."
      exit
    fi

    FILESIZE=`curl -sI $URL | grep Content-Length | awk '{print $2}' | tr -d $'\r' | bc -l`

    if [ "$FILESIZE" -lt 1 ]; then
      echo "The file on downloads.emc.com doesn't look correct. Please try to run \"vagrant up\" again."
      exit
    else
      echo "The file on downloads.emc.com is larger than 0 bytes. Continuing."
    fi

  fi

  cd /vagrant

  if [ "${VERIFY_FILES}" == "true" ]; then
    if [ -f "cache/ScaleIO_Linux_v2.0.zip" ]; then
      STOREDFILE=`wc -c <"cache/ScaleIO_Linux_v2.0.zip" | awk '{print $1}'`
      echo "Stored file size is" $STOREDFILE
      echo "File on downloads.emc.com is" $FILESIZE
      if [[ $FILESIZE -gt $STOREDFILE ]]; then
        echo "The file size of the stored ScaleIO zip is incorrect. Will remove and download the new one."
        rm "cache/ScaleIO_Linux_v2.0.zip"
      else
        echo "The file sizes of the stored ScaleIO zip and the zip file on downloads.emc.com are the same. Continuing."
      fi
    fi
  fi

  if [ ! -f "cache/ScaleIO_Linux_v2.0.zip" ]; then
    echo "Downloading ScaleIO_Linux_v2.0.zip from downloads.emc.com"
    cd /vagrant/cache
    curl -L -o /vagrant/cache/ScaleIO_Linux_v2.0.zip http://downloads.emc.com/emc-com/usa/ScaleIO/ScaleIO_Linux_v2.0.zip
  fi

  mkdir -p /vagrant/cache/scaleio
  SCALEIO_FILE_COUNT=`ls -l /vagrant/cache/scaleio | wc -l`
  if [[ ${SCALEIO_FILE_COUNT} -lt 10 ]]; then
    echo "Uncompressing SIO package"
    cd /vagrant/cache
    unzip -n ScaleIO_Linux_v2.0.zip -d scaleio-full

    SCALEIO_RPM_PATH=`unzip -n -l ScaleIO_Linux_v2.0.zip | awk '{print $4}' | grep RHEL_OEL7 | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`
    mv /vagrant/cache/scaleio-full/${SCALEIO_RPM_PATH}/* /vagrant/cache/scaleio
  fi
  cd /vagrant/cache/scaleio

  MDMRPM=`ls -1 | grep "\-mdm\-"`
  SDSRPM=`ls -1 | grep "\-sds\-"`
  SDCRPM=`ls -1 | grep "\-sdc\-"`

  echo "Installing ScaleIO MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=1 rpm -Uv $MDMRPM 2>/dev/nullmv
  echo "Installing ScaleIO SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null
  echo "Installing ScaleIO SDC $SDCRPM"
  MDM_IP=${MASTER_IP},${NODE01_IP} rpm -Uv $SDCRPM 2>/dev/null

  # Copy the ScaleIO GUI application to the /vagrant directory for easy access
  cd /vagrant
  if [ ! -d scaleio-gui ]; then
    DIR=`unzip -l /vagrant/cache/ScaleIO_Linux_v2.0.zip | awk '{print $4}' | grep GUI_for_Linux | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`
    cd /vagrant/cache/scaleio-full/$DIR
    GUIRPM=`ls -1 | grep rpm`
    rpm2cpio $GUIRPM | cpio -idmv
    rsync -qa opt/emc/scaleio/gui/* /vagrant/scaleio-gui
    rm -fr opt/
  fi
fi

rm -rf /vagrant/cache/scaleio-full


mkdir -p /vagrant/cache
cd /vagrant/cache

if [ ! -f docker-1.12.6.tgz ]; then
  echo "Downloading docker-1.12.6.tgz"
  curl -sLO https://get.docker.com/builds/Linux/x86_64/docker-1.12.6.tgz
  tar xvf docker-1.12.6.tgz
fi

if [ ! -f cni-plugins-amd64-v0.6.0.tgz ]; then
  echo "Downloading cni-plugins-amd64-v0.6.0.tgz"
  curl -sLO https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz
fi

if [ ! -f etcd-v3.2.8-linux-amd64.tar.gz ]; then
  echo "Downloading etcd-v3.2.8-linux-amd64.tar.gz"
  curl -sLO https://github.com/coreos/etcd/releases/download/v3.2.8/etcd-v3.2.8-linux-amd64.tar.gz
fi

if [ ! -f helm-v2.7.2-linux-amd64.tar.gz ]; then
  echo "Downloadind helm-v2.7.2-linux-amd64.tar.gz"
  curl -sLO https://storage.googleapis.com/kubernetes-helm/helm-v2.7.2-linux-amd64.tar.gz
fi

mkdir -p /vagrant/cache/k8s-${K8S_VERSION}
cd /vagrant/cache/k8s-${K8S_VERSION}
for file in kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy kubectl; do
  if [ ! -f ${file} ]; then
    echo "Downloading ${file}-${K8S_VERSION}"
    curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/${file}
    chmod +x ${file}
  fi
done
cd /vagrant

#Install Kubernetes Components
/vagrant/scripts/k8s-controller.sh -k8sv ${K8S_VERSION} -msip ${MASTER_IP} -n1ip ${NODE01_IP} -n2ip ${NODE02_IP} -si ${SCALEIO_INSTALL}

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  #tail -1 $1
fi
