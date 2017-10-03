#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -o|--os)
    OS="$2"
    shift
    ;;
    -zo|--zipos)
    ZIP_OS="$2"
    shift
    ;;
    -d|--device)
    DEVICE="$2"
    shift
    ;;
    -i|--installpath)
    INSTALLPATH="$2"
    shift
    ;;
    -v|--version)
    VERSION="$2"
    shift
    ;;
    -n|--packagename)
    PACKAGENAME="$2"
    shift
    ;;
    -f|--firstmdmip)
    FIRSTMDMIP="$2"
    shift
    ;;
    -s|--secondmdmip)
    SECONDMDMIP="$2"
    shift
    ;;
    -tb|--tbip)
    TBIP="$2"
    shift
    ;;
    -p|--password)
    PASSWORD="$2"
    shift
    ;;
    -c|--clusterinstall)
    CLUSTERINSTALL="$2"
    shift
    ;;
    -dk|--dockerinstall)
    DOCKERINSTALL="$2"
    shift
    ;;
    -r|--rexrayinstall)
    REXRAYINSTALL="$2"
    shift
    ;;
    -ds|--swarminstall)
    SWARMINSTALL="$2"
    shift
    ;;
    -ms|--mesosinstall)
    MESOSINSTALL="$2"
    shift
    ;;
    -vf|--verifyfiles)
    VERIFYFILES="$2"
    shift
    ;;
    -k8s|--k8sinstall)
    K8SINSTALL="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done
echo DEVICE  = "${DEVICE}"
echo INSTALL PATH     = "${INSTALLPATH}"
echo VERSION    = "${VERSION}"
echo OS    = "${OS}"
echo PACKAGENAME    = "${PACKAGENAME}"
echo FIRSTMDMIP    = "${FIRSTMDMIP}"
echo SECONDMDMIP    = "${SECONDMDMIP}"
echo TBIP    = "${TBIP}"
echo CLUSTERINSTALL = "${CLUSTERINSTALL}"
echo DOCKERINSTALL     = "${DOCKERINSTALL}"
echo REXRAYINSTALL     = "${REXRAYINSTALL}"
echo SWARMINSTALL     = "${SWARMINSTALL}"
echo MESOSINSTALL     = "${MESOSINSTALL}"
echo K8SINSTALL     = "${K8SINSTALL}"
echo VERIFYFILES     = "${VERIFYFILES}"
echo ZIP_OS    = "${ZIP_OS}"

VERSION_MAJOR=`echo "${VERSION}" | awk -F \. {'print $1'}`
VERSION_MINOR=`echo "${VERSION}" | awk -F \. {'print $2'}`
VERSION_MINOR_FIRST=`echo $VERSION_MINOR | awk -F "-" {'print $1'}`
VERSION_MAJOR_MINOR=`echo $VERSION_MAJOR"."$VERSION_MINOR_FIRST`
VERSION_MINOR_SUB=`echo $VERSION_MINOR | awk -F "-" {'print $2'}`
VERSION_MINOR_SUB_FIRST=`echo $VERSION_MINOR_SUB | head -c 1`
VERSION_SUMMARY=`echo $VERSION_MAJOR"."$VERSION_MINOR_FIRST"."$VERSION_MINOR_SUB_FIRST`

echo VERSION_MAJOR = $VERSION_MAJOR
echo VERSION_MAJOR_MINOR = $VERSION_MAJOR_MINOR
echo VERSION_SUMMARY = $VERSION_SUMMARY

echo "Checking Interface State: enp0s8"
INTERFACE_STATE=$(cat /sys/class/net/enp0s8/operstate)
if [ "${INTERFACE_STATE}" == "down" ]; then
  echo "Bringing Up Interface: enp0s8"
  ifup enp0s8
fi

echo "Adding Nodes to /etc/hosts"
echo "192.168.50.11 master" >> /etc/hosts
echo "192.168.50.12 node01" >> /etc/hosts
echo "192.168.50.13 node02" >> /etc/hosts

truncate -s 100GB ${DEVICE}
yum install unzip numactl libaio wget bc socat -y

cd /vagrant

DIR=`unzip -n -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep $ZIP_OS | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`

echo "Entering directory /vagrant/scaleio/$DIR"
cd /vagrant/scaleio/$DIR

MDMRPM=`ls -1 | grep "\-mdm\-"`
SDSRPM=`ls -1 | grep "\-sds\-"`
SDCRPM=`ls -1 | grep "\-sdc\-"`

if [ "${CLUSTERINSTALL}" == "true" ]; then
  echo "Installing MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=0 rpm -Uv $MDMRPM 2>/dev/null
  echo "Installing SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null

  scli --mdm_ip ${FIRSTMDMIP} --create_mdm_cluster --master_mdm_ip ${FIRSTMDMIP} --master_mdm_management_ip ${FIRSTMDMIP} --master_mdm_name mdm1 --accept_license --approve_certificate
  sleep 10
  scli --mdm_ip ${FIRSTMDMIP} --login --username admin --password admin --approve_certificate
  while [ $? -ne 0 ] ; do echo "Trying to login again.."; scli --mdm_ip ${FIRSTMDMIP} --login --username admin --password admin --approve_certificate ; done
  scli --mdm_ip ${FIRSTMDMIP} --set_password --old_password admin --new_password ${PASSWORD} --approve_certificate
  scli --mdm_ip ${FIRSTMDMIP} --login --username admin --password ${PASSWORD} --approve_certificate
  scli --mdm_ip ${FIRSTMDMIP} --add_standby_mdm --new_mdm_ip ${SECONDMDMIP} --mdm_role manager --new_mdm_management_ip ${SECONDMDMIP} --new_mdm_name mdm2
  scli --mdm_ip ${FIRSTMDMIP} --add_standby_mdm --new_mdm_ip ${TBIP} --mdm_role tb --new_mdm_name tb
  scli --mdm_ip ${FIRSTMDMIP} --switch_cluster_mode --cluster_mode 3_node --add_slave_mdm_name mdm2 --add_tb_name tb
  scli --mdm_ip ${FIRSTMDMIP} --rename_system --new_name cluster1
  scli --mdm_ip ${FIRSTMDMIP} --add_protection_domain --protection_domain_name pdomain
  scli --mdm_ip ${FIRSTMDMIP} --add_storage_pool --protection_domain_name pdomain --storage_pool_name pool1
  scli --mdm_ip ${FIRSTMDMIP} --add_sds --sds_ip ${FIRSTMDMIP} --device_path ${DEVICE} --no_test --sds_name sds1 --protection_domain_name pdomain --storage_pool_name pool1
  scli --mdm_ip ${FIRSTMDMIP} --add_sds --sds_ip ${SECONDMDMIP} --device_path ${DEVICE} --no_test --sds_name sds2 --protection_domain_name pdomain --storage_pool_name pool1
  scli --mdm_ip ${FIRSTMDMIP} --add_sds --sds_ip ${TBIP} --device_path ${DEVICE} --no_test --sds_name sds3 --protection_domain_name pdomain --storage_pool_name pool1
  sleep 5
  echo "Installing SDC $SDCRPM"
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv $SDCRPM 2>/dev/null
fi

if [ "${DOCKERINSTALL}" == "true" ]; then
  echo "Installing Docker"
  yum install -y yum-utils
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum makecache fast
  yum install docker-ce -y
  echo "Setting Docker service to Start on boot"
  systemctl enable docker
  systemctl start docker
  echo "Setting Docker Permissions"
  usermod -aG docker vagrant
  echo "Restarting Docker"
  systemctl restart docker
fi

if [ "${REXRAYINSTALL}" == "true" ]; then
  echo "Installing REX-Ray"
  /vagrant/scripts/rexray.sh
fi

if [ "${SWARMINSTALL}" == "true" ]; then
  echo "Configuring Host as Docker Swarm Worker"
  WORKER_TOKEN=`cat /vagrant/swarm_worker_token`
	docker swarm join --listen-addr ${TBIP} --advertise-addr ${TBIP} --token=$WORKER_TOKEN ${FIRSTMDMIP}
  #echo "Configuring Host as Docker Swarm Manager - will be demoted to Worker later by master"
  #docker swarm init --listen-addr ${TBIP} --advertise-addr ${TBIP}
  #docker swarm join-token -q worker > /vagrant/swarm_worker_token
  #docker swarm join-token -q manager > /vagrant/swarm_manager_token
fi

if [ "${MESOSINSTALL}" == "true" ]; then
  /vagrant/scripts/mesos-node.sh
fi

if [ "${K8SINSTALL}" == "true" ]; then
  /vagrant/scripts/k8s/k8s-node.sh
fi

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  #tail -1 $1
fi
