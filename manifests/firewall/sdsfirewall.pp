
class scaleio::firewall::sdsfirewall {

  firewall { '001 Open Port 7072 for ScaleIO SDS':
    port   => [7072],
    proto  => tcp,
    action => accept,
  }

}
