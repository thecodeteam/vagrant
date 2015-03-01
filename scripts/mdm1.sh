#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -o|--os)
    OS="$2"
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
#echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
truncate -s 100GB ${DEVICE}
yum install numactl libaio -y
yum install java-1.7.0-openjdk -y
cd /vagrant
rpm -Uv ${PACKAGENAME}-mdm-${VERSION}.${OS}.x86_64.rpm
rpm -Uv ${PACKAGENAME}-sds-${VERSION}.${OS}.x86_64.rpm
export GATEWAY_ADMIN_PASSWORD=${PASSWORD}
rpm -Uv ${PACKAGENAME}-gateway-${VERSION}.noarch.rpm
MDM_IP=${FIRSTMDMIP},${SECONDMDIP} rpm -Uv ${PACKAGENAME}-sdc-${VERSION}.${OS}.x86_64.rpm
scli --mdm --add_primary_mdm --primary_mdm_ip ${FIRSTMDMIP} --accept_license

sed -i 's/mdm.ip.addresses=/mdm.ip.addresses='${FIRSTMDMIP}','${SECONDMDMIP}'/' /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
service scaleio-gateway restart

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
