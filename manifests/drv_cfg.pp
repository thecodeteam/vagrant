
class scaleio::drv_cfg inherits scaleio {
	$mdm_ip              = $scaleio::mdm_ip
	$drv_cfg_file				 = $scaleio::drv_cfg_file

  if $mdm_ip {
	    $drv_mdm = "mdm ${join($mdm_ip,' ')}"
			file { "/bin/emc":
	      ensure => "directory",
	    } ->
	    file { "/bin/emc/scaleio":
	      ensure => "directory",
	    } -> 
	    file { "$drv_cfg_file":
	      ensure => present,
	    } ->
	    file_line { 'Append a line to drv_cfg.txt':
	      path => $drv_cfg_file,
	      match => "^mdm ",
	      line => $drv_mdm,
	    }
	}
}
