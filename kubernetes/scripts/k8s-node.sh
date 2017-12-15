#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -k8sv|--K8S_VERSION)
    K8S_VERSION="$2"
    shift
    ;;
    -msip|--master_ip)
    MASTER_IP="$2"
    shift
    ;;
    -n1ip|--node01_ip)
    NODE01_IP="$2"
    shift
    ;;
    -n2ip|--node02_ip)
    NODE02_IP="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done

echo "Installing Kubernetes Node Components"
mkdir -p /var/lib/{kube-proxy,kubelet,kubernetes}
echo "Moving Kubernetes Certificates"
cp /home/vagrant/certs/ca.pem /var/lib/kubernetes/
cp /home/vagrant/certs/`hostname`.pem /var/lib/kubelet/
cp /home/vagrant/certs/`hostname`-key.pem /var/lib/kubelet/
cp /home/vagrant/certs/`hostname`.kubeconfig /var/lib/kubelet/kubeconfig
cp /home/vagrant/certs/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
rm -rf /home/vagrant/certs

NODE_IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
MASTER_IP=192.168.50.11

# echo "Installing Docker 1.12.6"
# mv /vagrant/cache/docker/* /usr/bin
#
# cat << EOF > docker.service
# [Unit]
# Description=Docker Application Container Engine
# Documentation=http://docs.docker.io
#
# [Service]
# ExecStart=/usr/bin/docker daemon \\
#   --iptables=false \\
#   --ip-masq=false \\
#   --host=unix:///var/run/docker.sock \\
#   --log-level=error \\
#   --storage-driver=overlay
# Restart=on-failure
# RestartSec=5
#
# [Install]
# WantedBy=multi-user.target
# EOF
# echo "Starting Docker Service"
# mv docker.service /etc/systemd/system/
# systemctl daemon-reload
# systemctl enable docker
# systemctl start docker
# sleep 5
# systemctl status docker


echo "Installing CNI plugins"
mkdir -p /opt/cni/bin
sudo tar -xvf /vagrant/cache/cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin


echo "Installing kubelet"
cp /vagrant/cache/k8s-${K8S_VERSION}/kubelet /usr/bin

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
  --anonymous-auth=false \\
  --authorization-mode=Webhook \\
  --cgroup-driver=systemd \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --cloud-provider= \\
  --cluster-dns=10.32.0.10 \\
  --cluster-domain=cluster.local \\
  --container-runtime=docker \\
  --docker=unix:///var/run/docker.sock \\
  --fail-swap-on=false \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=kubenet \\
  --register-node=true \\
  --require-kubeconfig \\
  --runtime-request-timeout=15m \\
  --serialize-image-pulls=false \\
  --tls-cert-file=/var/lib/kubelet/`hostname`.pem \\
  --tls-private-key-file=/var/lib/kubelet/`hostname`-key.pem \\
  --v=5 \\
  --feature-gates=CSIPersistentVolume=true,MountPropagation=true \\
  --enable-controller-attach-detach=true


Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Starting kubelet service"
mv kubelet.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet


echo "Installing kube-proxy"
cp /vagrant/cache/k8s-${K8S_VERSION}/kube-proxy /usr/bin

echo "Creating kube-proxy service"
cat << EOF > kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --master=http://${MASTER_IP}:8080 \\
  --kubeconfig=/var/lib/kube-proxy/kubeconfig  \\
  --cluster-cidr=10.50.0.0/16 \\
  --proxy-mode=iptables \\
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Starting kube-proxy service"
mv kube-proxy.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable kube-proxy
systemctl start kube-proxy
systemctl status kube-proxy


echo "Installing kubectl"
cp /vagrant/cache/k8s-${K8S_VERSION}/kubectl /usr/bin
kubectl config set-cluster kubernetes --server=http://${MASTER_IP}:8080
kubectl config set-context default --cluster=kubernetes --namespace=default --user=admin
kubectl config use-context default
cp -R ~/.kube /home/vagrant/
chown vagrant:vagrant -R /home/vagrant/.kube


if [ $(hostname) == "node01" ]; then
  echo "Adding static routes for kubernetes"
  ip route add 10.50.1.0/24 via ${NODE02_IP}
  cat << EOF > /etc/sysconfig/network-scripts/route-enp0s8
10.50.1.0/24 via ${NODE02_IP} dev enp0s8
EOF
fi

if [ $(hostname) == "node02" ]; then
  echo "Adding static routes for kubernetes"
  ip route add 10.50.0.0/24 via ${NODE01_IP}
  cat << EOF > /etc/sysconfig/network-scripts/route-enp0s8
10.50.0.0/24 via ${NODE01_IP} dev enp0s8
EOF
  echo "Waiting 1 minute for services to settle"
  sleep 60
  echo "Starting kubernetes cluster DNS service"
  kubectl create -f https://storage.googleapis.com/kubernetes-the-hard-way/kube-dns.yaml
fi
