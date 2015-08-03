class scaleio::sds inherits scaleio {
  $mdm_ip                  = $scaleio::mdm_ip
  $components              = $scaleio::components
  $sio_sds_device          = $scaleio::sio_sds_device

  if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == "Running" {

    if($sio_sds_device) {
      $sio_sds_device.keys.each |$node| {
        $sds = $sio_sds_device[$node]
        $sds['devices'].keys.each |$device_path| {
        $device = $sds['devices'][$device_path]
          $storage_pool = $device['storage_pool']
          if($storage_pool) { $storage_pool_name = "--storage_pool_name '${storage_pool}'" }
          exec { "Add SDS ${node} device ${device_path}":
            command => "scli --add_sds_device --mdm_ip ${mdm_ip[0]} --sds_ip ${sds['ip']} --device_path ${device_path} ${storage_pool_name}",
            path    => '/bin',
            unless  => "scli --query_sds --mdm_ip ${mdm_ip[0]} --sds_name ${node} | grep ' Path: ${device_path}'",
            require => Class['::scaleio::login']
          }
        }
      }
    } else { notify {'SDS - No sio_sds_device specified':} }
  } else { notify {'SDS - Not specified as secondary MDM or MDM not running':} }

}
