# == Define: aem::osgi::config::file
#
# Creates an OSGI configuration file in the install folder.
#
# Do not use this defines directly.
#
define aem::osgi::config::file(
  $ensure,
  $group,
  $home,
  $pid,
  $properties,
  $user
){

  if $pid == undef {
    $_pid = $name
  } else {
    $_pid = $pid
  }

  $file_props = {
    'properties' => $properties,
    'pid' => $_pid
  }

  file { "${home}/crx-quickstart/install/${_pid}.config" :
    ensure  => $ensure,
    group   => $group,
    content => epp("${module_name}/osgi.config.epp", $file_props),
    mode    => '0664',
    owner   => $user,
  }

  if defined(File[$home]) {
    File[$home]
    -> File["${home}/crx-quickstart/install/${_pid}.config"]
  }
}
