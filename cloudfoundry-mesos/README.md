# CloudFoundry-Mesos

This project help you easily create a [Cloud Foundry][1] environment
that runs Diego cells on top of [Mesos][2]. This is done using the
[cloufoundry-mesos][3] project, which modifies the Diego auctioneer
process to be a [Mesos Framework][4].

## Requirements

* [Virtualbox][5]
* [Vagrant][6]
* [Git][7]
* [Go][8]
* [Ruby][9]
* [Spiff][10]
* [Cloud Foundry CLI][11]

For OS X developers, these can all be installed via [Homebrew][12]. You will want to
run `brew tap xoebus/homebrew-cloudfoundry` to get access to spiff and 
`brew tap pivotal/tap` to get the `cloudfoundry-cli` package.

## System Requirements

These scripts will create 3 VMs. A bosh-lite VM that uses 6GB RAM, and 2 Mesos VMs
that are 2.5GB each. Total project will need a machine with at least 11GB RAM, and about
10GB of disk space.

## Quick Start

1. Install Requirements

1. Clone this repository

  ```bash
  git clone clone https://github.com/emccode/vagrant
  cd vagrant/cloudfoundry-mesos
  ```

1. Run script to deploy CloudFoundry Diego via bosh-lite

  ```bash
  ./cfdiego.sh
  ```

1. Run Script to deploy Mesos nodes and register CF as Framework

  ```bash
  ./cfonmesos.sh
  ```

1. Visit Mesos GUI at http://192.158.50.5:5050

1. Deploy a CF app using `cf push`

  ```bash
  git clone https://github.com/jianhuiz/cf-apps
  cd cf-apps/hello
  vi manifest.yml
  cf push
  ```

  *Note*: you will want modify manifest.yml to use less RAM (128M is good) and to set
  the domain as `bosh-lite.com`.

## Tips

When running the scripts, if any of the `git clone` steps hang, it is okay to Ctrl-C
the script and re-run.

To stop the Vagrant VMs, you can run `vagrant destroy` from either the `bosh-lite` directory
or the `../playa-mesos` directory.

If you want to add an additional Mesos Slave, you can modify `../playa-mesos/config.json`
with the details and use `vagrant up` to do so.

## Authors

* [Travis Rhoden](https://github.com/codenrhoden) ([@codenrhoden](https://twitter.com/codenrhoden))

[1]: https://www.cloudfoundry.org/
[2]: http://mesos.apache.org/
[3]: https://github.com/mesos/cloudfoundry-mesos
[4]: http://mesos.apache.org/documentation/latest/app-framework-development-guide/
[5]: https://www.virtualbox.org/wiki/Downloads
[6]: https://www.vagrantup.com/
[7]: https://git-scm.com/downloads
[8]: https://golang.org/
[9]: https://www.ruby-lang.org/
[10]: https://github.com/cloudfoundry-incubator/spiff
[11]: https://github.com/cloudfoundry/cli
[12]: http://brew.sh/
