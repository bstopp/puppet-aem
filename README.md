
[Module Description]: #module-description

[Setup]: #setup
[Setup Requirements]: #setup-requirements
[Beginning with AEM]: #beginning-with-aem

[Reference]: #reference
[Public Classes]: #public-classes
[Public Defines]: #public-defines
[Private Defines]: #private-defines
[Private Types]: #private-types

[Limitations]: #limitations
[Known Issues]: #known-issues

[Development]: #development

[wiki]: https://github.com/bstopp/puppet-aem/wiki


[Adobe]: http://www.adobe.com
[Adobe Experience Manager]: http://www.adobe.com/marketing-cloud/enterprise-content-management.html

[Felix Configuration]: http://felix.apache.org/documentation/subprojects/apache-felix-config-admin.html

[Sling launchpad]: https://sling.apache.org/documentation/the-sling-engine/the-sling-launchpad.html
[Sling command-line-options]: https://sling.apache.org/documentation/the-sling-engine/the-sling-launchpad.html#command-line-options

[AEM Runmodes]: https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html
[AEM Sample Content]: https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Using%20samplecontent%20and%20nosamplecontent
[AEM Installation Runmodes]: https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Installation%20Run%20Modes
[AEM Java Requirements]: https://docs.adobe.com/docs/en/aem/6-1/deploy/technical-requirements.html#Java%20Virtual%20Machines

# aem - Adobe Experience Manager
[![Puppet Forge Version](https://img.shields.io/puppetforge/v/bstopp/aem.svg)](https://forge.puppetlabs.com/bstopp/aem)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/bstopp/aem.svg)](https://forge.puppetlabs.com/bstopp/aem)
[![Build Status](https://travis-ci.org/bstopp/puppet-aem.svg?branch=master)](https://travis-ci.org/bstopp/puppet-aem)
[![Dependency Status](https://gemnasium.com/bstopp/puppet-aem.svg)](https://gemnasium.com/bstopp/puppet-aem)
[![Code Climate](https://codeclimate.com/github/bstopp/puppet-aem/badges/gpa.svg)](https://codeclimate.com/github/bstopp/puppet-aem)
[![Test Coverage](https://codeclimate.com/github/bstopp/puppet-aem/badges/coverage.svg)](https://codeclimate.com/github/bstopp/puppet-aem/coverage)
[![Join the chat at https://gitter.im/bstopp/puppet-aem](https://badges.gitter.im/bstopp/puppet-aem.svg)](https://gitter.im/bstopp/puppet-aem?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

#### Table of Contents

1. [Module Description - What does the module do?][Module Description]
1. [Setup - The basics of getting started with AEM module][Setup]
  * [Setup Requirements][]
  * [Beginning with AEM][]
1. [Reference - AEM Module type and providers][Reference]
  * [Public Classes][]
  * [Public Defines][]
  * [Private Defines][]
  * [Private Types][]
1. [Limitations - OS compatibility, etc.][Limitations]
1. [Development - Contributing to the module][Development]

## Module Description

[Adobe Experience Manager][] (also known as AEM, formerly CQ5) is an enterprise content management system offered by [Adobe][]. This puppet module provides a set of tools to ease the tasks of installing, configuring and maintaining AEM instances.

## Setup

**What the AEM Puppet module affects**

- AEM Installation files and directories
- Service configuration and startup files
- Listened-to ports

**Note**: This module modifies AEM installation directories and configuration files, overwriting any existing configurations. AEM configurations should be managed by Puppet, as unmanaged configuration files may cause unexpected behaviour.

### Setup Requirements 

AEM uses Ruby-based providers, so you must enable pluginsync. Java is also required to be installed on the system. Finally, due to the AEM platform being proprietary, this module does not provide the installation jar file; it must be provided by the consumer.

### Beginning with AEM

A minimal AEM configuration is specified as:

~~~
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
}
~~~

For more options and detailed explanations, please see the [Puppet AEM Wiki][wiki]


## Reference

- **[Public Classes][]**
  - [Class: aem::dispatcher](#class-aemdispatcher)
- **[Public Defines][]**
  - [Define: aem::dispatcher::farm](#define-aemdispatcherfarm)
  - [Define: aem::instance](#define-aeminstance)
  - [Define: aem::license](#define-aemlicense)
  - [Define: aem::osgi::config](#define-aemosgiconfig)
  - [Define: aem::service](#define-aemservice)
- **[Private Defines][]**
  - [Define: aem::config](#define-aemconfig)
  - [Define: aem::osgi::config::file](#define-aemosgiconfigfile)
  - [Define: aem::package](#define-aempackage)
- **[Private Types][]**
  - [Type: Aem_Installer](#type-aem_installer)
  - [Type: Aem_Osgi_Config](#type-aem_osgi_config)

### Public Classes

#### Class: `aem::dispatcher`

Installs and configures a specified AEM Dispatcher module. For more details and examples see the [wiki](https://github.com/bstopp/puppet-aem/wiki/AEM%20Dispatcher)

**Note:** Currently only Apache HTTP is supported by this module.

#### `ensure`
Optional. Adds or removes the dispatcher configuration. Valid options: `present` or `absent`. Default: `present`.

#### `decline_root`
Optional. Sets the *DispatcherDelcineRoot* value for the dispatcher configuration. Valid options: `0`, `1`, `off` or `on`. Default: `off`.

#### `dispatcher_name`
Optional. Sets the *name* of the dispatcher in the root dispatcher farm file. Valid options: any string.

##### `group`
Optional. Sets the group for file ownership. Valid options: any valid group. Default: Apache's root group.

##### `log_file`
Optional. Sets the name and location of the dispatcher log file. Valid options: any fully qualified file name. Default: *<apache log root>/dispatcher.log*.

##### `log_level`
Optional. Sets the log level for dispatcher logging. Valid options: `0`, `1`, `2`, `3`, `error`, `warn`, `info`, `debug`. Default: `warn`.

#### `module_file`
Required. Specifies which dispatcher module will be loaded. Valid options: any absolute path to file.

#### `no_server_header`
Optional. Sets the *DispatcherNoServerHeader* value for the dispatcher configuration. Valid options: `0`, `1`, `off` or `on`. Default: `off`.

#### `pass_error`
Optional. Sets the *DispatcherPassError* value for the dispatcher configuration. Valid options: any string. Default: `0`.

#### `use_processed_url`
Optional. Sets the *DispatcherUseProcessedURL* value for the dispatcher configuration. Valid options: `0`, `1`, `off` or `on`. Default: `off`.

##### `user`
Optional. Sets the user for for file ownership. Valid options: any valid user. Default: `root`.

### Public Defines

#### Define: `aem::dispatcher::farm`

Configures a single farm instance within the Dispatcher. For more details and examples, see the [wiki](https://github.com/bstopp/puppet-aem/wiki/AEM%20Dispatcher%20Farm)

##### `ensure`
Optional. Adds or removes the dispatcher farm configuration. Valid options: `present` or `absent`. Default: `present`.

##### `allow_authorized`
Optional. Sets the cache */allowAuthorized* rule. Valid options: `0` or `1`.

##### `allowed_clients`
Optional. Sets the cache */allowedClients* section. Valid options: Hash, or Array of Hashes. Default:
~~~ puppet
{
  'type' => 'allow',
  'glob' => '*',
}
~~~

##### `cache_headers`
Optional. Sets the cache */headers* section. Valid options: String or Array of Strings.

##### `cache_rules`
Optional. Sets the cache */rules* section. Valid options: Hash, or Array of Hashes. Default:
~~~ puppet
{
  'type' => 'deny',
  'glob' => '*',
}
~~~

##### `cache_ttl`
Optional. Sets the cache */enableTTL* rule. Valid options: `0` or `1`.

##### `client_headers`
Optional. Sets the */clientheaders* rule. Valid options: String or Array of Strings. Default: `*`

##### `docroot`
Required. Sets the cache */docroot* rule. Valid options: any absolute path.

##### `failover`
Optional. Sets the */failover* rule. Valid options: `0` or `1`.

##### `filters`
Optional. Sets the */fiters* section. Valid options: Hash, or Array of Hashes. Default:
~~~ puppet
{
  'type' => 'allow',
  'glob' => '*',
}
~~~

##### `grace_period`
Optional. Sets the cache */grace* rule. Valid options: any positive integer.

##### `ignore_parameters`
Optional. Sets the cache */ignoreUrlParams* section. Valid options: Hash, or Array of Hashes.

##### `invalidate`
Optional. Sets the cache */invalidate* section. Valid options: Hash, or Array of Hashes. Default:
~~~ puppet
[
  {
    'type' => 'allow',
    'glob' => '*',
  }
]
~~~

##### `invalidate_handler`
Optional. Sets the cache */invalidateHandler* rule. Valid options: any absolute path to file.

##### `propagate_synd_post`
Optional. Sets the */propagateSyndPost* rule. Valid options: `0` or `1`.

##### `renders`
Optional. Sets the */renders* section. Valid options: Hash, or Array of Hashes. Default:
~~~ puppet
{
  'hostname' => 'localhost',
  'port'     => 4503,
}
~~~

##### `retries`
Optional. Sets the */numberOfRetries* rule. Valid options: any positive integer.

##### `retry_delay`
Optional. Sets the */retryDelay* rule. Valid options: any positive integer.

##### `serve_stale`
Optional. Sets the cache */serveStaleOnError* rule. Valid options: `0` or `1`.

##### `session_management`
Optional. Sets the */sessionmanagement* section. Valid options: Hash of values.

##### `stat_file`
Optional. Sets the cache */statfile* rule. Valid options: any absolute path to file.

##### `stat_files_level`
Optional. Sets the cache */statfileslevel* rule. Valid options: any integer >= 0.

##### `statistics`
Optional. Sets the */statistics* section. Valid options: Hash of values.

##### `sticky_connections`
Optional. Sets the */stickyConnectionsFor* rule or */stickyConnectionsFor* section based on value.. Valid options: String or Array of Strings.

##### `unavailable_penalty`
Optional. Sets the */unavailablePenalty* rule. Valid options: any positive integer.

##### `vanity_urls`
Optional. Sets the */vanity_urls* section. Valid options: Hash of values.

##### `virtualhosts`
Optional. Sets the */virtualhosts* section. Valid options: String or Array of Strings. Default: `*`.

#### Define: `aem::instance`

Installs an AEM instance into your system. For more details and examples see the [wiki](https://github.com/bstopp/puppet-aem/wiki/AEM%20Instance)

When this type is declared with the default options, Puppet:

- Unpacks the specified AEM jar file.
- Configures the AEM start scripts with the default configuration options.
- Starts AEM for the first time to ensure repository creation.
- Shuts AEM down to create a consistent state.
- Defines and starts an AEM Service for the instance.

See [Beginning with AEM][] for the minimum configuration required to create an AEM installation. It is suggested that you customize the AEM definion with the following parameters, as the default parameters are not recommended for production.

**Parameters within `aem::instance`:**

##### `name`
Namevar. Required. Specifies the name of the AEM instance.

##### `ensure`
Optional. Changes the state of the AEM instance. Valid options: `present` or `absent`. Default: `present`.

##### `context_root`
Optional. Specifies the URL context root for the AEM application. [Sling documentation][Sling launchpad]. Valid options: any valid URI path. Defaults to `/`.

##### `debug_port`
Optional. Specifies the port on which to listen for remote debugging connections. Setting this will add the following JVM options: `-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=<<port>>` Valid options: any port number.

##### `group`
Optional. Sets the group for installation. Valid options: any valid group. Default: `aem`.

##### `home`
Optional. Sets the directory in which AEM will be installed. Valid options: any absolute path. Default: `/opt/aem`.

##### `jvm_mem_opts`
Optional. Specifies options for the JVM memory. This is separated from the JVM opts to simplify configurations. Valid options: any valid JVM parameter string. Default: `-Xmx1024m`.

##### `jvm_opts`
Optional. Specifies options to pass to the JVM. Valid options: any valid JVM parameter string. Default: None. The following string is always passed, and cannot be overwritten: `-server -Djava.awt.headless=true`

##### `manage_group`
Optional. Sets whether or not this instance will manage the defined group. Valid options: `true` or `false`. Default: `true`.

##### `manage_home`
Optional. Sets whether or not this instance will manage the defined home directory. Valid options: `true` or `false`. Default: `true`.

##### `manage_user`
Optional. Sets whether or not this instance will manage the defined user. Valid options: `true` or `false`. Default: `true`.

##### `osgi_configs`
Optional. Creates *file* type definitions of `aem::osgi::config` which will be applied prior to inital AEM start. Valid options: Hash or Array of Hash configurations.

##### `port`
Optional. Specifies the port on which AEM will listen. Valid options: any valid port. Default: 4502. [Sling documentation][Sling command-line-options]

##### `runmodes`
Optional. Sets the array of runmodes to apply to the AEM instance. Do not use this to set options available via `type` configuration, or a `sample_content` state. Valid options: any string array. [AEM documentation][AEM Runmodes].

##### `sample_content`
Optional. Sets whether or not to include the sample content (e.g. Geometrixx). Valid options: `true` or `false`. Default: `true`. [AEM Documentation][AEM Sample Content].

##### `snooze`
Optional. Sets the wait period between checks for installation completion. When monitoring the system for up state, this is the wait period between checks. Value is specified in seconds. Valid options: any number. Default: `10`.

##### `source`
Required. Sets the source jar file to use, provided by user. Valid options: any absolute path to file.

##### `status`
Optional. Changes the state of the service on the system, defining whether or not the service starts at system boot and/or is currently running. Valid options:
* `enabled`: Start at boot & currently running (**Default**)
* `disabled`: Not started at boot & not currently running.
* `running`: Not started at boot but is currently running.
* `unmanaged`: Don't manage it with service manager, running state is arbitrary.

##### `timeout`
Optional. Sets the timeout allowed for startup monitoring. If the installation doesn't finish by the timeout, an error will be generated. Value is specified in seconds. Valid option: any number. Default: `600` (10 minutes).

##### `type`
Optional. Specifies the AEM installation type. Valid options: `author` or `publish`. Default: `author`. [AEM documentation][AEM Installation Runmodes]

##### `user`
Optional. Sets the user for installation. Valid options: any valid user. Default: `aem`.

##### `version`
Optional. Sets the version of AEM. Informational only, does not affect installation or resource management. Valid options: any semantic version.

#### Define: `aem::license`

Manages an AEM License file. Provides a convenient tool for managing the license file contents without needing ot know the structure. For examples, see the [wiki](https://github.com/bstopp/puppet-aem/wiki/AEM%20License)

**Parameters within `aem::license`:**

##### `name`
Namevar. Required. Specifies the name of the AEM license.

##### `ensure`
Optional. Changes the state of the AEM license. Valid options: `present` or `absent`. Default: `present`.

##### `customer`
Optional. Specifies the customer name for the license file. Valid options: any string

##### `group`
Optional. Sets the group for file ownership. Valid options: any valid group. Default: `aem`.

##### `home`
Required. Sets the directory in which the license will be placed. Valid options: any absolute path.

##### `license_key`
Required. Sets the license key for AEM. Valid options: any string.

##### `user`
Optional. Sets the user for for file ownership. Valid options: any valid user. Default: `aem`.

##### `version`
Optional. Sets the version of AEM for the license file contents. Valid options: any string.

#### Define: `aem::osgi::config`

Manages an AEM OSGi Configuration; allows for saving Service/Component configurations via a file or posted to the Felix Web Console. For examples, see the [wiki](https://github.com/bstopp/puppet-aem/wiki/AEM%20OSGi%20Config)

**Parameters within `aem::osgi::config`:**

##### `name`
Namevar. Required. Specifies the name of the AEM OSGi Configuration. This should be the Service PID. [Apache Felix Documentation][Felix Configuration]

##### `ensure`
Optional. Changes the state of the AEM OSGi configuration. A value of `absent` will delete the configuration. Valid options: `present` or `absent`. Default: `present`.

##### `group`
Optional. Sets the group for file ownership. Valid options: any valid group. Default: `aem`.

##### `handle_missing`
Required if **type** == `console`. Determine how to handle properties which are configured in the console, but not provided. See [wiki][wiki] for examples. Valid options: `merge` or `remove`.

##### `home`
Required. Sets the directory in which AEM exists. Valid options: any absolute path.

##### `password`
Required if **type** == `console`. Sets the password of the OSGI console user. Valid options: any valid password.

##### `properties`
Required. Sets the configuration properties to persist. Valid options: a hash of values.

##### `type`
Required. Sets the means by which to persist the configuration. Valid options:  `console` or `file`. `console` will use API calls to the OSGi Web Console. `file` will persist to a properties file in the *crx-quickstart/install* folder.

##### `user`
Optional. Sets the user for for file ownership. Valid options: any valid user. Default: `aem`.

##### `username`
Required if **type** == `console`. Sets the user for accessing the OSGI console. Valid options: any valid user.

#### Define: `aem::service`

Manages the AEM daemon. Creating a defintion for this is not necesary unless the `aem::instance`'s *manage_service* is **false**. For examples, see the [wiki](https://github.com/bstopp/puppet-aem/wiki/AEM%20Service)

**Parameters within `aem::service`:**

##### `name`
Namevar. Required. Specifies the name of the AEM Service.

##### `ensure`
Optional. Changes the state of the AEM Service within puppet. Valid options: `present` or `absent`. Default: `present`.

##### `group`
Optional. Sets the group for file ownership. Valid options: any valid group. Default: `aem`.

##### `home`
Required. Sets the directory in which the AEM instance exists, necessary for service configuration definition. Valid options: any absolute path.

##### `status`
Optional. Changes the state of the service on the system, defining whether or not the service starts at system boot and/or is currently running. Valid options:
* `enabled`: Start at boot & currently running (**Default**)
* `disabled`: Not started at boot & not currently running.
* `running`: Not started at boot but is currently running.
* `unmanaged`: Don't manage it with service manager, running state is arbitrary.

##### `user`
Optional. Sets the user for for file ownership. Valid options: any valid user. Default: `aem`.

### Private Defines

#### Define: `aem::package`
This define unpacks the AEM Quickstart jar for prepartion to configure.

#### Define: `aem::config`
This define sets up the start templates to ensure the AEM instance executes with the correct state.

#### Define: `aem::osgi::config::file`
This define is used to manage OSGi Configurations which are of type `file`.

### Private Types

#### Type: `aem_installer`
This custom type starts the AEM instance to create the base repository, monitors for it's initalization, then shuts the system down.

#### Type: `aem_osgi_config`
This custom type manages OSGi Configurations which are of type `console`.

## Limitations

### Dependencies

The `aem::dispatcher` class requires the Puppet Apache module; however since the use of this class is optional, this dependency is not delcared explicitly.

### OS Compatibility

This module has been tested on: 

- CentOS 7, 7.2
- Ubuntu 12.04*, 14.04
- Debian 7.8*, 8.2

*See [Known Issues][]*

### AEM Compatibility

This module has been tested with the following AEM versions:

- 6.0
- 6.1

### Minimum Ruby Requirement

Using the OSGi Configuration options require a Minimum ruby version of 1.9.x.

### Warnings

It is up to the consumer to ensure that the correct version of Java is installed based on the AEM version. See [AEM Documentation][AEM Java Requirements] for compatibility.

Defining an AEM resource as absent will remove the instance from the system, regardless of whether or not it was originally managed by puppet.

### Known Issues

Ubuntu 12.04 ships with Ruby 1.8.x; therefore the OSGi configurations acceptance tests fail.

There is an oddity with the `aem::service` support on Debian: even though specifying a valid status sends the correct parameters to the underlying service resource, the service is not enabled, nor do state changes occur correctly. Acceptance tests on those Virtual Machines fail for issues with service management. See [issue #36](https://github.com/bstopp/puppet-aem/issues/36).

## Development

This module in its early stages, any updates or feature additions are welcome. 

_Please make sure you do not include any AEM Installer jars in PRs._
