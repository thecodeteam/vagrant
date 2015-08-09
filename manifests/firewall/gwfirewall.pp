
class scaleio::firewall::gwfirewall {

  firewall { '001 for ScaleIO Gateway':
    port   => [443],
    proto  => tcp,
    #action => accept,
    action => drop,
  }

}
