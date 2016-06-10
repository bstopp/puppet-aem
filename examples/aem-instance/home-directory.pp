
# Specific Home Directory Example

# This example shows how to customize the home directory in which AEM will be installed.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  home   => '/opt/aem/author',
}

# Managing Home Directory Example
#
# By default, the AEM Module will manage the home directory specified in the resource definition.
# This can be disabled using the manage_* attributes.

aem::instance { 'aem' :
  source      => '/path/to/aem-quickstart.jar',
  home        => '/opt/aem/author',
  manage_home => false,
}
