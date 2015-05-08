# Class: adobe_experience_manager::install
#
# This class installs AEM into the configured directory.
#

class adobe_experience_manager::install(
  $cabfile        = "${adobe_experience_manageer::aem_home}/installed.cab"
) {

  if !$::java_major_version {
    fail('Java is required but not installed.')
  }

  $req_java_version = $adobe_experience_manager::version ? {
    '6.0'     => '1.7',
    default   => '.*'
  }
    
  if ($req_java_version == '.*') {
    warning("Unrecognized/unspecified version of AEM (${adobe_experience_manager::version}) specified.")
    warning('Unable to validate Java requirement, proceeding with unknown results')
  }
  
  validate_re($::java_major_version, $req_java_version, 
    'The installed version of Java is not supported for the specified version of AEM')
  
  file { $adobe_experience_manager::aem_home :
    ensure => directory,
    owner  => $adobe_experience_manager::user,
    group  => $adobe_experience_manager::group,
  }

}
