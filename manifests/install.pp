# Class: adobe_experience_manager::install
#
# This class installs AEM into the configured directory.
#

class adobe_experience_manager::install {

  if !$::java_major_version {
    fail('Java is required but not installed.')
  }

  case $adobe_experience_manager::version {
    '6.0':    { $req_java_version = '1.7' }
    default:  { 
      warning("Unrecognized/unspecified version of AEM ($adobe_experience_manager::version) specified.")
      warning("Unable to validate Java requirement, proceeding with unknown results")
      $req_java_version = '.*'  
    }
  }
  
    validate_re("${java_major_version}", "${req_java_version}", 'The installed version of Java is not supported for the specified version of AEM')
}
