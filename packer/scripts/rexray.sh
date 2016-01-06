sudo curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -
sudo tee -a /etc/rexray/config.yml << EOF
rexray:
  logLevel: warn
  storageDrivers:
  - virtualbox
  volume:
    mount:
      preempt: false
virtualbox:
  endpoint: http://10.0.2.2:18083
  tls: false
  volumePath: /tmp
  controllerName: SATA
EOF
