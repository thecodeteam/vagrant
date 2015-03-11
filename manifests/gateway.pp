
class scaleio::gateway (
  $components  = $scaleio::params::components,
  $mdm_ip      = $scaleio::params::mdm_ip,
  $gw_password = $scaleio::params::gw_password
){
  
  if 'gw' in $components {

    file_line { 'Set MDM IP addresses':
      ensure  => present,
      line    => "mdm.ip.addresses=${mdm_ip[0]};${mdm_ip[1]}",
      path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
      match   => '^mdm.ip.addresses=.*',
    } ->

    service { "scaleio-gateway":
      ensure  => 'running',
      enable  => true,
    } ~>

    exec { 'Set gateway admin password':
      command => "java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar --reset_password '${gw_password}' --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties",
      path => "/etc/alternatives",
      refreshonly => true,
    } ~>
    
    exec { 'Manually restart scaleio-gateway':
      command     => "service scaleio-gateway restart",
      path        => '/sbin',
      refreshonly => true,
    }
  }

}
