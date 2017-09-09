#!/bin/bash
echo "Installing etcd"
mkdir -p /etc/etcd/
cp /home/vagrant/k8s-certs/ca.pem /etc/etcd/
cp /home/vagrant/k8s-certs/kubernetes-key.pem /etc/etcd/
cp /home/vagrant/k8s-certs/kubernetes.pem /etc/etcd/
FILESIZE=0
until [ $FILESIZE -gt 1000000 ]; do
  wget -q https://github.com/coreos/etcd/releases/download/v3.1.4/etcd-v3.1.4-linux-amd64.tar.gz
  FILESIZE=$(stat --printf="%s" etcd-v3.1.4-linux-amd64.tar.gz)
  if [ $FILESIZE -lt 1000000 ]; then
      echo "Filesize was not correct, deleting and trying again"
      echo $FILESIZE
      rm etcd-v3.1.4-linux-amd64.tar.gz
  fi
done
sudo tar -xvf etcd-v3.1.4-linux-amd64.tar.gz
mv etcd-v3.1.4-linux-amd64/etcd* /usr/bin/
mkdir -p /var/lib/etcd
echo "Creating Etcd Service"
ETCD_IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
cat << EOF > etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd \
  --name controller0 \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --initial-advertise-peer-urls https://${ETCD_IP}:2380 \\
  --listen-peer-urls https://${ETCD_IP}:2380 \\
  --listen-client-urls https://${ETCD_IP}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls https://${ETCD_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller0=https://${ETCD_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

EOF
mv etcd.service /etc/systemd/system/
echo "Starting Etcd Service"
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
systemctl status etcd
