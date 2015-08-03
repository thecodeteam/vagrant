# the installation part
class scaleio::install inherits scaleio {

    notify { "Installing Components: ${scaleio::components}": }
    ####################################
    # Installation of tie-breaker (tb) #
    ####################################
    if 'tb' in $scaleio::components {
      package { $scaleio::pkgs['tb']:
        ensure   => $scaleio::version,
      }
    } else {
      notify { 'component "tb" not specified':  }
    } ->

    ###########################################
    # Installation of meta-data-manager (mdm) #
    ###########################################
    if 'mdm' in $scaleio::components {
      package { ['mutt', 'python', 'python-paramiko' ]:
        ensure => present,
      } ->
      package { $scaleio::pkgs['mdm']:
        ensure   => $scaleio::version,
        require  => Class[ '::scaleio::shm' ],
      }
    } else {
      notify {  'component "mdm" not specified':  }
    } ->

    ##################################################
    # Installation of Software-Defined-Storage (sds) #
    ##################################################
    if 'sds' in $scaleio::components {
      package { $scaleio::pkgs['sds']:
        ensure   => $scaleio::version,
      }
    } else {
      notify {  'component "sds" not specified':  }
    } ->

    ##################################################
    # Installation of Software-Defined-Client (sdc) #
    ##################################################
    if 'sdc' in $scaleio::components {
      package { $scaleio::pkgs['sdc']:
        ensure   => $scaleio::version,
      }
    } else {
      notify {  'sdc component not specified':  }
    } ->

    #######################
    # Installation of lia #
    #######################
    if 'lia' in $scaleio::components {
      package { $scaleio::pkgs['lia']:
        ensure   => $scaleio::version,
      }
    } else {
      notify {  'lia component not specified':  }
    } ->

    ###########################################
    # Installation of Gateway/WebService (gw) #
    ###########################################
    if 'gw' in $scaleio::components {
      package { $scaleio::pkgs['gw']:
        ensure   => $scaleio::version,
        require  => Package[ 'java' ],
      }
    } else {
      notify {  'gw component not specified': }
    } ->

    ##################################################
    # Installation of Graphical User Interface (gui) #
    ##################################################
    if 'gui' in $scaleio::components {
      package { $scaleio::pkgs['gui']:
      ensure   => $scaleio::version,
      }
    } else {
      notify {  'gui component not specified': }
    } ->

    #############################
    # Installation of callhome  #
    #############################
    if 'callhome' in $scaleio::components {
      package { $scaleio::pkgs['callhome']:
        ensure   => $scaleio::version,
      }
    } else {
      notify {  'callhome component not specified': }
    }
}
