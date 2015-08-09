class scaleio::params {

  $cluster_name         = "cluster1"
  $components           = undef
  $callhome_cfg         = undef
  $default_password     = "admin"
  $enable_cluster_mode  = true
  $ensure               = undef
  $gw_password          = "Scaleio123"
  $interface            = undef
  $license              = undef
  $mdm_ip               = undef
  $password             = "Scaleio123"
  $tb_ip                = undef
  $rpm_suffix           = undef
  $shm_size             = 536866816
  $sds_network          = undef
  $sio_sds_device       = undef
  $sio_sdc_volume       = undef
  $sds_ssd_env_flag     = false
  $version              = '1.32'

  case $::osfamily {
    # Platform Specific variables
    'RedHat', 'SUSE' : {
      $path         = '/opt/scaleio'
      $use_ssd      = false
      
      $pkgs         = { callhome => "EMC-ScaleIO-callhome",
                        mdm      => "EMC-ScaleIO-mdm",
                        lia      => "EMC-ScaleIO-lia",
                        sds      => "EMC-ScaleIO-sds",
                        sdc      => "EMC-ScaleIO-sdc",
                        tb       => "EMC-ScaleIO-tb",
                        gw       => "EMC-ScaleIO-gateway",
                        gui      => "EMC-ScaleIO-gui"
                      }
      $drv_cfg_file  = "/bin/emc/scaleio/drv_cfg.txt"
    }
    default: {
      fail("ScaleIO installation is not supported on an ${::osfamily} based system.")
    }
  }
}
