# the installation part
class scaleio::install inherits scaleio{
  
  each($scaleio::params::components) |$component| {
    $package_array = getvar("${component}package")
    $package_name = $package_array[0]
    $package_version = $package_array[1]
    $package_var = "${package_name}${package_version}"
 
    file { "${scaleio::params::pathpackage}/${package_var}.rpm":
        mode   => 755,
        owner  => root,
        group  => root,
        source => "puppet:///modules/scaleio/${package_var}.rpm",
    } 
  }

  if 'tb' in $scaleio::params::components {
    package { $tbpackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($tbpackage,"")}.rpm",
      require  => File["${scaleio::params::pathpackage}/${join($tbpackage,"")}.rpm"],
    } 
  } else { notify {'tb component not specified':}}  ->
 
  if 'mdm' in $scaleio::params::components {
    
    package { ['mutt', 'python', 'python-paramiko']:
      ensure => present,
    } -> 

    package { $mdmpackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($mdmpackage,"")}.rpm",
      require  => [Class['::scaleio::shm'],Package['numactl'],File["${scaleio::params::pathpackage}/${join($mdmpackage,"")}.rpm"]],
    } 
  } else { notify {'mdm component not specified':}}  ->
 
  if 'sds' in $scaleio::params::components {
    package { $sdspackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($sdspackage,"")}.rpm",
      require  => File["${scaleio::params::pathpackage}/${join($sdspackage,"")}.rpm"],
    } 
  } else { notify {'sds component not specified':}}  ->

  if 'sdc' in $scaleio::params::components {
    package { $sdcpackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($sdcpackage,"")}.rpm",
      require  => File["${scaleio::params::pathpackage}/${join($sdcpackage,"")}.rpm"],
    } 
  } else { notify {'sdc component not specified':}} ->

  if 'lia' in $scaleio::params::components {
    package { $liapackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($liapackage,"")}.rpm",
      require  => File["${scaleio::params::pathpackage}/${join($liapackage,"")}.rpm"],
    } 
  } else { notify {'lia component not specified':}} ->

  if 'gw' in $scaleio::params::components {
    #package { $gwpackage[0]:
    #  ensure   => latest,
    #  provider => 'rpm',
    #  source   => "${scaleio::params::pathpackage}/${join($gwpackage,"")}.rpm",
    #  require  => File["${scaleio::params::pathpackage}/${join($gwpackage,"")}.rpm"],
    #}

   exec { 
     $gwpackage[0]: 
     command => "/usr/bin/rpm -i ${scaleio::params::pathpackage}/${join($gwpackage,"")}.rpm", 
     unless =>"/usr/bin/rpm -qi EMC-ScaleIO-gateway >/dev/null 2>&1",
     require  => File["${scaleio::params::pathpackage}/${join($gwpackage,"")}.rpm"],
     path => "/etc/alternatives/java",   
  }
 
  } else { notify {'gw component not specified':}} ->

  if 'ui' in $scaleio::params::components {
    package { $uipackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($uipackage,"")}.rpm",
      require  => File["${scaleio::params::pathpackage}/${join($uipackage,"")}.rpm"],
    } 
  } else { notify {'ui component not specified':}} ->

  if 'callhome' in $scaleio::params::components {
    package { $callhomepackage[0]:
      ensure   => latest,
      provider => 'rpm',
      source   => "${scaleio::params::pathpackage}/${join($callhomepackage,"")}.rpm",
      require  => File["${scaleio::params::pathpackage}/${join($callhomepackage,"")}.rpm"],
    } 
  } else { notify {'callhome component not specified':}} 

}

