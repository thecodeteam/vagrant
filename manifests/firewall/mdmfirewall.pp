
class scaleio::firewall::mdmfirewall {

  firewall { '001 Open Ports 6611 and 9011 for ScaleIO MDM':
    port   => [6611, 9011, 443],
    proto  => tcp,
    action => accept,
  }

}
