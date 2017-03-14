yum install -y epel-release
yum install -y python-pip
pip install ceph-deploy
ceph-deploy install --all --release kraken localhost
chown vagrant:vagrant ~vagrant/ceph-deploy-ceph.log
