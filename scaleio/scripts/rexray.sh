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
  endpoint: https://192.168.50.11:8443/api
  insecure: true
  useCerts: true
  userName: admin
  password: 'Scaleio123'
  systemName: cluster1
  protectionDomainName: pdomain
  storagePoolName: pool1
  thinOrThick: ThinProvisioned
EOF
sed -i '/KillMode/a RestartSec=10' /etc/systemd/system/rexray.service
sed -i '/KillMode/a Restart=always' /etc/systemd/system/rexray.service
systemctl daemon-reload
systemctl start rexray
systemctl enable rexray
