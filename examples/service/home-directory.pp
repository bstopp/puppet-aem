
# Custom Home Directory Example

aem::instance { 'aem' :
  source  => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
  home    => '/opt/aem/author',
}

aem::service { 'aem' :
  home    => '/opt/aem/author',
}

Aem::Instance['aem'] ~> Aem::Service['aem']

