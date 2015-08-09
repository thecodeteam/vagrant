
class scaleio::iptables inherits scaleio {
  file { "/etc/sysconfig/iptables" :
    ensure => file,
    owner  => root,
    group  => root,
  }
}
