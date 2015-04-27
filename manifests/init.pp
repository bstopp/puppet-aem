# == Class: adobe_experience_manager
#
# Full description of class adobe_experience_manager here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'adobe_experience_manager':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Bryan Stopp.
#
class adobe_experience_manager (
  $aem_home           = $::adobe_experience_manager::params::aem_home,
  $jar                = undef,
  $user               = $::adobe_experience_manager::params::user,
  $group              = $::adobe_experience_manager::params::group,
  $manage_user        = true,
  $manage_group       = true,
  $runmodes           = $::adobe_experience_manager::params::runmodes,
  $cabfile            = $::adobe_experience_manager::params::cabfile,

) inherits ::adobe_experience_manager::params {
  
  validate_absolute_path($aem_home)
  validate_string($jar)
  validate_string($user)
  validate_string($group)
  validate_bool($manage_user)
  validate_bool($manage_group)
  validate_array($runmodes)
  validate_absolute_path($cabfile)
  

  if !$jar {
    fail ('Installer jar required but not defined')
  }
  
  anchor { 'adobe_experience_manager::begin':
    before => Class['adobe_experience_manager::user'],
  }
  
  class { 'adobe_experience_manager::user': }

  class { 'adobe_experience_manager::install': 
    require => Class['adobe_experience_manager::user'],
    notify  => Class['adobe_experience_manager::service'],
  }
  
  class { 'adobe_experience_manager::service': }
  
  anchor { 'adobe_experience_manager::end':
    require => Class['adobe_experience_manager::service'],
  }
}
