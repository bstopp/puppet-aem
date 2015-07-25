[![Build Status](https://travis-ci.org/bstopp/puppet-aem.svg?branch=master)](https://travis-ci.org/bstopp/puppet-aem)
[![Coverage Status](https://coveralls.io/repos/bstopp/puppet-aem/badge.svg?branch=feature%2Faem6&service=github)](https://coveralls.io/github/bstopp/puppet-aem?branch=feature%2Faem6)

# aem - Adobe Experience Manager

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with aem](#setup)
    * [What aem affects](#what-aem-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with aem](#beginning-with-aem)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

The AEM module installs, configures and manages an AEM instance.

## Module Description

The AEM module introduces the `aem` resource which is used to manage and configure an installation of AEM utilizing the Puppet DSL.

## Setup

### What AEM affects

  * AEM Installations

### Setup Requirements 

AEM uses Ruby-based providers, so you must enable pluginsync. Java is also required to be installed on the system. Finally, due to the AEM platform being proprietary, this module does not provide installation jar files, it must be provided by the consumer.

### Beginning with AEM

A minimal AEM configuration is specified as:

~~~
aem { 'aem' :
  ensure      => present,
  source      => '/path/to/aem-quickstart.jar',
  home        => '/path/to/home',
}
~~~

See [Useage](#usage) and [Reference](#reference) for options and detailed explanations.

## Usage

### AEM Resource

The `aem` resource definition is used to install and manage an AEM instance. An AEM installation is considered complete when the following steps have occurred:

  * Unpacking the source file (See [documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Further options available from the Quickstart file).)
  * Configuring the start script (See [documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/command-line-start-and-stop.html).)
  * Starting & Stopping the server, creating base repository. _This does not create a service._

_Configuring an AEM installation where an unmanaged one exists is undefined._

#### Minimal Definition

This is  the minimal required `aem` resource definition to install AEM. The default property values will be used, and the installation user:group will be `root:root`.

~~~
aem { 'aem' :
  ensure      => present,
  source      => '/path/to/aem-quickstart.jar',
  home        => '/path/to/home',
}
~~~

#### Specific User/Group Example

You can optionally specify either a user and/or group to own the installation. This user and/or group will be used when executing the installation process. (Normal policies apply, see Puppet Provider _execute(*args)_ DSL defintion.)

~~~
aem { 'aem' :
  ensure      => present,
  source      => '/path/to/aem-quickstart.jar',
  home        => '/path/to/home',
  user        => 'aem',
  group       => 'aem',
}
~~~

#### Specify type Example

You can specify the type of AEM installation to create. This is either `author` or `publish`, once specified it cannot be changed. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Installation Run Modes))

~~~
aem { 'aem' :
  ensure      => present,
  source      => '/path/to/aem-quickstart.jar',
  home        => '/path/to/home',
  type        => publish,
}
~~~

#### Specify port Example

You can specify the port on which AEM will listen. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Changing the Port Number by Renaming the File))

~~~
aem { 'aem' :
  ensure      => present,
  source      => '/path/to/aem-quickstart.jar',
  home        => '/path/to/home',
  port        => 8080,
}
~~~

## Reference

Types:

  * [aem](#type-aem)

###Type: aem

This type enables you to manage AEM instances within Puppet.

####Providers
**Note:** Not all features are available with all providers.

  * `linux`: Linux type provider
    * Supported features: 

**Autorequires:**

If Puppet is managing the home directory, user, or group parameters, the aem resource will autorequire those resources.

####Parameters

  * `name`: name of the AEM resource.

  * `ensure`: Ensures that the resource is present. Valid values are `present`, `absent`.

  * `source`: Source jar file to use, provided by user.

  * `version`: Optional. Version of AEM. If not specified, will be found via _quickstart_ jar name.

  * `home`: Home directory in which AEM will be installed. Default to `/opt/aem` or `C:/opt/aem` depending on platform.

  * `port`: Port on which AEM will listen. [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Changing the Port Number by Renaming the File) 

  * `user`: User for installation. Defaults to puppet user.

  * `group`: Group for installation. Defaults to puppet group.

  * `type`: AEM installation type, one of `author` or `publish`. [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Installation Run Modes)

  * `runmodes`: An array of runmodes to apply to the AEM instance [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html). Do not use this to set options available via `type` configuration.

  * `jvm_mem_opts`: Specify options for the JVM memory. This is separated from the JVM opts to simplify configurations. Defaults to `-Xmx1024m -XX:MaxPermSize=256M`.

  * `jvm_opts`: Options to pass to the JVM. There is no default for this property, but the following value is always passed: `-server -Djava.awt.headless=true`

  * `context_root`: The URL context root for the AEM applicaton. [Sling documentation](https://sling.apache.org/documentation/the-sling-engine/the-sling-launchpad.html). Defaults to `/`.

  * `samplecontent`: Whether or not to include the sample content (Geometrixx). [AEM Documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Using samplecontent and nosamplecontent). Defaults to `true`.

  * `timeout`: Timeout allowed for startup monitoring. If the installation doesn't finish by the timeout, an error will be generated. Value is specified in seconds. Default value: `10 minutes`.

  * `snooze`: Wait period between checks for installation completion. When monitoring the system for up state, this is the wait period between checks. Value is specified in seconds. Default value: `10 seconds`.

## Limitations

### OS Compatibility

This module has been tested on: 

  * CentOS 6, 7
  * Ubuntu 12.04, 14.04
  * Debian 6.0, 7.8 

### AEM Compatibility

This module has been tested with the following AEM versions:

  * 6.0
  * 6.1

### Warnings

Defining an AEM resource as absent will remove the instance from the system, regardless of whether or not it was originally managed by puppet.

## Development

This module in its early stages, any updates or feature additions are welcome. 

_Please make sure you do not include any AEM Installer jars in PRs._

