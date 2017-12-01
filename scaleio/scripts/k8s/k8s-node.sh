#!/bin/bash
echo "Installing Kubernetes Node Components"
mkdir -p /var/lib/{kubelet,kubernetes}
echo "Moving Kubernetes Certificates"
cp /home/vagrant/k8s-certs/ca.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/kubernetes.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/kubernetes-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8s-certs/kubeconfig /var/lib/kubelet/
rm -rf /home/vagrant/k8s-certs

NODE_IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
CONTROLLER_IP=192.168.50.11
sed -i "s/k8s_controller_ip/$CONTROLLER_IP/" /var/lib/kubelet/kubeconfig

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
  --iptables=false \\
  --ip-masq=false \\
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
echo "Installing CNI"
mkdir -p /opt/cni
curl -s -O https://storage.googleapis.com/kubernetes-release/network-plugins/cni-amd64-0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff.tar.gz
sudo tar -xvf cni-amd64-0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff.tar.gz -C /opt/cni
echo "Downloading kubectl"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kubectl
echo "Downloading kubelet"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kubelet
echo "Downloading kube-proxy"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kube-proxy
chmod +x kubectl kubelet kube-proxy
mv kubectl kubelet kube-proxy /usr/bin/
echo "Creating Kubelet Service"
cat << EOF > kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Wants=docker.service

[Service]
ExecStart=/usr/bin/kubelet \\
  --allow-privileged=true \\
  --cluster-dns=10.32.0.10 \\
  --cluster-domain=cluster.local \\
  --container-runtime=docker \\
  --docker=unix:///var/run/docker.sock \\
  --network-plugin=kubenet \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --require-kubeconfig \\
  --serialize-image-pulls=false \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2 \\
  --enable-controller-attach-detach=false \\
  --fail-swap-on=false

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
echo "Starting Kubelet Service"
mv kubelet.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet
echo "Creating Kube Proxy Service"
cat << EOF > kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --master=http://${CONTROLLER_IP}:8080 \\
  --kubeconfig=/var/lib/kubelet/kubeconfig  \\
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

kubectl config set-cluster kubernetes --server=http://${CONTROLLER_IP}:8080
kubectl config set-context default --cluster=kubernetes --namespace=default --user=admin
kubectl config use-context default
cp -R ~/.kube /home/vagrant/
chown vagrant:vagrant -R /home/vagrant/.kube

HOSTNAME=$(hostname)

if [ "$HOSTNAME" == "node01" ]; then
  echo "Adding static routes for kubernetes"
  ip route add 10.50.1.0/24 via 192.168.50.13
  cat << EOF > /etc/sysconfig/network-scripts/route-enp0s8
10.50.1.0/24 via 192.168.50.13 dev enp0s8
EOF
fi

if [ "$HOSTNAME" == "node02" ]; then
  echo "Adding static routes for kubernetes"
  ip route add 10.50.0.0/24 via 192.168.50.12
  cat << EOF > /etc/sysconfig/network-scripts/route-enp0s8
10.50.0.0/24 via 192.168.50.12 dev enp0s8
EOF
  sleep 15
  echo "Starting Kubernetes Cluster DNS Service"
  kubectl create -f https://storage.googleapis.com/kubernetes-the-hard-way/kube-dns.yaml
fi
