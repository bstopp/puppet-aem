node 'agent' {
  File { backup => false, owner => 'aem', group => 'aem' }

  aem::instance { 'author':
    ensure       => absent,
    manage_user  => false,
    manage_group => false,
    manage_home  => false,
    user         => 'vagrant',
    group        => 'vagrant',
    home         => '/opt/aem/author',
  }
}