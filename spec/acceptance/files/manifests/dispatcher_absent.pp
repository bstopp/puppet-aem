node "agent" {
  File { backup => false }

  class { apache: }
  class { aem::dispatcher:
    ensure => absent,
    module_file => '/vagrant/puppet/files/dispatcher/dispatcher-apache-module.so'
  }
}