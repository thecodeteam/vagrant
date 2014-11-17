
class scaleio::callhome (
	$components   = $scaleio::params::components,
	$callhome_cfg = $scaleio::params::callhome_cfg
){
  if 'callhome' in $components {
    file {'Callhome configuration' :
      ensure  => present,
      path    => '/opt/emc/scaleio/callhome/cfg/conf.txt',
      owner   => 'root',
      mode    => '0644',
      content => template('scaleio/callhome.erb'),
    }
  } else { notify {'Callhome - callhome component not specified':}}
}