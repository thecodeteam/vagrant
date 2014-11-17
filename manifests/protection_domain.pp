
class scaleio::protection_domain (
  $mdm_ip                  = $scaleio::params::mdm_ip,
  $components              = $scaleio::params::components,
  $sio_sds_device          = $scaleio::params::sio_sds_device
) {

    if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == 'Running' {
      if($sio_sds_device) {
        $sio_sds_device.keys.each |$node| {
          $sds = $sio_sds_device[$node]
          $protection_domain = $sds['protection_domain']      

          exec { "Enable Protection Domain ${protection_domain} for SDS ${node}":
            command => "scli --add_protection_domain --mdm_ip ${mdm_ip[0]} --protection_domain_name '${protection_domain}'",
            path    => '/bin',
            unless  => "scli --query_all --mdm_ip ${mdm_ip[0]} | grep \"^Protection Domain ${protection_domain}\"",
            require => Class['::scaleio::login']
          }
        }
      } else { notify {'Protection Domain - sio_sdc_volume not specified':} } 
    } else { notify {'Protection Domain - Not specified as secondary MDM or MDM not running':} }
  }
