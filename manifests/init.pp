
class scaleio (

  $enable_cluster_mode  = $scaleio::params::enable_cluster_mode,
  $cluster_name         = $scaleio::params::cluster_name,
  $components           = $scaleio::params::components,
  $config               = $scaleio::params::config,
  $callhome_cfg         = $scaleio::params::callhome_cfg,
  $ensure               = $scaleio::params::ensure,
  $interface            = $scaleio::params::interface,
  $license              = $scaleio::params::license,
  $mdm_management_ip    = $scaleio::params::mdm_management_ip,
  $path                 = $scaleio::params::path,
  $password             = $scaleio::params::password,
  $gw_password          = $scaleio::params::gwpassword,
  $primary_mdm          = $scaleio::params::primary_mdm,
  $secondary_mdm        = $scaleio::params::secondary_mdm,
  $tb_ip                = $scaleio::params::tb_ip,
  $use_ssd              = $scaleio::params::use_ssd,
  $version              = $scaleio::params::version,
  ) inherits scaleio::params {

    validate_bool($enable_cluster_mode)
    if $cluster_name { validate_string($cluster_name) }
    validate_array($components)
    if $callhome_cfg { validate_hash($callhome_cfg) }
    validate_string($ensure)
    validate_string($interface)
    validate_string($license)
    validate_absolute_path($path)
    if $scaleio::params::primary_mdm {
      validate_re($password, '^.{6,31}$')
    }
    #if $scaleio::params::components =~/gw/ {
    #  validate_re($gw_password, '^.{6,31}$')
    #}
    validate_string($eversion)
    if $use_ssd {
      validate_bool($use_ssd)
    }
  
    # Only validate the MDM IP for SDC installs
   # if $components =~/sdc/ {
   #   validate_re($mdm_management_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
   # }

    if $cluster_name {
      validate_string($cluster_name)
    }

  # Only validate the IP addresses if config is run
  #if $config {
  #  validate_re($password, '^.*(?=.{6,})(?=.*[a-z])(?=.*[A-Z])(?=.*[\d\W]).*$')
  #  validate_re($mdm_management_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  #  validate_re($primary_mdm, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  #  validate_re($secondary_mdm, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  #}

  if 'tb' in $components and 'mdm' in $components {
    fail('Invalid ScaleIO component selection - cannot Install TB and MDM components on the same system')
  }

    #if ($::lsbdistrelease < '5.5') {
    #  fail("ScaleIO version ${version} not supported on ${::osfamily} ${::lsbdistrelease}.")
    #}

 #   if $component =~/lia/ and $version =~/^1.2/ {
  #    fail("ScaleIO LIA is not supported on ScaleIO version ${version}")
  #  }


  include '::scaleio::login'
  include '::scaleio::iptables'
  include '::scaleio::drv_cfg'
  include '::scaleio::device'
  include '::scaleio::os_prep'
  include '::scaleio::install'
  include '::scaleio::shm'
  include '::scaleio::mdm'
  include '::scaleio::protection_domain'
  include '::scaleio::storage_pool'
  include '::scaleio::sds_first'
  include '::scaleio::sds_sleep'
  include '::scaleio::sds'
  include '::scaleio::volume'
  include '::scaleio::map_volume'
  include '::scaleio::gateway'
  include '::scaleio::callhome'

  Class['::scaleio::iptables'] -> Class['::scaleio::drv_cfg'] -> 
    Class['::scaleio::device'] ->  Class['::scaleio::os_prep'] -> Class['::scaleio::install'] ->
      Class['::scaleio::mdm'] -> Class['::scaleio::protection_domain'] -> Class['::scaleio::storage_pool'] ->
        Class['::scaleio::sds_first'] -> Class['::scaleio::sds'] -> Class['::scaleio::sds_sleep'] -> 
          Class['::scaleio::volume'] -> Class['::scaleio::map_volume'] -> Class['::scaleio::gateway'] -> Class['::scaleio::callhome']
            


}


