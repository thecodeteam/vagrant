
class scaleio::firewall::pre {

  firewall { '000 accept all icmp':
      require => undef,
      proto => 'icmp',
      action => 'accept', } ->
  firewall { '001 accept all to lo interface':
      require => undef,
      proto => 'all',
      iniface => 'lo',
      action => 'accept', } ->
  firewall { '002 accept related established rules':
      require => undef,
      proto => 'all',
      state => ['RELATED', 'ESTABLISHED'],
      action => 'accept', } ->
  firewall { "003 accept all ssh requests":
    require => undef,
    proto  => "tcp",
    port   => [22],
    action => "accept", }
}