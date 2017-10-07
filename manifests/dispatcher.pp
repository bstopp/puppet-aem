# This class exists soley to ensure that the module is properly defined.

class aem::dispatcher (
  $ensure             = 'present',
  $decline_root       = $::aem::dispatcher::params::decline_root,
  $dispatcher_name    = undef,
  $group              = $::aem::dispatcher::params::group,
  $log_file           = $::aem::dispatcher::params::log_file,
  $log_level          = $::aem::dispatcher::params::log_level,
  $module_file        = undef,
  $no_server_header   = $::aem::dispatcher::params::no_server_header,
  $pass_error         = $::aem::dispatcher::params::pass_error,
  $use_processed_url  = $::aem::dispatcher::params::use_processed_url,
  $user               = $::aem::dispatcher::params::user
) inherits ::aem::dispatcher::params {

  # Check for Apache because it is used by parameter defaults
  if ! defined(Class['apache']) {
    fail('You must include the apache base class before using any dispatcher class or defined resources')
  }

  anchor { 'aem::dispatcher::begin': }

  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if is_integer($decline_root) {
    validate_integer($decline_root, 1, 0)
  } else {
    validate_re($decline_root, '^(on|off)$', "${decline_root} is not supported for decline_root. Allowed values are 'on' and 'off'.")
  }

  if is_integer($log_level) {
    validate_integer($log_level, 3, 0)
  } else {
    validate_re($log_level, '^(error|warn|info|debug)$',
      "${log_level} is not supported for log_level. Allowed values are 'error', 'warn', 'info', and 'debug'.")
  }

  validate_absolute_path($module_file)
  $_mod_filename = basename($module_file)

  if is_integer($no_server_header) {
    validate_integer($no_server_header, 1, 0)
  } else {
    validate_re($no_server_header, '^(on|off)$',
      "${no_server_header} is not supported for no_server_header. Allowed values are 'on' and 'off'.")
  }

  if is_integer($use_processed_url) {
    validate_integer($use_processed_url, 1, 0)
  } else {
    validate_re($use_processed_url, '^(on|off)$',
      "${use_processed_url} is not supported for use_processed_url. Allowed values are 'on' and 'off'.")
  }

  $config_file = $::aem::dispatcher::params::config_file

  anchor { 'aem::dispatcher::end': }

  # Manage actions

  if ($ensure == 'present') {
    apache::mod { 'dispatcher' :
      lib => 'mod_dispatcher.so',
    }

    file { "${::aem::dispatcher::params::mod_path}/${_mod_filename}" :
      ensure  => file,
      group   => $group,
      owner   => $user,
      replace => true,
      seltype => 'httpd_module_t',
      source  => $module_file,
    }

    file { "${::aem::dispatcher::params::mod_path}/mod_dispatcher.so" :
      ensure  => link,
      group   => $group,
      owner   => $user,
      replace => true,
      seltype => 'httpd_module_t',
      target  => "${::aem::dispatcher::params::mod_path}/${_mod_filename}",
    }

    file { "${::aem::dispatcher::params::farm_path}/dispatcher.conf" :
      ensure  => file,
      group   => $group,
      owner   => $user,
      replace => true,
      content => template("${module_name}/dispatcher/dispatcher.conf.erb")
    }

    file {  "${::aem::dispatcher::params::farm_path}/${config_file}":
      ensure  => file,
      group   => $group,
      owner   => $user,
      replace => true,
      content => template("${module_name}/dispatcher/dispatcher.farms.erb")
    }

    Anchor['aem::dispatcher::begin']
    -> File["${::aem::dispatcher::params::mod_path}/${_mod_filename}"]
    -> File["${::aem::dispatcher::params::mod_path}/mod_dispatcher.so"]
    -> Apache::Mod['dispatcher']
    -> File["${::aem::dispatcher::params::farm_path}/${config_file}"]
    -> File["${::aem::dispatcher::params::farm_path}/dispatcher.conf"]
    -> Anchor['aem::dispatcher::end']

    if defined(Service[$::apache::service_name]) {
      Anchor['aem::dispatcher::begin']
      -> File["${::aem::dispatcher::params::farm_path}/${config_file}"]
      ~> Service[$::apache::service_name]
      -> Anchor['aem::dispatcher::end']

      Anchor['aem::dispatcher::begin']
      -> File["${::aem::dispatcher::params::farm_path}/dispatcher.conf"]
      ~> Service[$::apache::service_name]
      -> Anchor['aem::dispatcher::end']
    }

  } else {

    file { "${::aem::dispatcher::params::mod_path}/${_mod_filename}" :
      ensure => $ensure,
    }

    file { "${::aem::dispatcher::params::mod_path}/mod_dispatcher.so" :
      ensure => $ensure,
    }

    file { "${::aem::dispatcher::params::farm_path}/dispatcher.conf" :
      ensure => $ensure,
    }

    file { "${::aem::dispatcher::params::farm_path}/${config_file}" :
      ensure => $ensure,
    }

    Anchor['aem::dispatcher::begin']
    -> File["${::aem::dispatcher::params::farm_path}/dispatcher.conf"]
    -> File["${::aem::dispatcher::params::farm_path}/${config_file}"]
    -> File["${::aem::dispatcher::params::mod_path}/${_mod_filename}"]
    -> File["${::aem::dispatcher::params::mod_path}/mod_dispatcher.so"]
    -> Anchor['aem::dispatcher::end']

    if defined(Service[$::apache::service_name]) {
      Anchor['aem::dispatcher::begin']
      -> File["${::aem::dispatcher::params::farm_path}/${config_file}"]
      ~> Service[$::apache::service_name]
      -> Anchor['aem::dispatcher::end']

      Anchor['aem::dispatcher::begin']
      -> File["${::aem::dispatcher::params::farm_path}/dispatcher.conf"]
      ~> Service[$::apache::service_name]
      -> Anchor['aem::dispatcher::end']
    }
  }

}
