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
    -k8|--k8install)
    K8INSTALL="$2"
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
echo CLUSTERINSTALL     = "${CLUSTERINSTALL}"
echo DOCKERINSTALL     = "${DOCKERINSTALL}"
echo REXRAYINSTALL     = "${REXRAYINSTALL}"
echo SWARMINSTALL     = "${SWARMINSTALL}"
echo MESOSINSTALL     = "${MESOSINSTALL}"
echo K8INSTALL     = "${K8INSTALL}"
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
echo "192.168.50.11  tb.scaleio.local tb" >> /etc/hosts
echo "192.168.50.13  mdm2.scaleio.local mdm2" >> /etc/hosts

truncate -s 100GB ${DEVICE}
yum install unzip numactl libaio rsync -y
yum install java-1.8.0-openjdk -y

cd /vagrant
DIR=`unzip -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep $ZIP_OS | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`

echo "Entering directory /vagrant/scaleio/$DIR"
cd /vagrant/scaleio/$DIR

MDMRPM=`ls -1 | grep "\-mdm\-"`
SDSRPM=`ls -1 | grep "\-sds\-"`
SDCRPM=`ls -1 | grep "\-sdc\-"`

if [ "${CLUSTERINSTALL}" == "true" ]; then
  echo "Installing MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=1 rpm -Uv $MDMRPM 2>/dev/null
  echo "Installing SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null
  echo "Installing SDC $SDCRPM"
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv $SDCRPM 2>/dev/null
fi

# Always install ScaleIO Gateway
cd /vagrant
DIR=`unzip -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep Gateway_for_Linux | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`
cd /vagrant/scaleio/$DIR
echo "Installing GATEWAY $GWRPM"
GWRPM=`ls -1 | grep x86_64`
GATEWAY_ADMIN_PASSWORD=${PASSWORD} rpm -Uv $GWRPM --nodeps 2>/dev/null

sed -i 's/security.bypass_certificate_check=false/security.bypass_certificate_check=true/' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
sed -i 's/mdm.ip.addresses=/mdm.ip.addresses='${FIRSTMDMIP}','${SECONDMDMIP}'/' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
service scaleio-gateway start
service scaleio-gateway restart

# Copy the ScaleIO GUI application to the /vagrant directory for easy access
cd /vagrant
DIR=`unzip -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep GUI_for_Linux | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`
cd /vagrant/scaleio/$DIR
GUIRPM=`ls -1 | grep rpm`
rpm2cpio $GUIRPM | cpio -idmv
rsync -a opt/emc/scaleio/gui /vagrant
rm -fr opt/

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
  echo "Configuring Host as Docker Swarm Manager and then demoting TB to a Swarm Worker"
  MANAGER_TOKEN=`cat /vagrant/swarm_manager_token`
	docker swarm join --listen-addr ${FIRSTMDMIP} --advertise-addr ${FIRSTMDMIP} --token=$MANAGER_TOKEN ${TBIP}
  docker node demote tb.scaleio.local
fi

if [ "${MESOSINSTALL}" == "true" ]; then
  /vagrant/scripts/mesos-master.sh
fi

if [ "${K8INSTALL}" == "true" ]; then
  /vagrant/scripts/k8/etcd.sh
  /vagrant/scripts/k8/k8controller.sh
fi

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  #tail -1 $1
fi
