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
  $sds_ssd_env_flag       = false,
  $rpm_suffix             = ".el6.x86_64",
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
  $callhomepackage = ["EMC-ScaleIO-callhome","-${version}${rpm_suffix}"]
  $mdmpackage      = ["EMC-ScaleIO-mdm","-${version}${rpm_suffix}"]
  $liapackage      = ["EMC-ScaleIO-lia","-${version}${rpm_suffix}"]
  $sdspackage      = ["EMC-ScaleIO-sds","-${version}${rpm_suffix}"]
  $sdcpackage      = ["EMC-ScaleIO-sdc","-${version}${rpm_suffix}"]
  $tbpackage       = ["EMC-ScaleIO-tb","-${version}${rpm_suffix}"]
  $gwpackage       = ["EMC-ScaleIO-gateway","-${version}.noarch"]
  $uipackage       = ["EMC-ScaleIO-gui","-${version}.noarch"]

  $use_ssd           = false

}

