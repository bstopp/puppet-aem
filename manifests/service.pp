# Class: adobe_experience_manager::service
#
# Manages the AEM daemon
#
# Parameters:
#   - $service_name
#   - $service_enable
#   - $service_ensure
#   - $service_manage
#
# Actions:
#   - Manage AEM service
#
# Requires:
#   - AEM Class
#
# Sample Usage:
#
#    sometype { 'foo':
#      notify => Class['adobe_experience_manager::service'],
#    }
#
#

class adobe_experience_manager::service {
#  
#  # Require base class, default parameters are defined therein
#  if ! defined(Class['adobe_experience_manager::params']) {
#    fail('The adobe_experience_manager::params class is required to use adobe_experience_manager resources.')
#  }
#
#  validate_bool($service_enable)
#  validate_bool($service_manage)
#
#  case $service_ensure {
#    true, false, 'running', 'stopped': {
#      $_service_ensure = $service_ensure
#    }
#    default: {
#      $_service_ensure = undef
#    }
#
#  }
#
#  if $service_manage {
#    service { "aem-${service_name}" :
#      ensure => $_service_ensure,
#      name   => $service_name,
#      enable => $service_enable,
#    }
#  }
}
