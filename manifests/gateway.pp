
class scaleio::gateway (
  $components  = $scaleio::params::components,
  $mdm_ip      = $scaleio::params::mdm_ip,
  $gw_password = $scaleio::params::gw_password
){
  
  if 'gw' in $components {

    service { "scaleio-gateway":
      ensure  => 'running',
      enable  => true,
    } -> 

    file_line { 'Set gateway admin password':
      ensure  => present,
      line    => "gateway-admin.password=${gw_password}",
      path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
      match   => '^gateway-admin.password=.*$',
    } ->
    
    file_line { 'Set MDM IP addresses':
      ensure  => present,
      line    => "mdm.ip.addresses=${mdm_ip[0]};${mdm_ip[1]}",
      path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
      match   => '^mdm.ip.addresses=.*',
    } ~>

    exec { 'Manually restart scaleio-gateway':
      command     => "service scaleio-gateway restart",
      path        => '/sbin',
    }
  }

}
