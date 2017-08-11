#!/bin/bash
echo "Installing Kubernetes Worker Components"
mkdir -p /var/lib/{kubelet,kube-proxy,kubernetes}
mkdir -p /var/run/kubernetes
echo "Moving Kubernetes Certificates"
cp /home/vagrant/k8certs/ca.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/kube-proxy.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/kube-proxy-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/admin.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/admin-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/bootstrap.kubeconfig /var/lib/kubelet
cp /home/vagrant/k8certs/kube-proxy.kubeconfig /var/lib/kube-proxy
rm -rf /home/vagrant/k8certs
ENP0S8IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
K8CONTROLLERIP=192.168.50.12
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
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubectl
echo "Downloading kubelet"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubelet
echo "Downloading kube-proxy"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kube-proxy
chmod +x kubectl kubelet kube-proxy
mv kubectl kubelet kube-proxy /usr/bin/
echo "Creating Kubelet Service"
API_SERVERS=$(sudo cat /var/lib/kubelet/bootstrap.kubeconfig | grep server | cut -d ':' -f2,3,4 | tr -d '[:space:]')
cat << EOF > kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \\
  --api-servers=${API_SERVERS} \\
  --allow-privileged=true \\
  --cluster-dns=10.32.0.10 \\
  --cluster-domain=cluster.local \\
  --container-runtime=docker \\
  --experimental-bootstrap-kubeconfig=/var/lib/kubelet/bootstrap.kubeconfig \\
  --network-plugin=kubenet \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --serialize-image-pulls=false \\
  --register-node=true \\
  --tls-cert-file=/var/run/kubernetes/kubelet-client.crt \\
  --tls-private-key-file=/var/run/kubernetes/kubelet-client.key \\
  --v=2
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
  --cluster-cidr=10.200.0.0/16 \\
  --masquerade-all=true \\
  --kubeconfig=/var/lib/kube-proxy/kube-proxy.kubeconfig \\
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
echo "Configuring Kubectl"
kubectl config set-cluster scaleio-k8s --certificate-authority=/var/lib/kubernetes/ca.pem --embed-certs=true --server=https://${K8CONTROLLERIP}:6443
kubectl config set-credentials admin --client-certificate=/var/lib/kubernetes/admin.pem --client-key=/var/lib/kubernetes/admin-key.pem
kubectl config set-context scaleio-k8s --cluster=scaleio-k8s --user=admin
kubectl config use-context scaleio-k8s
HOSTNAME=$(hostname)
if [ "$HOSTNAME" == "mdm2.scaleio.local" ]; then
  sleep 20s
  CSR=$(kubectl get csr | grep csr | awk -F" " '{print $1}')
  if [ -n "$CSR" ]; then
    kubectl certificate approve $CSR
  fi
  sleep 8
  echo "Starting Kubernetes Cluster DNS Service"
  kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts
  kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/services/kubedns.yaml
  kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/deployments/kubedns.yaml
fi
