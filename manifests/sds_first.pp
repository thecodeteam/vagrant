class scaleio::sds_first (
  $mdm_ip                  = $scaleio::params::mdm_ip,
  $components              = $scaleio::params::components,
  $sio_sds_device          = $scaleio::params::sio_sds_device
) {

  if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == "Running" {

    if($sio_sds_device) {
      $sio_sds_device.keys.each |$node| {
        $sds = $sio_sds_device[$node]
        $key_0 = $sds['devices'].keys[0]
        $sds['devices'].keys.each |$device_path| {
          $device = $sds['devices'][$device_path] 
          $storage_pool  = $device['storage_pool']
          if($storage_pool) { $storage_pool_name = "--storage_pool_name '${storage_pool}'" }
          if $device_path == $key_0 { 
            exec { "Add SDS ${node} for first device ${device_path}": 
              command => "scli --add_sds --mdm_ip ${mdm_ip[0]} --sds_ip ${sds['ip']} --sds_name ${node} --protection_domain_name '${sds['protection_domain']}' --device_path ${device_path} ${storage_pool_name}",
              path    => '/bin',
              unless  => "scli --query_sds --mdm_ip ${mdm_ip[0]} --sds_name ${node}",
              require => Class['::scaleio::login']
            }
          } else { notify {"${node} ${device[0]}": } }
        }
      }
    } else { notify {'SDS_FIRST - No sio_sds_device specified':} }
  } else { notify {'SDS_FIRST - Not specified as secondary MDM or MDM not running':} }

}

