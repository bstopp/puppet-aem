# AEM Instance

## Specify Quickstart Start Options Example

You can start with arbitrary Quickstart Start Options, e.g. if you need to enforce no fork.

~~~ puppet
aem::instance { 'aem' :
  source     => '/path/to/aem-quickstart.jar',
  start_opts => '-nofork'
}
~~~
