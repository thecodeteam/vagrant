
class scaleio::map_volume inherits scaleio {
  $mdm_ip                  = $scaleio::mdm_ip
  $components              = $scaleio::components
  $sio_sdc_volume          = $scaleio::sio_sdc_volume

  if $mdm_ip[1] in $ip_address_array and 'mdm' in $components and $scaleio_mdm_state == "Running" {
	  if($sio_sdc_volume) {
		  $sio_sdc_volume.keys.each |$sdc_volume| {
		  	$size_gb = $sio_sdc_volume[$sdc_volume]['size_gb']
		  	$protection_domain = $sio_sdc_volume[$sdc_volume]['protection_domain']
		  	$sio_sdc_volume[$sdc_volume]['sdc_ip'].each |$sdc_ip| {
			    exec { "Add Volume ${sdc_volume} to SDC ${sdc_ip}":
			      command => "scli --map_volume_to_sdc --mdm_ip ${mdm_ip[0]} --volume_name ${sdc_volume} --sdc_ip ${sdc_ip} --allow_multi_map",
			      path    => '/bin',
			      unless  => "scli --query_volume --mdm_ip ${mdm_ip[0]} --volume_name ${sdc_volume} | grep SDC | grep 'IP: ${sdc_ip}'",
			      require => Class[ '::scaleio::login' ]
			    }
			}
		  }
	  } else { notify { 'No volume specified or not configured as SDC': } }
	} else { notify {'Not on the secondary MDM or mdm not running':} }

}
