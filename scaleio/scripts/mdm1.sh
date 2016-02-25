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
    -p|--password)
    PASSWORD="$2"
    shift
    ;;
    -c|--clusterinstall)
    CLUSTERINSTALL="$2"
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
echo CLUSTERINSTALL     = "${CLUSTERINSTALL}"
echo ZIP_OS    = "${ZIP_OS}"

VERSION_MAJOR=`echo "${VERSION}" | awk -F \. {'print $1'}`
VERSION_MAJOR_MINOR=`echo "${VERSION}" | awk -F \. {'print $1"."$2'}`
VERSION_MINOR=`echo "${VERSION}" | awk -F \. {'print $2'}`
VERSION_MINOR_FIRST=`echo $VERSION_MINOR | awk -F "-" {'print $1'}`
VERSION_MINOR_SUB=`echo $VERSION_MINOR | awk -F "-" {'print $2'}`
VERSION_MINOR_SUB_FIRST=`echo $VERSION_MINOR_SUB | head -c 1`
VERSION_SUMMARY=`echo $VERSION_MAJOR"."$VERSION_MINOR_FIRST"."$VERSION_MINOR_SUB_FIRST`

echo VERSION_MAJOR = $VERSION_MAJOR
echo VERSION_SUMMARY = $VERSION_SUMMARY


truncate -s 100GB ${DEVICE}
yum install numactl libaio -y
yum install java-1.8.0-openjdk -y
cd /vagrant/scaleio/ScaleIO_"$VERSION_SUMMARY"_"$ZIP_OS"_Download

if [ "${CLUSTERINSTALL}" == "True" ]; then
  rpm -Uv ${PACKAGENAME}-mdm-${VERSION}.${OS}.x86_64.rpm
  rpm -Uv ${PACKAGENAME}-sds-${VERSION}.${OS}.x86_64.rpm
  MDM_IP=${FIRSTMDMIP},${SECONDMDIP} rpm -Uv ${PACKAGENAME}-sdc-${VERSION}.${OS}.x86_64.rpm
  scli --mdm --add_primary_mdm --primary_mdm_ip ${FIRSTMDMIP} --accept_license
fi

# Always install ScaleIO Gateway
export GATEWAY_ADMIN_PASSWORD=${PASSWORD}
unzip -o "/vagrant/scaleio/ScaleIO_"$VERSION_SUMMARY"_Gateway_for_Linux_Download.zip" -d /vagrant/scaleio
cd /vagrant/scaleio/ScaleIO_"$VERSION_SUMMARY"_Gateway_for_Linux_Download
rpm -Uv ${PACKAGENAME}-gateway-${VERSION}.noarch.rpm

sed -i 's/mdm.ip.addresses=/mdm.ip.addresses='${FIRSTMDMIP}','${SECONDMDMIP}'/' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar \
  --reset_password $GATEWAY_ADMIN_PASSWORD \
  --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
service scaleio-gateway start
service scaleio-gateway restart

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
