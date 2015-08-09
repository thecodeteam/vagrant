
class scaleio::os_prep inherits scaleio {


  Firewall {
    before => Class['scaleio::firewall::post'],
    require => Class['scaleio::firewall::pre'],
  }

  class { ['scaleio::firewall::pre', 'scaleio::firewall::post']: }

  if 'gw' in $scaleio::components {
    include 'scaleio::firewall::gwfirewall'
  }

  if 'lia' in $scaleio::components {
    include 'scaleio::firewall::liafirewall'
  }

  if 'mdm' in $scaleio::components {
    include 'scaleio::firewall::mdmfirewall'
  }

  if 'sds' in $scaleio::components {
    include 'scaleio::firewall::sdsfirewall'
  }

  if 'tb' in $scaleio::components {
    include 'scaleio::firewall::tbfirewall'
  }

  package { 'numactl' :
    ensure => present,
  }  ->

  package {'libaio' :
    ensure => present
  } ->

  if ($scaleio::sds_network) {
    file_line { 'Append a FACTER_scaleio_sds_network line to /etc/environment':
        path => '/etc/environment',
        match => "^FACTER_scaleio_sds_network=",
        line => "FACTER_scaleio_sds_network=${scaleio::sds_network}",
    }
  } else {
    notify { 'sds_network not set': }
  } ->

  if ('sds' in $scaleio::components and $scaleio::sds_ssd_env_flag) {
    file_line { 'Append a CONF=IOPS line to /etc/environment':
        path => '/etc/environment',
        match => "^CONF=",
        line => "CONF=IOPS",
    }
  } else {
    notify { 'sds not in components and/or sds_ssd_env_flag not set': }
  } ->

  file { "${scaleio::path}" :
    ensure => directory,
    owner  => root,
    group  => root,
  } ->

  if 'gui' in $scaleio::components or 'gw' in $scaleio::components {
    if !$javaversion or $javaversion < "1.6" {
      class{ 'java':
        distribution => 'jdk',
      }
    } else {
      notify {  "Java version up to date ${javaversion}": }
    }
  } else {
    notify {  'gui not specified or jdk at correct version':  }
  }


}
