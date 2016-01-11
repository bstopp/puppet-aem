# == Class: aem::dispatcher::apache
#
# This manages an AEM Dispatcher configuration.
#
class aem::dispatcher::params {

  if $::osfamily == 'RedHat' or $::operatingsystem == 'amazon' {

    $mod_path = "${::apache::httpd_dir}/${::apache::lib_path}"
    $farm_path = $::apache::mod_dir

  } elsif $::osfamily == 'Debian' {

    $mod_path = $::apache::lib_path
    $farm_path = $::apache::mod_enable_dir

  } else {

    fail("Class['aem::dispatcher::params']: Unsupported osfamily: ${::osfamily}")

  }
  
  $allowed_clients = {
    'type' => 'allow',
    'glob' => '*',
  }

  $cache_rules = {
    'type' => 'deny',
    'glob' => '*',
  }

  $client_headers = '*'

  $config_file = 'dispatcher.farms.any'

  $decline_root = 'off'

  $filters = {
    'type' => 'allow',
    'glob' => '*',
  }

  $group = $::apache::root_group

  $invalidate = [
    {
      'type' => 'allow',
      'glob' => '*',
    }
  ]

  $log_file = "${::apache::logroot}/dispatcher.log"

  $log_level = 'warn'

  $no_server_header = 'off'

  $pass_error = '0'

  $renders = {
    'hostname' => 'localhost',
    'port'     => 4503,
  }

  $use_processed_url = 'off'

  $user = 'root'

  $virtualhosts = '*'

}
