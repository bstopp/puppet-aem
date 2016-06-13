# Dispatcher Farm Cache Rules Allow Authorized Example

aem::dispatcher::farm { 'site' :
  docroot          => '/var/www',
  allow_authorized => 1,
}