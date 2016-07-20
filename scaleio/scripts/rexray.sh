curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -s -- stable
cat << EOF > /etc/rexray/config.yml
libstorage:
  service: scaleio
  integration:
    volume:
      operations:
        mount:
          preempt: true
scaleio:
  endpoint: https://192.168.50.12/api
  insecure: true
  useCerts: true
  userName: admin
  password: 'Scaleio123'
  systemName: cluster1
  protectionDomainName: pdomain
  storagePoolName: pool1
  thinOrThick: ThinProvisioned
EOF
service rexray restart
