
# Specify Sample Content Example
#
# Exclude sample content during install.
aem::instance { 'aem' :
  source         => '/path/to/aem-quickstart.jar',
  sample_content => false,
}
