#!/bin/bash
echo "Installing Kubernetes Controller"
echo "Moving Kubernetes Controller Certificates"
mkdir -p /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/authorization-policy.jsonl /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/ca.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/ca-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/kubeconfig /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/kubernetes.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/kubernetes-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/token.csv /var/lib/kubernetes/
rm -rf /home/vagrant/k8s-certs

echo "Installing Docker 1.12.6"
curl -s -O https://get.docker.com/builds/Linux/x86_64/docker-1.12.6.tgz
tar -xvf docker-1.12.6.tgz
sudo cp docker/docker* /usr/bin/
cat << EOF > docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
ExecStart=/usr/bin/docker daemon \\
  --host=unix:///var/run/docker.sock \\
  --log-level=error \\
  --storage-driver=overlay
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
echo "Starting Docker Service"
mv docker.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable docker
systemctl start docker
systemctl status docker
sleep 5
echo "Installing ScaleIO Gateway"
docker run -d --name=scaleio-gw --restart=always -p 8443:443 -e GW_PASSWORD=Scaleio123 -e MDM1_IP_ADDRESS=192.168.50.11 -e MDM2_IP_ADDRESS=192.168.50.12 -e TRUST_MDM_CRT=true vchrisb/scaleio-gw:v2.0.1.2

echo "Downloading kube-apiserver"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kube-apiserver
echo "Downloading kube-controller-manager"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kube-controller-manager
echo "Downloading kube-scheduler"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kube-scheduler
echo "Downloading kubectl"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kubectl
echo "Downloading kube-proxy"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kube-proxy
echo "Setting Permissions and Moving Executables"
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl kube-proxy
mv kube-apiserver kube-controller-manager kube-scheduler kubectl kube-proxy /usr/bin/
echo "Creating Kubernetes API Service"
CONTROLLER_IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')

sed -i "s/k8s_controller_ip/$CONTROLLER_IP/" /var/lib/kubernetes/kubeconfig

cat << EOF > kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \\
  --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota \\
  --advertise-address=${CONTROLLER_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --authorization-mode=ABAC \\
  --authorization-policy-file=/var/lib/kubernetes/authorization-policy.jsonl \\
  --bind-address=0.0.0.0 \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --insecure-bind-address=0.0.0.0 \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --etcd-servers=https://${CONTROLLER_IP}:2379 \\
  --service-account-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --service-cluster-ip-range=10.32.0.0/20 \\
  --service-node-port-range=30000-32767 \\
  --storage-backend=etcd2 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --token-auth-file=/var/lib/kubernetes/token.csv \\
  --v=2 
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
mv kube-apiserver.service /etc/systemd/system/
echo "Starting Kubernetes API Service"
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver
echo "Creating Kubernetes Controller Manager Service"
cat << EOF > kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.50.0.0/16 \\
  --cluster-name=kubernetes \\
  --leader-elect=true \\
  --master=http://${CONTROLLER_IP}:8080 \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --service-cluster-ip-range=10.32.0.0/20 \\
  --v=5
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
mv kube-controller-manager.service /etc/systemd/system/
echo "Starting Kubernetes Controller Manager Service"
systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager
echo "Creating Kubernetes Scheduler Service"
cat << EOF > kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \\
  --leader-elect=true \\
  --master=http://${CONTROLLER_IP}:8080 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
mv kube-scheduler.service /etc/systemd/system/
echo "Starting Kubernetes Scheduler Service"
systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler
systemctl status kube-scheduler
echo "Creating Kube Proxy Service"
cat << EOF > kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --master=http://${CONTROLLER_IP}:8080 \\
  --kubeconfig=/var/lib/kubernetes/kubeconfig \\
  --cluster-cidr=10.50.0.0/16 \\
  --proxy-mode=iptables \\
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
echo "Starting Kube Proxy Service"
mv kube-proxy.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable kube-proxy
systemctl start kube-proxy
systemctl status kube-proxy

#adding static routes for kubernetes
sudo ip route add 10.50.0.0/24 via 192.168.50.12
sudo ip route add 10.50.1.0/24 via 192.168.50.13
cat << EOF > /etc/sysconfig/network-scripts/route-enp0s8
10.50.0.0/24 via 192.168.50.12 dev enp0s8
10.50.1.0/24 via 192.168.50.13 dev enp0s8
EOF
