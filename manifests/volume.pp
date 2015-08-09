
class scaleio::volume inherits scaleio {
  $mdm_ip                  = $scaleio::mdm_ip
  $components              = $scaleio::components
  $sio_sdc_volume          = $scaleio::sio_sdc_volume

	if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == "Running" {

	  if($sio_sdc_volume) {
		  $sio_sdc_volume.keys.each |$sdc_volume| {
		  	$size_gb = $sio_sdc_volume[$sdc_volume]['size_gb']
		  	$protection_domain = $sio_sdc_volume[$sdc_volume]['protection_domain']
		  	$storage_pool = $sio_sdc_volume[$sdc_volume]['storage_pool']
			if($storage_pool) { $storage_pool_name = "--storage_pool_name '${storage_pool}'" }
		    exec { "Add Volume ${sdc_volume}":
		      command => "scli --add_volume --mdm_ip ${mdm_ip[0]} --size_gb ${size_gb} --volume_name ${sdc_volume} --protection_domain_name '${protection_domain}' ${storage_pool_name}",
		      path    => '/bin',
		      unless  => "scli --query_volume --mdm_ip ${mdm_ip[0]} --volume_name ${sdc_volume}",
		      require => Class['::scaleio::login']
		    }
		  }
	  } else { notify { 'VOLUME - sio_sdc_volume not specified': } }
	} else { notify {'VOLUME - Not specified as secondary MDM or MDM not running':} }

}
