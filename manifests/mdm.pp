
class scaleio::mdm inherits scaleio {

  $enable_cluster_mode     = $scaleio::enable_cluster_mode
  $cluster_name            = $scaleio::cluster_name
  $password                = $scaleio::password
  $tb_ip                   = $scaleio::tb_ip
  $version                 = $scaleio::version
  $default_password        = $scaleio::default_password
  $mdm_ip                  = $scaleio::mdm_ip
  $components              = $scaleio::components
  $sio_sdc_volume          = $scaleio::sio_sdc_volume

  if 'mdm' in $components {
    file_line { 'Append line for mdm_ip to /etc/environment':
        path => '/etc/environment',
        match => "^mdm_ip=",
        line => "mdm_ip=${join($mdm_ip,',')}",
    } ->

    if $mdm_ip[0] in $ip_address_array {
      notify {'This is the primary MDM':} ->
      if $scaleio_mdm_state == 'Running' and !$scaleio_primary_ip {
        exec { 'Add Primary MDM':
          command => "scli --mdm --add_primary_mdm --primary_mdm_ip ${mdm_ip[0]} --mdm_management_ip ${mdm_ip[0]} --accept_license",
          path    => '/bin',
        }
      } else { notify {'Skipped Add Primary MDM':} }
    } else { notify {'Not primary MDM':} } ->

    if $mdm_ip[1] in $ip_address_array {
      notify { "scaleio_secondary_ip = '${scaleio_secondary_ip}'":}  ->
      notify { "scaleio_mdm_state = '${scaleio_mdm_state}'":}  ->
      notify { "default_password: $default_passwod, password: $password": } ->
      notify { "MDMs: $mdm_ip": } ->
      # !facter represents a missing facter, hence a first puppet run before mdm service
      if $scaleio_mdm_state == 'Running' and !$scaleio_secondary_ip {
        exec { '1st Login':
          command => "scli --mdm_ip ${mdm_ip[0]} --login --username admin --password '${default_password}'",
          path    => '/bin',
        } ->
        exec { 'Set 1st Password':
          command => "scli --mdm_ip ${mdm_ip[0]} --set_password --old_password admin --new_password '${password}'",
          path    => '/bin',
        } ->
        exec { '1st Login New Password':
          command => "scli --mdm_ip ${mdm_ip[0]} --login --username admin --password '${password}'",
          path    => '/bin',
        } ->
        exec { 'Add Secondary MDM':
          command => "scli --add_secondary_mdm --mdm_ip ${mdm_ip[0]} --secondary_mdm_ip ${mdm_ip[1]}",
          path    => '/bin',
        }
      }  else { notify {'Skipped Password Set and 2nd MDM Add':} }
    } else { notify {'Skipped MDM Configuration - Part One':} } ->

    Class["::scaleio::login"] ->

    if $mdm_ip[1] in $ip_address_array and $scaleio_mdm_state == 'Running' {
      #using mdm_ip versus scaleio_primary_ip since scaleio_primary_ip may not be populated if first run
      notify {'This is the secondary MDM':} ->
      notify {"scaleio_tb_ip= '${scaleio_tb_ip}'":} ->
      if !$scaleio_tb_ip or $scaleio_tb_ip == "N/A" {
        exec { 'Add TB':
          command => "scli --add_tb --mdm_ip ${mdm_ip[0]} --tb_ip ${tb_ip}",
          path    => '/bin',
          require => Class['::scaleio::login']
        }
      } else { notify {'Tie-Breaker already exists':} } ->

      if $enable_cluster_mode {
        exec { 'Switch to Cluster Mode':
          command => "scli --mdm_ip ${mdm_ip[0]} --switch_to_cluster_mode",
          path    => '/bin',
          onlyif  => "scli --query_cluster --mdm_ip ${mdm_ip[0]} | grep ' Mode: Single'",
          require => Class['::scaleio::login']
        }
      } else { notify {'Cluster Mode not required':} } ->

      if $cluster_name {
        exec { 'Rename Cluster':
          command => "scli --mdm_ip ${mdm_ip[0]} --rename_system --new_name '${cluster_name}'",
          path    => '/bin',
          unless  => "scli --query_cluster --mdm_ip ${mdm_ip[0]} | grep \"Name: ${cluster_name}\"",
          require => Class['::scaleio::login']
        }
      } else { notify {'Cluster Name not specified':} }

    } else { notify {'Skipped MDM Configuration - Part Two':} }
  }
}
