
class scaleio::storage_pool (
  $mdm_ip                  = $scaleio::params::mdm_ip,
  $components              = $scaleio::params::components,
  $sio_sds_device          = $scaleio::params::sio_sds_device,
  $storage_pool            = $scaleio::params::storage_pool
) {

    if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == 'Running' {
      if($sio_sds_device) {
        $sio_sds_device.keys.each |$node| {
          $sds = $sio_sds_device[$node]
          $protection_domain = $sds['protection_domain']
          $sds['devices'].keys.each |$device_path| {
            $device = $sds['devices'][$device_path] 
            $storage_pool = $device['storage_pool']
            if($storage_pool) {
              exec { "Enable storage pool '${storage_pool}'' for protection domain ${protection_domain} and SDS ${node} and device {$device_path}":
                command => "scli --add_storage_pool --mdm_ip ${mdm_ip[0]} --protection_domain_name '${protection_domain}' --storage_pool_name '${storage_pool}'",
                path    => '/bin',
                unless  => "scli --query_storage_pool --mdm_ip ${mdm_ip[0]} --protection_domain_name '${protection_domain}' --storage_pool_name '${storage_pool}'",
                require => Class['::scaleio::login']
              }
            }            
          }        

        }
      } else { notify {'Storage Pool - sio_sdc_volume not specified':} } 
    } else { notify {'Storage Pool - Not specified as secondary MDM or MDM not running':} }
  }
