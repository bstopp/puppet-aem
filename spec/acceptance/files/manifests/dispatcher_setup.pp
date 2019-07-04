node "agent" {
  File { backup => false }

  class { apache: }
  class { aem::dispatcher:
    module_file => '/vagrant/puppet/files/dispatcher/dispatcher-apache-module.so',
    log_level => 'error'
  }
  aem::dispatcher::farm { 'site' : docroot => '/var/www' }

}