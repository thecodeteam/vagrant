
class scaleio (

  $cluster_name         = $scaleio::params::cluster_name,
  $components           = $scaleio::params::components,
  $callhome_cfg         = $scaleio::params::callhome_cfg,
  $default_password     = $scaleio::params::default_password,
  $drv_cfg_file         = $scaleio::params::drv_cfg_file,
  $enable_cluster_mode  = $scaleio::params::enable_cluster_mode,
  $gw_password          = $scaleio::params::gwpassword,
  $interface            = $scaleio::params::interface,
  $license              = $scaleio::params::license,
  $mdm_ip               = $scaleio::params::mdm_ip,
  $path                 = $scaleio::params::path,
  $password             = $scaleio::params::password,
  $pkgs                 = $scaleio::params::pkgs,
  $tb_ip                = $scaleio::params::tb_ip,
  $shm_size             = $scaleio::params::shm_size,
  $sds_network          = $scaleio::params::sds_network,
  $sio_sds_device       = $scaleio::params::sio_sds_device,
  $sio_sdc_volume       = $scaleio::params::sio_sdc_volume,
  $sds_ssd_env_flag     = $scaleio::params::sds_ssd_env_flag,
  $use_ssd              = $scaleio::params::use_ssd,
  $version              = $scaleio::params::version
  ) inherits scaleio::params {

# Mandatory Parameters
  validate_array($components)
  validate_array($mdm_ip)
  validate_string($tb_ip)

# Need to define cluster name if cluster is enabled
  if $enable_cluster_mode {
    validate_bool($enable_cluster_mode)
    validate_string($cluster_name)
  }

  if 'tb' in $components and 'mdm' in $components {
    fail('Invalid ScaleIO component selection - cannot Install TB and MDM components on the same system')
  }

# The rest of parameters are optional
  if $callhome_cfg      { validate_hash($callhome_cfg)      }
  if $default_password  { validate_string($default_password)}
  if $drv_cfg_file      { validate_string($drv_cfg_file)    }
  if $gw_password       { validate_string($gw_password)     }
  if $interface         { validate_string($interface)       }
  if $license           { validate_string($license)         }
  if $path              { validate_absolute_path($path)     }
  if $password          { validate_string($password)        }
  if $pkgs              { validate_hash($pkgs)              }
  if $shm_size          { validate_string(shm_size)        }
  if $sds_network       { validate_string($sds_network)     }
  if $sio_sdc_volume    { validate_hash($sio_sdc_volume)    }
  if $sio_sds_device    { validate_hash($sio_sds_device)    }
  if $sds_ssd_env_flag  { validate_bool($sds_ssd_env_flag)  }
  if $use_ssd           { validate_bool($use_ssd)           }
  if $version           { validate_string($version)         }

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

  Class['::scaleio::iptables']          ->
  Class['::scaleio::device']            ->
  Class['::scaleio::drv_cfg']           ->
  Class['::scaleio::os_prep']           ->
  Class['::scaleio::install']           ->
  Class['::scaleio::mdm']               ->
  Class['::scaleio::protection_domain'] ->
  Class['::scaleio::storage_pool']      ->
  Class['::scaleio::sds_first']         ->
  Class['::scaleio::sds']               ->
  Class['::scaleio::sds_sleep']         ->
  Class['::scaleio::volume']            ->
  Class['::scaleio::map_volume']        ->
  Class['::scaleio::gateway']           ->
  Class['::scaleio::callhome']

}
