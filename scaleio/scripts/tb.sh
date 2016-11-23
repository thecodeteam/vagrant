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
    -c|--clusterinstall)
    CLUSTERINSTALL="$2"
    shift
    ;;
    -r|--rexrayinstall)
    REXRAYINSTALL="$2"
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
echo CLUSTERINSTALL = "${CLUSTERINSTALL}"
echo REXRAYINSTALL     = "${REXRAYINSTALL}"
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

truncate -s 100GB ${DEVICE}
yum install unzip numactl libaio wget -y
cd /vagrant
if [ ! -f "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" ];
then
  echo "Downloading SIO package from downloads.emc.com"
  wget -nv http://downloads.emc.com/emc-com/usa/ScaleIO/ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip -O ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip
fi

echo "Uncompressing SIO package"
unzip -n "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" -d /vagrant/scaleio/

DIR=`unzip -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep $ZIP_OS | awk -F'/' '{print $1 "/" $2 "/" $3}' | head -1`

echo "Entering directory /vagrant/scaleio/$DIR"
cd /vagrant/scaleio/$DIR

MDMRPM=`ls -1 | grep "\-mdm\-"`
SDSRPM=`ls -1 | grep "\-sds\-"`
SDCRPM=`ls -1 | grep "\-sdc\-"`

if [ "${CLUSTERINSTALL}" == "True" ]; then
  echo "Installing MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=0 rpm -Uv $MDMRPM 2>/dev/null
  echo "Installing SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null
  echo "Installing SDC $SDCRPM"
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv $SDCRPM 2>/dev/null
fi

if [ "${REXRAYINSTALL}" == "True" ]; then
  echo "Installing Docker"
  curl -sSL https://get.docker.com/ | sh
  echo "Setting Docker Permissions"
  usermod -aG docker vagrant
  echo "Setting Docker service to Start on boot"
  chkconfig docker on
  echo "Installing REX-Ray"
  /vagrant/scripts/rexray.sh
  service docker restart
fi

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
