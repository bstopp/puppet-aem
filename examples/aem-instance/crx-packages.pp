

# AEM Instance w/ Packages installed prior to Start-up.

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  crx_packages => ['/path/to/file.zip']
}
