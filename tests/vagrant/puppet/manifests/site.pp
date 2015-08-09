
Package {
  allow_virtual => true,
}

$version = 'latest'

$mdm_ip = ['192.168.50.12','192.168.50.13']
$tb_ip = '192.168.50.11'
$cluster_name = "cluster1"
$enable_cluster_mode = true
$password = 'Scaleio123'
$gw_password= 'Scaleio123'


$sio_sds_device = {
          'tb.scaleio.local' => {
            'ip' => '192.168.50.11',
            'protection_domain' => 'protection_domain1',
            'devices' => {
              '/var/sio_device1' => {  'size' => '100GB',
                                                'storage_pool' => 'capacity'
                                              },
            }
          },
          'mdm1.scaleio.local' => {
            'ip' => '192.168.50.12',
            'protection_domain' => 'protection_domain1',
            'devices' => {
              '/var/sio_device1' => {  'size' => '100GB',
                                                'storage_pool' => 'capacity'
                                              },
            }
          },
          'mdm2.scaleio.local' => {
            'ip' => '192.168.50.13',
            'protection_domain' => 'protection_domain1',
            'devices' => {
              '/var/sio_device1' => {  'size' => '100GB',
                                                'storage_pool' => 'capacity'
                                              },
            }
          },
        }

$sio_sdc_volume = {
          'volume1' => { 'size_gb' => 8,
          'protection_domain' => 'protection_domain1',
          'storage_pool' => 'capacity',
          'sdc_ip' => [
              '192.168.50.11',
              '192.168.50.12',
              '192.168.50.13',
            ]
          },
        }

$callhome_cfg = {
        'email_to' => "emailto@address.com",
        'email_from' => "emailfrom@address.com",
        'username' => "monitor_username",
        'password' => "monitor_password",
        'customer' => "customer_name",
        'smtp_host' => "smtp_host",
        'smtp_port' => "smtp_port",
        'smtp_user' => "smtp_user",
        'smtp_password' => "smtp_password",
        'severity' => "error",
      }

node /tb/ {
  class {'::scaleio':
        password => $password,
        version => $version,
        mdm_ip => $mdm_ip,
        tb_ip => $tb_ip,
        callhome_cfg => $callhome_cfg,
        sio_sds_device => $sio_sds_device,
        sds_ssd_env_flag => true,
        components => ['tb','sds','sdc', 'lia'],
  }
}

node /mdm/ {
  class {'::scaleio':
        password => $password,
        version => $version,
        mdm_ip => $mdm_ip,
        tb_ip => $tb_ip,
        cluster_name => $cluster_name,
        sio_sds_device => $sio_sds_device,
        sio_sdc_volume => $sio_sdc_volume,
        callhome_cfg => $callhome_cfg,
        components => ['mdm','sds','sdc','callhome', 'lia'],
  }
}

node /sds/ {
  class {'::scaleio':
        password => $password,
        version => $version,
        mdm_ip => $mdm_ip,
        sio_sds_device => $sio_sds_device,
        sds_ssd_env_flag => true,
        components => ['sds', 'lia'],
  }
}

node /sdc/ {
  class {'::scaleio':
        password => $password,
        version => $version,
        mdm_ip => $mdm_ip,
        components => ['sdc'],
  }
}

node /gw/ {
  class {'::scaleio':
        gw_password => $gw_password,
        version => $version,
        mdm_ip => $mdm_ip,
        components => ['gw'],
  }
}
