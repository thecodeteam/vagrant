#!/bin/bash
echo "Installing Kubernetes Controller"
echo "Moving Kubernetes Controller Certificates"
mkdir -p /var/lib/kubernetes/
cp /home/vagrant/k8certs/ca.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/ca-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/kubernetes.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/kubernetes-key.pem /var/lib/kubernetes/
cp /home/vagrant/k8certs/token.csv /var/lib/kubernetes/
rm -rf /home/vagrant/k8certs
echo "Downloading kube-apiserver"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kube-apiserver
echo "Downloading kube-controller-manager"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kube-controller-manager
echo "Downloading kube-scheduler"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kube-scheduler
echo "Downloading kubectl"
curl -s -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubectl
echo "Setting Permissions and Moving Executables"
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/
echo "Creating Kubernetes API Service"
ENP0S8IP=$(ip -o -4 addr show enp0s8 | awk -F '[ /]+' '/global/ {print $4}')
cat << EOF > kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \\
  --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --advertise-address=${ENP0S8IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/lib/audit.log \\
  --authorization-mode=RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://${ENP0S8IP}:2379 \\
  --event-ttl=1h \\
  --experimental-bootstrap-token-auth \\
  --insecure-bind-address=0.0.0.0 \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=rbac.authorization.k8s.io/v1alpha1 \\
  --service-account-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
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
  --address=0.0.0.0 \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --leader-elect=true \\
  --master=http://${ENP0S8IP}:8080 \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/16 \\
  --v=2
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
  --master=http://${ENP0S8IP}:8080 \\
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
echo "Creating the kubelet bootstrap cluster role"
sleep 20s
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
