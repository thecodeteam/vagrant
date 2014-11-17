
class scaleio::iptables {
  file { "/etc/sysconfig/iptables" :
    ensure => file,
    owner  => root,
    group  => root,
  }
}