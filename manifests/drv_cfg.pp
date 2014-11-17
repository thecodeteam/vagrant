
class scaleio::drv_cfg (
	$mdm_ip              = $scaleio::params::mdm_ip,
) {
	if $scaleio::params::mdm_ip {
	    $drv_mdm = "mdm ${join($mdm_ip,' ')}"
	    file { "/bin/emc":
	      ensure => "directory",
	    } -> 
	    file { "/bin/emc/scaleio":
	      ensure => "directory",
	    } -> 
	    file { "/bin/emc/scaleio/drv_cfg.txt":
	      ensure => present,
	    } -> 
	    file_line { 'Append a line to drv_cfg.txt':
	      path => '/bin/emc/scaleio/drv_cfg.txt',  
	      match => "^mdm ",
	      line => $drv_mdm,
	    }
	}
}