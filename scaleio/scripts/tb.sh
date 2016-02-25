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
yum install numactl libaio wget -y
cd /vagrant
if [ ! -f "ScaleIO_Linux_"$VERSION_MAJOR".latest.zip" ];
then
  echo "Downloading SIO package from downloads.emc.com"
  wget -nv http://downloads.emc.com/emc-com/usa/ScaleIO/ScaleIO_Linux_"$VERSION_MAJOR".latest.zip -O ScaleIO_Linux_"$VERSION_MAJOR".latest.zip
fi
unzip -o "ScaleIO_Linux_"$VERSION_MAJOR".latest.zip" -d /vagrant/scaleio/
unzip -o "/vagrant/scaleio/ScaleIO_"$VERSION_SUMMARY"_"$ZIP_OS"_Download.zip" -d /vagrant/scaleio/
cd /vagrant/scaleio/ScaleIO_"$VERSION_SUMMARY"_"$ZIP_OS"_Download

if [ "${CLUSTERINSTALL}" == "True" ]; then
  rpm -Uv ${PACKAGENAME}-tb-${VERSION}.${OS}.x86_64.rpm
  rpm -Uv ${PACKAGENAME}-sds-${VERSION}.${OS}.x86_64.rpm
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv ${PACKAGENAME}-sdc-${VERSION}.${OS}.x86_64.rpm
fi

if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
