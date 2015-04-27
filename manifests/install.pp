# Class: adobe_experience_manager::params
#
# This class installs AEM into the configured directory.
#
# Parameters:
# - The $aem_home, root of the AEM installation.
# - The $user AEM runs as.
# - The $group AEM runs as.
# - The $jar used to install AEM.
# - The $runmodes of the AEM instance
# - The $cab_file indicating that the initial installation of AEM has completed.

class adobe_experience_manager::install {
  $aem_home   = '/opt/aem'
  $user       = 'aem'
  $group      = 'aem'
  $runmodes   = ['author']
  $cabfile   = "${aem_home}/installed.cab"
  
}
  
  file { $aem_home:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }
