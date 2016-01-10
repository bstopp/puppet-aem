# == Define: aem::dispatcher::farm
#
# Configure a Dispatcher instance.
define aem::dispatcher::farm(
  $ensure              = 'present',
  $allow_authorized    = undef,
  $allowed_clients     = $::aem::dispatcher::params::allowed_clients,
  $cache_headers       = $::aem::dispatcher::params::cache_headers,
  $cache_rules         = $::aem::dispatcher::params::cache_rules,
  $cache_ttl           = undef,
  $client_headers      = $::aem::dispatcher::params::client_headers,
  $docroot             = undef,
  $failover            = undef,
  $filters             = $::aem::dispatcher::params::filters,
  $grace_period        = undef,
  $health_check_url    = undef,
  $ignore_parameters   = undef,
  $invalidate          = $::aem::dispatcher::params::invalidate,
  $invalidate_handler  = undef,
  $propagate_synd_post = undef,
  $renders             = $::aem::dispatcher::params::renders,
  $retries             = undef,
  $retry_delay         = undef,
  $serve_stale         = $::aem::dispatcher::params::serve_stale,
  $session_management  = undef,
  $stat_file           = undef,
  $stat_files_level    = undef,
  $statistics          = undef,
  $sticky_connections  = undef,
  $unavailable_penalty = undef,
  $vanity_urls         = undef,
  $virtualhosts        = $::aem::dispatcher::params::virtualhosts
) {

  # Required dispatcher class because it is used by parameter defaults
  if ! defined(Class['aem::dispatcher']) {
    fail('You must include the aem::dispatcher base class before using any dispatcher class or defined resources')
  }

  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if $allow_authorized {
    validate_integer($allow_authorized, 1, 0)
  }

  if is_array($allowed_clients) {
    validate_hash($allowed_clients[0])
    $_allowed_clients = $allowed_clients
  } else {
    validate_hash($allowed_clients)
    $_allowed_clients = [$allowed_clients]
  }

  if $cache_headers {
    if is_array($cache_headers) {
      $_cache_headers = $cache_headers
    } else {
      $_cache_headers = [$cache_headers]
    }
  }

  if is_array($cache_rules) {
    validate_hash($cache_rules[0])
    $_cache_rules = $cache_rules
  } else {
    validate_hash($cache_rules)
    $_cache_rules = [$cache_rules]
  }

  if $cache_ttl {
    validate_integer($cache_ttl, 1, 0)
  }

  if is_array($client_headers) {
    $_client_headers = $client_headers
  } else {
    $_client_headers = [$client_headers]
  }

  validate_absolute_path($docroot)

  if $failover {
    validate_integer($failover, 1, 0)
  }

  if is_array($filters) {
    validate_hash($filters[0])
    $_filters = $filters
  } else {
    validate_hash($filters)
    $_filters = [$filters]
  }

  if $grace_period {
    validate_integer($grace_period, undef, 1)
  }

  if $health_check_url {
    validate_string($health_check_url)
  }

  if $ignore_parameters {
    if is_array($ignore_parameters) {
      validate_hash($ignore_parameters[0])
      $_ignore_parameters = $ignore_parameters
    } else {
      validate_hash($ignore_parameters)
      $_ignore_parameters = [$ignore_parameters]
    }
  }

  if is_array($invalidate) {
    validate_hash($invalidate[0])
    $_invalidate = $invalidate
  } else {
    validate_hash($invalidate)
    $_invalidate = [$invalidate]
  }

  if $invalidate_handler {
    validate_absolute_path($invalidate_handler)
  }

  if $propagate_synd_post {
    validate_integer($propagate_synd_post, 1, 0)
  }

  if is_array($renders) {
    validate_hash($renders[0])
    $_renders = $renders
  } else {
    validate_hash($renders)
    $_renders = [$renders]
  }

  if $retries {
    validate_integer($retries, undef, 1)
  }

  if $retry_delay {
    validate_integer($retry_delay, undef, 1)
  }

  if $serve_stale {
    validate_integer($serve_stale, 1, 0)
  }

  if $session_management {
    if $allow_authorized == 1 {
      fail('Allow authorized and session management are mutually exclusive.')
    }
    validate_hash($session_management)
    if !has_key($session_management, 'directory') {
      fail('Session management directory is not specified.')
    } else {
      validate_absolute_path($session_management['directory'])
    }
    if has_key($session_management, 'encode') {
      validate_re($session_management['encode'], '^(md5|hex)$',
        "${session_management['encode']} is not supported for session_management['encode']. Allowed values are 'md5' and 'hex'.")
    }
    if has_key($session_management, 'timeout') {
      validate_integer($session_management['timeout'], undef, 0)
    }
  }

  if $stat_file {
    validate_absolute_path($stat_file)
  }

  if $stat_files_level {
    validate_integer($stat_files_level, undef, 0)
  }

  if $statistics {
    if is_array($statistics) {
      validate_hash($statistics[0])
      $_statistics = $statistics
    } else {
      validate_hash($statistics)
      $_statistics = [$statistics]
    }
  }

  if $sticky_connections {
    if is_array($sticky_connections) {
      validate_string($sticky_connections[0])
    } else {
      validate_string($sticky_connections)
    }
  }

  if $unavailable_penalty {
    validate_integer($unavailable_penalty, undef, 1)
  }

  if $vanity_urls {
    validate_hash($vanity_urls)
    if !has_key($vanity_urls, 'file') {
      fail('Vanity Urls cache file is not specified.')
    } else {
      validate_absolute_path($vanity_urls['file'])
      validate_integer($vanity_urls['delay'], undef, 0)
    }
  }

  if !is_array($virtualhosts) {
    $_virtualhosts = [$virtualhosts]
  } else {
    $_virtualhosts = $virtualhosts
  }

  $_line_start = '  $include "dispatcher.'
  $_line_end = '.any"'

  if $ensure == 'present' {
    file { "${::aem::dispatcher::params::farm_path}/dispatcher.${name}.any" :
      ensure  => $ensure,
      content => template("${module_name}/dispatcher/dispatcher.any.erb"),
    }
    file_line { "include ${name}.any" :
      ensure  => $ensure,
      after   => '/farms \{',
      line    => "${_line_start}${name}${_line_end}",
      match   => "${_line_start}${name}${_line_end}",
      path    => "${::aem::dispatcher::params::farm_path}/${::aem::dispatcher::config_file}",
      require => File["${::aem::dispatcher::params::farm_path}/${::aem::dispatcher::config_file}"],
    }

  } else {

    file_line { "include ${name}.any" :
      ensure => $ensure,
      path   => "${::aem::dispatcher::params::farm_path}/${::aem::dispatcher::config_file}",
      line   => "${_line_start}${name}${_line_end}",
      match  => "${_line_start}${name}${_line_end}",
    }

    file { "${::aem::dispatcher::params::farm_path}/dispatcher.${name}.any" :
      ensure  => $ensure,
      require => File_line["include ${name}.any"],
    }
  }
}
