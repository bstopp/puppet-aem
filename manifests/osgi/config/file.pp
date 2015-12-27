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
  $properties,
  $user
){

  $file_props = {
    'properties' => $properties
  }

  file { "${home}/crx-quickstart/install/${name}.config" :
    ensure  => $ensure,
    group   => $group,
    content => epp("${module_name}/osgi.config.epp", $file_props),
    mode    => '0664',
    owner   => $user,
  }

  if defined(File[$home]) {
    File[$home]
    -> File["${home}/crx-quickstart/install/${name}.config"]
  }
}
