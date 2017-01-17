# File Type Example

aem::crx::package { 'author-test-pkg' :
  ensure => present,
  group  => 'aem',
  home   => '/opt/aem',
  source => '/path/to/file.zip',
  user   => 'aem'
}

