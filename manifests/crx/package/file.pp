# == Define: aem::crx::package::file
#
# Copies a package file to the AEM the install folder.
#
# Do not use this defines directly.
#
define aem::crx::package::file(
  $ensure,
  $group,
  $home,
  $source,
  $user
){

  $_filename = basename($source)

  file { "${home}/crx-quickstart/install/${_filename}" :
    ensure => $ensure,
    group  => $group,
    source => $source,
    mode   => '0664',
    owner  => $user,
  }

  if defined(File[$home]) {
    File[$home]
    -> File["${home}/crx-quickstart/install/${_filename}"]
  }

}
