node 'agent' {

  $osgi = {
    'handler.schemes'                     => [ 'jcrinstall', 'launchpad' ],
    'sling.jcrinstall.folder.name.regexp' => '.*/(install|config|bundles)$',
    'sling.jcrinstall.folder.max.depth'   => 5,
    'sling.jcrinstall.search.path'        => [ '/libs:100', '/apps:200', '/doesnotexist:10' ],
    'sling.jcrinstall.new.config.path'    => 'system/config',
    'sling.jcrinstall.signal.path'        => '/system/sling/installer/jcr/pauseInstallation',
    'sling.jcrinstall.enable.writeback'   => false
  }

  aem::osgi::config { 'JCRInstaller':
    ensure         => present,
    pid            => 'org.apache.sling.installer.provider.jcr.impl.JcrInstaller',
    properties     => $osgi,
    handle_missing => 'remove',
    home           => '/opt/aem/author',
    password       => 'admin',
    type           => 'console',
    username       => 'admin',
  }

}