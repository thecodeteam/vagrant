class scaleio::login inherits scaleio {
  $password                = $scaleio::password
  $mdm_ip                  = $scaleio::mdm_ip
  $components              = $scaleio::components

  if 'mdm' in $components and $mdm_ip[1] in $ip_address_array {
	  exec { 'Normal Login Class':
	    command => "scli --mdm_ip ${mdm_ip[0]} --login --username admin --password '${password}'",
	    path    => '/bin',
      }
  } else { notify { 'Not logging in since not MDM': } }
}
