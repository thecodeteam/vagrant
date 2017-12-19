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
    -si|--scaleio_install)
    SCALEIO_INSTALL="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done

echo "Installing Kubernetes controller components"

echo K8S_INSTALL = "${K8S_INSTALL}"
echo MASTER_IP = "${MASTER_IP}"
echo NODE01_IP = "${NODE01_IP}"
echo NODE02_IP = "${NODE02_IP}"
echo SCALEIO_INSTALL = "${SCALEIO_INSTALL}"

echo "Deploying Kubernetes controller certificates"
mkdir -p /var/lib/kubernetes/
cp /home/vagrant/certs/ca.pem /var/lib/kubernetes/
cp /home/vagrant/certs/ca-key.pem /var/lib/kubernetes/
cp /home/vagrant/certs/kubernetes.pem /var/lib/kubernetes/
cp /home/vagrant/certs/kubernetes-key.pem /var/lib/kubernetes/

echo "Deploying etcd certificates"
mkdir -p /etc/etcd/
cp /home/vagrant/certs/ca.pem /etc/etcd/
cp /home/vagrant/certs/kubernetes-key.pem /etc/etcd/
cp /home/vagrant/certs/kubernetes.pem /etc/etcd/

echo "Cleaning up certificates"
rm -rf /home/vagrant/certs


# echo "Installing Docker 1.12.6"
# cp /vagrant/cache/docker/* /usr/bin
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
#   --storage-driver=devicemapper
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


echo "Installing etcd"
sudo tar -xvf /vagrant/cache/etcd-v3.2.8-linux-amd64.tar.gz
mv etcd-v3.2.8-linux-amd64/etcd* /usr/bin/
rm -rf etcd-v3.2.8-linux-amd64
mkdir -p /var/lib/etcd
echo "Creating etcd service"
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
  --initial-advertise-peer-urls https://${MASTER_IP}:2380 \\
  --listen-peer-urls https://${MASTER_IP}:2380 \\
  --listen-client-urls https://${MASTER_IP}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls https://${MASTER_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller0=https://${MASTER_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

EOF
mv etcd.service /etc/systemd/system/
echo "Starting etcd service"
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
systemctl status etcd

sleep 5

if [ "${SCALEIO_INSTALL}" == "true" ]; then
  echo "Installing ScaleIO gateway"

  if [ ! -f /vagrant/cache/scaleio-gw:v2.0.1.2.tar ]; then
    echo "Downloading ScaleIO Gateway from Docker Hub"
    docker pull vchrisb/scaleio-gw:v2.0.1.2
    echo "Saving ScaleIO Gateway Image to Cache"
    docker save vchrisb/scaleio-gw:v2.0.1.2 -o /vagrant/cache/scaleio-gw:v2.0.1.2.tar
  else
    echo "Importing ScaleIO Gateway into Docker"
    docker load -i /vagrant/cache/scaleio-gw:v2.0.1.2.tar
  fi
  docker run -d --name=scaleio-gw --restart=always -p 8443:443 -e MDM1_IP_ADDRESS=${MASTER_IP} -e MDM2_IP_ADDRESS=${NODE01_IP} -e TRUST_MDM_CRT=true vchrisb/scaleio-gw:v2.0.1.2
fi

echo "Installing kube-apiserver"
cp /vagrant/cache/k8s-${K8S_VERSION}/kube-apiserver /usr/bin/

echo "Creating kube-apiserver service"

cat << EOF > kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \\
  --admission-control=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --advertise-address=${MASTER_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://${MASTER_IP}:2379 \\
  --insecure-bind-address=0.0.0.0 \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/20 \\
  --service-node-port-range=30000-32767 \\
  --tls-ca-file=/var/lib/kubernetes/ca.pem \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2 \\
  --feature-gates=CSIPersistentVolume=true,MountPropagation=true

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
mv kube-apiserver.service /etc/systemd/system/
echo "Starting kube-apiserver service"
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver


echo "Installing kube-controller-manager"
cp /vagrant/cache/k8s-${K8S_VERSION}/kube-controller-manager /usr/bin/

echo "Creating kube-controller-manager service"
cat << EOF > kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.50.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --leader-elect=true \\
  --master=http://127.0.0.1:8080 \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/20 \\
  --v=2 \\
  --feature-gates=CSIPersistentVolume=true,MountPropagation=true

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


echo "Downloading kube-scheduler"
cp /vagrant/cache/k8s-${K8S_VERSION}/kube-scheduler /usr/bin/

echo "Creating kube-scheduler service"
cat << EOF > kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \\
  --leader-elect=true \\
  --master=http://127.0.0.1:8080 \\
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


echo "Installing kube-proxy"
cp /vagrant/cache/k8s-${K8S_VERSION}/kube-proxy /usr/bin/

echo "Creating Kube Proxy Service"
cat << EOF > kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --master=http://127.0.0.1:8080 \\
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
cp /vagrant/cache/k8s-${K8S_VERSION}/kubectl /usr/bin/

echo "Configuring Kubernetes RBAC for kubelet connectivity"
sleep 10
cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

echo "Installing helm"
tar zxf /vagrant/cache/helm-v2.7.2-linux-amd64.tar.gz linux-amd64/helm --strip-components=1
mv helm /usr/bin

echo "Adding static routes for kubenet"
sudo ip route add 10.50.0.0/24 via ${NODE01_IP}
sudo ip route add 10.50.1.0/24 via ${NODE02_IP}
cat << EOF > /etc/sysconfig/network-scripts/route-enp0s8
10.50.0.0/24 via ${NODE01_IP} dev enp0s8
10.50.1.0/24 via ${NODE02_IP} dev enp0s8
EOF

#fix for Windows environments
echo "Making sure scripts are executable"
chmod +x /home/vagrant/tmux.sh
chmod +x /home/vagrant/pvc-create.sh
