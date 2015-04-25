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

) inherits ::adobe_experience_manager::params {
  
  validate_absolute_path($aem_home)
  validate_string($jar)
  validate_string($user)
  validate_string($group)
  validate_bool($manage_user)
  validate_bool($manage_group)
  validate_array($runmodes)
  
  
  
  if ! defined("$jar") {
    fail ('Installer jar required but not defined')
  }
  
  if $manage_group {
    group { $group:
      ensure => present,
    }
  }

  if $manage_user {
    user { $user:
      ensure => present,
      gid    => $group,
    }
  }
  
  file { $aem_home:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }
  
  
    
}
