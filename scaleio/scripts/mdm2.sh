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
    -t|--tbip)
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
echo PASSWORD    = "${PASSWORD}"
echo CLUSTERINSTALL   =  "${CLUSTERINSTALL}"
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


#echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
truncate -s 100GB ${DEVICE}
yum install numactl libaio -y

cd /vagrant
DIR=`unzip -l "ScaleIO_Linux_v"$VERSION_MAJOR_MINOR".zip" | awk '{print $4}' | grep $ZIP_OS | awk -F'/' '{print $1 "/" $2}' | head -1`

echo "Entering directory /vagrant/scaleio/$DIR"
cd /vagrant/scaleio/$DIR

MDMRPM=`ls -1 | grep "\-mdm\-"`
SDSRPM=`ls -1 | grep "\-sds\-"`
SDCRPM=`ls -1 | grep "\-sdc\-"`

if [ "${CLUSTERINSTALL}" == "True" ]; then
  echo "Installing MDM $MDMRPM"
  MDM_ROLE_IS_MANAGER=1 rpm -Uv $MDMRPM 2>/dev/null
  echo "Installing SDS $SDSRPM"
  rpm -Uv $SDSRPM 2>/dev/null
  echo "Installing SDC $SDCRPM"
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv $SDCRPM 2>/dev/null

  scli --mdm_ip ${FIRSTMDMIP} --create_mdm_cluster --master_mdm_ip ${FIRSTMDMIP} --master_mdm_management_ip ${FIRSTMDMIP} --master_mdm_name mdm1 --accept_license --approve_certificate
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
  scli --mdm_ip ${FIRSTMDMIP} --add_volume --size_gb 8 --volume_name vol1 --protection_domain_name pdomain --storage_pool_name pool1
  while [ $? -ne 0 ] ; do echo "Trying to add volume again.."; sleep 1; scli --mdm_ip ${FIRSTMDMIP} --add_volume --size_gb 8 --volume_name vol1 --protection_domain_name pdomain --storage_pool_name pool1 ; done
  scli --mdm_ip ${FIRSTMDMIP} --map_volume_to_sdc --volume_name vol1 --sdc_ip ${FIRSTMDMIP} --allow_multi_map
  scli --mdm_ip ${FIRSTMDMIP} --map_volume_to_sdc --volume_name vol1 --sdc_ip ${SECONDMDMIP} --allow_multi_map
  scli --mdm_ip ${FIRSTMDMIP} --map_volume_to_sdc --volume_name vol1 --sdc_ip ${TBIP} --allow_multi_map
fi


if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
