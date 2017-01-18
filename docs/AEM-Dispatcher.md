# Dispatcher

The `aem::dispatcher` resource allows you to enable the Dispatcher Module in Apache. By default, no Dispatcher Farms are configured, to configure them, see: [aem::dispatcher::farm](/docs/AEM-Dispatcher-Farm.md)

For information on dispatcher configuration details see [Dispatcher Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-install.html#Apache%20Web%20Server%20-%20Configure%20Apache%20Web%20Server%20for%20Dispatcher)

**Note**: It's up to consumers to ensure the correct version of the Dispatcher Module is referenced.

* [Default](#default-dispatcher-class-example)
* [Custom](#custom-dispatcher-class-example)


## Default Dispatcher Class Example

This example enables the Dispatcher module with the default configurations:

~~~ puppet
class { 'aem::dispatcher' :
  module_file => '/path/to/dispatcher-module.so',
}
~~~

This definition loads the dispatcher module into the Apache and configures it with:

* Farm file: *dispatcher.farms.any* in the default Apache configuration directory
* The farm will not have a reference name
* Log file: *dispatcher.log* in the default Apache log directory
* DispatcherLogLevel: *warn*
* DispatcherNoServerHeader: *off*
* DispatcherDelcineRoot: *off*
* DispatcherUseProcessedURL: *off*
* DispatcherPassError: *0*

## Custom Dispatcher Class Example

This is an example of how each field can be configured. The fields which are flags support either 0 or 1, and 'on' or 'off'.

~~~ puppet
class { 'aem::dispatcher' :
  decline_root      => 1,
  dispatcher_name   => 'named instance',
  log_file          => '/path/to/log/dir/my-dispatcher.log',
  log_level         => 3,
  module_file       => '/path/to/dispatcher-module.so',
  no_server_header  => 'on',
  use_processed_url => 1,
  pass_error        => '400-404,500',
}
~~~

This definition loads the dispatcher module into the Apache and configures it with:

* Farm file: *dispatcher.farms.any* in the default Apache configuration directory
* The farm will have a name referenced: *named-instance*
* Log file: *my-dispatcher.log*, in the directory: */path/to/log*
* DispatcherLogLevel: *3*
* DispatcherNoServerHeader: *on*
* DispatcherDelcineRoot: *1*
* DispatcherUseProcessedURL: *1*
* DispatcherPassError: *400-404,500*
