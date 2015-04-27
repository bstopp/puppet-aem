# Class: adobe_experience_manager::install
#
# This class installs AEM into the configured directory.
#

class adobe_experience_manager::install {

  file { $adobe_experience_manager::aem_home :
    ensure => directory,
    owner  => $adobe_experience_manager::user,
    group  => $adobe_experience_manager::group,
  }

}
