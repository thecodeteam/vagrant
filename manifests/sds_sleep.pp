class scaleio::sds_sleep inherits scaleio {
  $mdm_ip                  = $scaleio::mdm_ip
  $components              = $scaleio::components
  $sio_sds_device          = $scaleio::sio_sds_device

  if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == "Running" {

    if($sio_sds_device) {
      $sio_sds_device.keys.each |$node| {
        exec {"Add SDS ${node} Sleep 30":
                command => 'sleep 30',
                path => '/bin',
                require => Class['::scaleio::login'],
                unless  => "/usr/bin/test ! `scli --query_sds --mdm_ip ${mdm_ip[0]} --sds_name ${node} | grep ' Path: ' -A1 | grep 'State: Initia'`",
        }
      }
    } else { notify {'SDS_SLEEP - No sio_sds_device specified':} }
  } else { notify {'SDS_SLEEP - Not specified as secondary MDM or MDM not running':} }
}
