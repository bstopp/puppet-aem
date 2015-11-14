[![Build Status](https://travis-ci.org/bstopp/puppet-aem.svg?branch=master)](https://travis-ci.org/bstopp/puppet-aem)
[![Dependency Status](https://gemnasium.com/bstopp/puppet-aem.svg)](https://gemnasium.com/bstopp/puppet-aem)
[![Code Climate](https://codeclimate.com/github/bstopp/puppet-aem/badges/gpa.svg)](https://codeclimate.com/github/bstopp/puppet-aem)
[![Test Coverage](https://codeclimate.com/github/bstopp/puppet-aem/badges/coverage.svg)](https://codeclimate.com/github/bstopp/puppet-aem/coverage)

# aem - Adobe Experience Manager

#### Table of Contents

1. [Overview - What is the AEM module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with AEM module](#setup)
    * [What AEM affects](#what-aem-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with AEM](#beginning-with-aem)
4. [Usage - How to use the module](#usage)
5. [Reference - AEM Module type and providers](#reference)
    * [Public defines](#public-defines)
    * [Private defines](#private-defines)
    * [Private types](#private-types)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Contributing to the module](#development)

## Overview

The AEM module installs, configures and manages an AEM installation, license, and service.

## Module Description

The AEM module introduces the `aem::instance` resource which is used to manage and configure an installation of AEM utilizing the Puppet DSL. This module also introduces the `aem::license` and `aem::service` types; see usage for details.

## Setup

### What AEM affects

AEM Installations may be modified by using this module. See [warnings](#warnings), for how existing instances are affected by enabling a this module.

### Setup Requirements 

AEM uses Ruby-based providers, so you must enable pluginsync. Java is also required to be installed on the system. Finally, due to the AEM platform being proprietary, this module does not provide the installation jar file; it must be provided by the consumer.

### Beginning with AEM

A minimal AEM configuration is specified as:

~~~
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
}
~~~

See [Useage](#usage) and [Reference](#reference) for options and detailed explanations.

## Usage

### Aem::Instance

The `aem::instance` resource definition is used to install and manage an AEM instance. An AEM installation is considered complete when the following steps have occurred:

  * Unpacking the source file (See [documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Further options available from the Quickstart file).)
  * Configuring the start script (See [documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/command-line-start-and-stop.html).)
  * Starting & Stopping the server, creating base repository. _This does not create a service._

_Configuring an AEM installation where an unmanaged one exists is undefined (Theoretically it should work)._

### Aem::License

The `aem::license` resource definition is used to install and manage an AEM license file. As of v2.1.0 of this module, all `aem::license` catalog entries are applied as part of the module resource lifecycle. All `aem::license` entries are guaranteed to be applied before an associated `aem::service` resource (if *status* is not **unmanaged**).

**Upgrading to 2.1.0 may require edits to catalogs if explicit dependency was specified.**

### Aem::Service

The `aem::service` resource definition is used to install and manage an AEM Instance as a service. Setting the `aem::instance` parameter to any value other than **unmanaged** will create a service defintion with the specified state. The name of the service will be *aem-&lt;name&gt;*, where *&lt;name&gt;* is the namevar of the `aem::instance`.

#### Minimal Definition

This is the minimal required `aem::instance` resource definition to install AEM. The default property values will be used, and the installation user:group will be `aem:aem`. This user and group will be created. The AEM instance will be installed to `/opt/aem`, which will also be created. A service definition wil be created (named *'aem-aem'*), enabled andrunning. 

~~~
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
}
~~~

#### Specific User/Group Example

You can optionally specify either a user and/or group to own the installation. This user and/or group will be used when executing the installation process. (Normal policies apply, see Puppet Provider _execute(*args)_ DSL defintion.)

~~~
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  user   => 'vagrant',
  group  => 'vagrant',
}
~~~

#### Specify type Example

You can specify the type of AEM installation to create. This is either `author` or `publish`. Once an instance is created, changing the defintion will update the associated configuration script. However this update will have no impact on the operation of the AEM instance. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Installation Run Modes))

~~~
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  type   => 'publish',
}
~~~

#### Specify port Example

You can specify the port on which AEM will listen. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Changing the Port Number by Renaming the File))

~~~
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  port   => 8080,
}
~~~

#### Specify runmodes Example

You can specify additional runmodes for the AEM instance. See notes on *runmodes* usage with respect to *type* and *sample_content*. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Customized Run Modes))

~~~
aem::instance { 'aem' :
  source   => '/path/to/aem-quickstart.jar',
  runmodes => ['dev', 'server', 'mock'],
}
~~~

#### Specify samplecontent Example

You can disable the sample content (Geometrixx) that comes with AEM. See notes on *sample_content* usage with respect to *runmodes*. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Using samplecontent and nosamplecontent))

~~~
aem::instance { 'aem' :
  source         => '/path/to/aem-quickstart.jar',
  sample_content => false,
}
~~~

#### Specify License Example

This is an example for defining an AEM instance, and a license.

~~~
# Add Instance
aem::instance { 'aem' :
  source         => '/path/to/aem-quickstart.jar',
  sample_content => false,
}
# Add License
aem::license { 'aem' :
  customer    => 'Customer Name',
  home        => '/opt/aem',
  license_key => 'enter-your-key-here',
  version     => '6.1.0',
}
~~~

## Reference

- [**Public Defines**](#public-defines)
  - [Define: aem::instance](#define-aeminstance)
  - [Define: aem::license](#define-aemlicense)
  - [Define: aem::service](#define-aemservice)
- [**Private Defines**](#private-defines)
  - [Define: aem::package](#define-aempackage)
  - [Define: aem::config](#define-aemconfig)
- [**Private Types**](#private-types)
  - [Type: Aem_Installer](#type-aem_installer)

### Public Defines

#### Define: `aem::instance`

This type enables you to manage AEM instances within Puppet. Declare one `aem::instance` per managed AEM server desired.

**Parameters within `aem::instance`:**

##### `name`
Namevar. Required. Specifies the name of the AEM instance.

##### `ensure`
Optional. Changes the state of the AEM instance. Valid values are `present` or `absent`. Default: `present`.

##### `context_root`
Optional. Specifies the URL context root for the AEM application. [Sling documentation](https://sling.apache.org/documentation/the-sling-engine/the-sling-launchpad.html). Defaults to `/`.

##### `debug_port`
Optional. Specifies the port on which to listen for remote debugging connections. Setting this will add the following JVM options: `-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=<<port>>` Valid options: any port number.

##### `group`
Optional. Sets the group for installation. Valid options: any valid group. Default: `aem`.

##### `home`
Optional. Sets the directory in which AEM will be installed. Valid options: Any absolute system path. Default: `/opt/aem`.

##### `jvm_mem_opts`
Optional. Specifies options for the JVM memory. This is separated from the JVM opts to simplify configurations. Valid options: any valid JVM parameter string. Default: `-Xmx1024m -XX:MaxPermSize=256M`.

##### `jvm_opts`
Optional. Specifies options to pass to the JVM. Valid options: any valid JVM parameter string. Default: None, but the following value is always passed, and cannot be overwritten: `-server -Djava.awt.headless=true`

##### `manage_group`
Optional. Sets whether or not this instance will manage the defined group. Valid options: `true` or `false`. Default: `true`.

##### `manage_home`
Optional. Sets whether or not this instance will manage the defined home directory. Valid options: `true` or `false`. Default: `true`.

##### `manage_user`
Optional. Sets whether or not this instance will manage the defined user. Valid options: `true` or `false`. Default: `true`.

##### `port`
Optional. Specifies the port on which AEM will listen. Valid options: any valid port. Default: 4502. [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Changing the Port Number by Renaming the File)

##### `runmodes`
Optional. Sets the array of runmodes to apply to the AEM instance. Do not use this to set options available via `type` configuration, or a `sample_content` state. Valid options: any string array. [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html).

##### `sample_content`
Optional. Sets whether or not to include the sample content (e.g. Geometrixx). Valid options: `true` or `false`. Default: `true`. [AEM Documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Using samplecontent and nosamplecontent).

##### `snooze`
Optional. Sets the wait period between checks for installation completion. When monitoring the system for up state, this is the wait period between checks. Value is specified in seconds. Valid options: any number. Default: `10`.

##### `source`
Required. Sets the source jar file to use, provided by user. Valid options: any absolute file.

##### `status`
Optional. Changes the state of the service on the system, defining whether or not the service starts at system boot and/or is currently running. Valid values are:
* `enabled`: Start at boot & currently running (**Default**)
* `disabled`: Not started at boot & not currently running.
* `running`: Not started at boot but is currently running.
* `unmanaged`: Don't manage it with service manager, running state is arbitrary.

##### `timeout`
Optional. Sets the timeout allowed for startup monitoring. If the installation doesn't finish by the timeout, an error will be generated. Value is specified in seconds. Valid option: any number. Default: `600`.

##### `type`
Optional. Specifies the AEM installation type. Valid options: `author` or `publish`. Default: `author`. [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Installation Run Modes)

##### `user`
Optional. Sets the user for installation. Valid options: any valid user. Default: `aem`.

##### `version`
Optional. Sets the version of AEM. Informational only, does not affect installation or resource management. Valid options: any semantic version. 

#### Define: `aem::license`

This type enables you to manage AEM license. Declare one `aem::license` per managed AEM server.

** Parametrs within `aem::license`:**

##### `name`
Namevar. Required. Specifies the name of the AEM license.

##### `ensure`
Optional. Changes the state of the AEM license. Valid values are `present` or `absent`. Default: `present`.

##### `customer`
Optional. Specifies the customer name for the license file.

##### `group`
Optional. Sets the group for file ownership. Valid options: any valid group. Default: `aem`.

##### `home`
Required. Sets the directory in which the license will be placed. Valid options: Any absolute system path.

##### `license_key`
Required. Sets the license key for AEM. Valid options: any string.

##### `user`
Optional. Sets the user for for file ownership. Valid options: any valid user. Default: `aem`.

##### `version`
Optional. Sets the version of AEM for the license file contents. Valid options: any string. 

#### Define: `aem::service`

This type enables you to manage an AEM instance as a service. Creating a separate configuration for this is not necesary unless the `aem::instance`'s *manage_service* is **false**. Declare one `aem::service` per managed AEM server.

** Parametrs within `aem::service`:**

##### `name`
Namevar. Required. Specifies the name of the AEM Service.

##### `ensure`
Optional. Changes the state of the AEM Service within puppet. Valid values are `present` or `absent`. Default: `present`.

##### `group`
Optional. Sets the group for file ownership. Valid options: any valid group. Default: `aem`.

##### `home`
Required. Sets the directory in which the AEM instance exists, necessary for service configuration definition. Valid options: Any absolute system path.

##### `status`
Optional. Changes the state of the service on the system, defining whether or not the service starts at system boot and/or is currently running. Valid values are:
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

### Private Types

#### Type: `aem_installer`
This custom type starts the AEM instance to create the base repository, monitors for it's initalization, then shuts the system down.

## Limitations

### OS Compatibility

This module has been tested on: 

  * CentOS 6, 7
  * Ubuntu 12.04, 14.04
  * Debian 6.0, 7.8*

*See [Known Issues](#known-issues)*

### AEM Compatibility

This module has been tested with the following AEM versions:

  * 6.0
  * 6.1

### Warnings

It is up to the consumer to ensure that the correct version of Java is installed based on the AEM version. See [AEM Documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/technical-requirements.html) for compatibility.

Defining an AEM resource as absent will remove the instance from the system, regardless of whether or not it was originally managed by puppet.

### Known Issues

There is an oddity with the `aem::service` support on Debian: even though specifying a valid status sends the correct parameters to the underlying service resource, the service is not enabled, nor do state changes occur correctly. Acceptance tests on those Virtual Machines fail for issues with service management. See [issue #36](https://github.com/bstopp/puppet-aem/issues/36).

## Development

This module in its early stages, any updates or feature additions are welcome. 

_Please make sure you do not include any AEM Installer jars in PRs._
