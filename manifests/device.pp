
class scaleio::device (
	$sio_sds_device = $scaleio::params::sio_sds_device
){
	if $sio_sds_device {
        $sds = $sio_sds_device[$fqdn]
        if($sds) {
	        $sds['devices'].keys.each |$device_path| {
	          $device = $sds['devices'][$device_path] 
			  notify {"Checking ${fqdn} device ${device_path}":}
			  exec {"Truncate ${fqdn} device ${device_path}":
			  	command => "truncate -s ${device['size']} ${device_path}",
			  	logoutput => true,
			  	path => '/usr/bin',
			  	onlyif => [
			  		        "/usr/bin/test ! -f ${device_path}"
			  			  ],
			  }
			    
			}
		} else { notify {"SDS ${fqdn} not configured for device": } }
	  
	}
}