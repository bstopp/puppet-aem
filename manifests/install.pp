# Class: adobe_experience_manager::install
#
# This class installs AEM into the configured directory.
#

class adobe_experience_manager::install {

  case $adobe_experience_manager::version {
    '6.0': { $req_java_version = 1.7 }
  }
  
  if !$java_major_version {
    fail('Java is required but not installed.')
  }
  
  file { $adobe_experience_manager::aem_home :
    ensure => directory,
    owner  => $adobe_experience_manager::user,
    group  => $adobe_experience_manager::group,
  }

}
