
# Specific User/Group Example
#
# This example shows how to customize the user/group which own the files in the installation.
# (Normal policies apply, see Puppet Provider execute(*args) DSL definition.)

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  user   => 'vagrant',
  group  => 'vagrant',
}

# Managing User/Group Example
#
# By default, the AEM Module will manage the user/group specified in the resource definition.
# This can be disabled using the manage_* attributes.

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  manage_group => false,
  manage_user  => false,
  user         => 'vagrant',
  group        => 'vagrant',
}
