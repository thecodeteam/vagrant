
class scaleio::callhome inherits scaleio {

  if 'callhome' in $scaleio::components {
    file {'Callhome configuration' :
      ensure  => present,
      path    => '/opt/emc/scaleio/callhome/cfg/conf.txt',
      owner   => 'root',
      mode    => '0644',
      content => template('scaleio/callhome.erb'),
    }
  } else {
    notify {  'Callhome - callhome component not specified':  }
  }
}
