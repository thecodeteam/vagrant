# ScaleIO

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What ScaleIO affects](#what-scaleio-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with scaleio](#beginning-with-scaleio)
4. [Usage](#usage)
5. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

A Puppet module that installs and configures the  ScaleIO block storage service components.  The module currently supports Redhat/CentOS v6.x.  

See <http://github.com/emccode/vagrant-puppet-scaleio> for a simple working example.

## Module Description

ScaleIO is software that takes local storage from operating systems and configures them in a virtual SAN to deliver block services to operating systems via IP.  The module handles the configuration of ScaleIO components and the creation and mapping of volumes to hosts.

Most aspects of configuration of ScaleIO have been brought into Puppet.  This means an operations team can easily adopt a software storage platform into their existing operations.

## Setup

### What Puppet-ScaleIO affects

* Installs firewall (iptables) settings based on ScaleIO components installed
* Tested with Puppet 3.7.2+
	* puppet.conf [main] - parser = “future”
* Tested with ScaleIO 1.30-426+

### Setup Requirements

* Requires separately downloadable ScaleIO RPMs

Required modules to install

	puppet module install puppetlabs-stdlib
	puppet module install puppetlabs-firewall
	puppet module install puppetlabs-java

	
Optional module to install

	puppet module install dalen-dnsquery

### Beginning with scaleio

	puppet module install emccode-scaleio

## Usage

The following section represents variables that are configured at the top of the site.pp file.  They can be considered optional and global as they are reused in the specific class declarations later on.

In order to make the site.pp more dynamic, we are using the hosts_lookup function to retrieve names for DNS names.  This allows a more dynamic capability for IP addresses.  The FQDN's represented below are not used in the Puppet paramaters, only as lookup references here in the site.pp file.  If lookups are to occur against a DNS server, the dns_lookup function can be used instead of hosts_lookup.  See the puppet <a href="https://github.com/emccode/vagrant-puppet-scaleio">vagrant-puppet-scaleio</a> repo for the most static example of the module.

	$version = '1.30-426.0'
	$mdm_fqdn = ['mdm1.scaleio.local','mdm2.scaleio.local']
	$mdm_ip = [hosts_lookup($mdm_fqdn[0])[0],hosts_lookup($mdm_fqdn[1])[0]]
	$tb_fqdn = 'tb.scaleio.local'
	$tb_ip = hosts_lookup($tb_fqdn)[0]
	$cluster_name = "cluster1"
	$enable_cluster_mode = true
	$password = 'Scaleio123'
	$gw_password= 'Scaleio123'

Here we have the sio_sds_device hash that holds the configuration parameters necessary to specify which device or file on the OS will be conumsed for storage by ScaleIO.

	$sio_sds_device = {
	          $tb_fqdn => {
	            'ip' => hosts_lookup($tb_fqdn)[0],
	            'protection_domain' => 'protection_domain1', 
	            'devices' => {
	              '/opt/sio_device1' => {  'size' => '100GB', 
	                                                'storage_pool' => 'capacity'
	                                              },
	            }
	          },
	          $mdm_fqdn[0] => {
	            'ip' => hosts_lookup($mdm_fqdn[0])[0],
	            'protection_domain' => 'protection_domain1',
	            'devices' => {
	              '/opt/sio_device1' => {  'size' => '100GB', 
	                                                'storage_pool' => 'capacity'
	                                              },
	            }
	          },
	          $mdm_fqdn[1] => {
	            'ip' => hosts_lookup($mdm_fqdn[1])[0],
	            'protection_domain' => 'protection_domain1',
	            'devices' => {
	              '/opt/sio_device1' => {  'size' => '100GB', 
	                                                'storage_pool' => 'capacity'
	                                              },
	            }
	          },
	        }

The sio_sdc_volume hash declares volumes that are to be created and the mapping of these volumes to specific clients.

	$sio_sdc_volume = {
	          'volume1' => { 'size_gb' => 8, 
	          'protection_domain' => 'protection_domain1', 
	          'storage_pool' => 'capacity',
	          'sdc_ip' => [
	              hosts_lookup($tb_fqdn)[0],
	              hosts_lookup($mdm_fqdn[0])[0],
	              hosts_lookup($mdm_fqdn[1])[0],
	            ] 
	          },
	        }

The callhome_cfg section is used to configure callhome services for support.

	$callhome_cfg = {
	        'email_to' => "emailto@address.com",
	        'email_from' => "emailfrom@address.com",
	        'username' => "monitor_username",
	        'password' => "monitor_password",
	        'customer' => "customer_name",
	        'smtp_host' => "smtp_host",
	        'smtp_port' => "smtp_port",
	        'smtp_user' => "smtp_user",
	        'smtp_password' => "smtp_password",
	        'severity' => "error",
	      }


Following this there are the node classifications.  Here we are provdining the default site.pp classifications that will configure a ScaleIO cluster from scratch using 3 nodes and multiple components per node.

Notice that there are extra fields being represented in the node classifications that may not naturally seem like they are required based on the node name.  In the below examples, we are setting up multi-role nodes by specifying multiple components which may require the extra parameters.

The following is a Tie-Breaker node.

	node /tb/ {
	  class {'scaleio::params':
	        password => $password,
	        version => $version,
	        mdm_ip => $mdm_ip,
	        tb_ip => $tb_ip,
	        callhome_cfg => $callhome_cfg,
	        sio_sds_device => $sio_sds_device,
	        sds_ssd_env_flag => true,
	        components => ['tb','sds','sdc'],
	  }
	  include scaleio
	}

The following is an MDM node.

	node /mdm/ {
	  class {'scaleio::params':
	        password => $password,
	        version => $version,
	        mdm_ip => $mdm_ip,
	        tb_ip => $tb_ip,
	        cluster_name => $cluster_name,
	        sio_sds_device => $sio_sds_device,
	        sio_sdc_volume => $sio_sdc_volume,
	        callhome_cfg => $callhome_cfg,
	        components => ['mdm','sds','sdc','callhome'],
	  }
	  include scaleio
	}

The following is an SDS node.

	node /sds/ {
	  class {'scaleio::params':
	        password => $password,
	        version => $version,
	        mdm_ip => $mdm_ip,
	        sio_sds_device => $sio_sds_device,
	        sds_ssd_env_flag => true,
	        components => ['sds'],
	  }
	  include scaleio
	}

The following is an SDC node.

	node /sdc/ {
	  class {'scaleio::params':
	        password => $password,
	        version => $version,
	        mdm_ip => $mdm_ip,
	        components => ['sdc'],
	  }
	  include scaleio
	}

The following is a Gateway node.

	node /gw/ {
	  class {'scaleio::params':
	        gw_password => $gw_password,
	        version => $version,
	        mdm_ip => $mdm_ip,
	        components => ['gw'],
	  }
	  include scaleio
	}


See <http://github.com/emccode/vagrant-puppet-scaleio> for a working example of a whole site.pp file.


## Reference

* puppetlabs-stdlib
* puppetlabs-firewall
* puppetlabs-java
* dalen-dnsquery

## Limitations

This module currently only support Redhat 6.x and was developed against CentOS 6.5.

## Development

We encourage the community to actively contribute to this module.

* Fork the repository
* Clone
* Add original repository as upstream
* Checkout new branch
* Commit changes
* Push to your repository
* Issue pull request

## Contributors

* Eoghan Kelleher
* Jonas Rosland
* Clint Kitson
