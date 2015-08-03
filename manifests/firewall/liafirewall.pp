
class scaleio::firewall::liafirewall {

  firewall { '001 Open Port 9099 for ScaleIO LIA':
    port   => [9099],
    proto  => tcp,
    action => accept,
  }

}
