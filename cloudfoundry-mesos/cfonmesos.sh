#!/usr/bin/env bash

set -x
set -e

pushd ../playa-mesos
git reset --hard

cat > config.json <<EOF
{
  "platform": "virtualbox",
  "box_name": "codenrhoden/playa_mesos_0.25",
  "hosts": {
    "mesos-master": {
      "ip": "192.168.50.5"
    },
    "mesos-slave1": {
      "ip": "192.168.50.6"
    }
  },
  "vm_ram": "2560",
  "vm_cpus": "2"
}
EOF

sed -i '' 's/^box_url/#box_url/' Vagrantfile
sed -i '' 's/ node.vm.box_url/ #node.vm.box_url/' Vagrantfile

vagrant up --provider=virtualbox
popd

pushd diego-release
export GOPATH=$(pwd)
popd
pushd diego-release/src/github.com/cloudfoundry-incubator/auctioneer/cmd/auctioneer/
sed -i '' 's|"github.com/cloudfoundry-incubator/auction/auctionrunner"|"github.com/codenrhoden/cloudfoundry-mesos/scheduler/auctionrunner"|g' main.go
go get ./...
env GOOS=linux go build

bosh scp brain_z1/0 --upload auctioneer /tmp/auctioneer
popd

cat > auctioneer_ctl <<"EOF"
#!/bin/bash -e

RUN_DIR=/var/vcap/sys/run/auctioneer
LOG_DIR=/var/vcap/sys/log/auctioneer
CONF_DIR=/var/vcap/jobs/auctioneer/config
PIDFILE=$RUN_DIR/auctioneer.pid

source /var/vcap/packages/pid_utils/pid_utils.sh

bbs_sec_flags=" \
 -bbsClientCert=${CONF_DIR}/certs/bbs/client.crt \
 -bbsClientKey=${CONF_DIR}/certs/bbs/client.key \
 -bbsCACert=${CONF_DIR}/certs/bbs/ca.crt"

bbs_api_url="https://bbs.service.cf.internal:8889"

case $1 in

  start)
    pid_guard $PIDFILE "auctioneer"

    mkdir -p $RUN_DIR
    chown -R vcap:vcap $RUN_DIR

    mkdir -p $LOG_DIR
    chown -R vcap:vcap $LOG_DIR

    echo $$ > $PIDFILE

    # Allowed number of open file descriptors
    ulimit -n 100000

    exec chpst -u vcap:vcap /var/vcap/packages/auctioneer/bin/auctioneer ${bbs_sec_flags} \
      -bbsAddress=${bbs_api_url} \
       \
      -address=10.244.16.134 \
      -master=zk://192.168.50.5:2181/mesos \
      -auction_strategy=binpack \
      -consul_server=10.244.0.54 \
      -etcd_url=http://10.244.0.42:4001 \
      -consulCluster=http://127.0.0.1:8500 \
      -executor_image=codenrhoden/diego-cell \
      -debugAddr=0.0.0.0:17001 \
      -listenAddr=0.0.0.0:9016 \
      -logLevel=info \
      2> >(tee -a $LOG_DIR/auctioneer.stderr.log | logger -p user.error -t vcap.auctioneer) \
      1> >(tee -a $LOG_DIR/auctioneer.stdout.log | logger -p user.info -t vcap.auctioneer)

    ;;

  stop)
    kill_and_wait $PIDFILE

    ;;

  *)
    echo "Usage: auctioneer_ctl {start|stop}"

    ;;

esac
EOF

cat > replace_auctioneer.sh <<EOF
#!/bin/bash
set -x
# Since bosh uses a different user on every SSH attempt,
# we set ogo+w on our files so they can be overwritten later
sudo chmod ugo+w /tmp/auctioneer /tmp/auctioneer_ctl /tmp/replace_auctioneer.sh
sudo /var/vcap/bosh/bin/monit stop auctioneer
# wait for auctioneer to stop
while [ -e /var/vcap/sys/run/auctioneer/auctioneer.pid ]; do
	sleep 1
done
if [ ! -f /var/vcap/jobs/auctioneer/bin/auctioneer_ctl_old ]
then
	sudo mv /var/vcap/jobs/auctioneer/bin/auctioneer_ctl /var/vcap/jobs/auctioneer/bin/auctioneer_ctl_old
fi
sudo cp /tmp/auctioneer_ctl /var/vcap/jobs/auctioneer/bin/
sudo chown root:root /var/vcap/jobs/auctioneer/bin/auctioneer_ctl
sudo chmod 0755 /var/vcap/jobs/auctioneer/bin/auctioneer_ctl
if [ ! -f /var/vcap/packages/auctioneer/bin/auctioneer_old ]
then
	sudo mv /var/vcap/packages/auctioneer/bin/auctioneer /var/vcap/packages/auctioneer/bin/auctioneer_old
fi
sudo cp /tmp/auctioneer /var/vcap/packages/auctioneer/bin/
sudo chown root:root /var/vcap/packages/auctioneer/bin/auctioneer
sudo chmod 0755 /var/vcap/packages/auctioneer/bin/auctioneer
sudo /var/vcap/bosh/bin/monit start auctioneer
EOF

bosh scp brain_z1/0 --upload auctioneer_ctl /tmp/auctioneer_ctl
bosh scp brain_z1/0 --upload replace_auctioneer.sh /tmp/replace_auctioneer.sh
bosh ssh brain_z1/0 bash /tmp/replace_auctioneer.sh
