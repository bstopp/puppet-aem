# Class: adobe_experience_manager::params
#
# This class manages AEM parameters.
#
# Parameters:
# - $aem_home is the root of the AEM installation.
# - The $user AEM runs as.
# - The $group AEM runs as.
# - The $jar used to install AEM.
# - The $runmodes of the AEM instance
# - The 

class adobe_experience_manager::params {
  $aem_home   = '/opt/aem'
  $user       = 'aem'
  $group      = 'aem'
  $jar        = '/opt/aem/cq-author-4502.jar'
  $runmodes    = ['author']
}