#!/usr/bin/env bash

set -x
set -e

BOSH_STEMCELL_FILE=bosh-lite-stemcell-latest.tgz
GARDEN_LINUX_FILE=garden-linux-release-v0.307.0.tgz
ETCD_FILE=etcd-release-latest.tgz

gem install bosh_cli bundler --no-ri --no-rdoc
if [ ! -d bosh-lite ]
then
	git clone https://github.com/cloudfoundry/bosh-lite
fi
if [ ! -d cf-release ]
then
	git clone https://github.com/cloudfoundry/cf-release
fi
if [ ! -d diego-release ]
then
	git clone https://github.com/cloudfoundry-incubator/diego-release
fi

pushd bosh-lite
vagrant up --provider=virtualbox

bosh target 192.168.50.4 lite
bosh login admin admin
sudo bin/add-route

popd

if [ ! -e $BOSH_STEMCELL_FILE ]
then
	curl -L -o $BOSH_STEMCELL_FILE https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
fi
if [ ! -e $GARDEN_LINUX_FILE ]
then
	curl -L -o $GARDEN_LINUX_FILE https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release?v=0.307.0
fi
if [ ! -e $ETCD_FILE ]
then
	curl -L -o $ETCD_FILE https://bosh.io/d/github.com/cloudfoundry-incubator/etcd-release
fi

bosh upload stemcell bosh-lite-stemcell-latest.tgz --skip-if-exists

pushd cf-release
git checkout v219
scripts/update
cat > bosh-lite/stubs/cfmesos.yml <<EOF
---
properties:
  consul:
    require_ssl: false
  cc:
    default_to_diego_backend: true
EOF
scripts/generate-bosh-lite-dev-manifest bosh-lite/stubs/cfmesos.yml

bosh deployment bosh-lite/deployments/cf.yml
bosh create release --name cf --force
bosh -n upload release
bosh -n deploy

popd

bosh upload release garden-linux-release-v0.307.0.tgz --skip-if-exists
bosh upload release etcd-release-latest.tgz --skip-if-exists

pushd diego-release
git checkout v0.1434.0
scripts/update
scripts/generate-bosh-lite-manifests ./cfmesos.yml
sed -i '' '1796s/true/false/' bosh-lite-manifests/diego.yml
pushd src/github.com/cloudfoundry-incubator/auctioneer/cmd/auctioneer/
sed -i '' 's|"github.com/codenrhoden/cloudfoundry-mesos/scheduler/auctionrunner"|"github.com/cloudfoundry-incubator/auction/auctionrunner"|g' main.go
popd
bosh deployment bosh-lite-manifests/diego.yml
bosh create release --name diego --force
bosh -n upload release
bosh -n deploy

cf login -a api.bosh-lite.com -u admin -p admin --skip-ssl-validation
cf enable-feature-flag diego_docker

cf create-org diego
cf target -o diego
cf create-space diego
cf target -s diego
