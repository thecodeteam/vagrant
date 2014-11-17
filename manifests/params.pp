
class scaleio::params (
  $components             = undef,
  $cluster_name           = undef,
  $version                = undef,
  $mdm_ip                 = undef,
  $mdm_fqdn               = undef,
  $tb_ip                  = undef,
  $shm_size               = 536866816,
  $password               = "Scaleio123",
  $gw_password            = "Scaleio123",
  $default_password       = "admin",
  $enable_cluster_mode    = true,
  $sds_network            = undef,
  $sio_sds_device         = undef,
  $sio_sdc_volume         = undef,
  $callhome_cfg           = undef,
  $sds_ssd_env_flag       = false
){

  case $::osfamily {
    'RedHat', 'SUSE' : {
      $path = '/opt/scaleio'
    }
    default: {
      fail("ScaleIO installation is not supported on an ${::osfamily} based system.")
    }
  }

  $pathpackage     = "/tmp"
  $callhomepackage = ["EMC-ScaleIO-callhome","-${version}.el6.x86_64"]
  $mdmpackage      = ["EMC-ScaleIO-mdm","-${version}.el6.x86_64"]
  $liapackage      = ["EMC-ScaleIO-lia","-${version}.el6.x86_64"]
  $sdspackage      = ["EMC-ScaleIO-sds","-${version}.el6.x86_64"]
  $sdcpackage      = ["EMC-ScaleIO-sdc","-${version}.el6.x86_64"]
  $tbpackage       = ["EMC-ScaleIO-tb","-${version}.el6.x86_64"]
  $gwpackage       = ["EMC-ScaleIO-gateway","-${version}.noarch"]
  $uipackage       = ["EMC-ScaleIO-gui","-${version}.noarch"]

  $use_ssd           = false

}
