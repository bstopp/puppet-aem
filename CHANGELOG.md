
## 2017-01-26 - Release 2.4.1
### Summary

Bug fix release.

* Fixed #80: Multiple packages are not supported.

## 2017-01-19 - Release 2.4.0
### Summary

* **Minimum Puppet version 4.2**
* Support for CRX Packages via file or API.
* Bug fix for Apache restart every Agent run when multiple farms.
* Bug fixes for Apache bindings.
* Bug fixes for Replication Agents
* Amazon Linux Service configuration
* Use new packer boxes for testing.
* Updating rubocop issues.
* Documentation updates.

#### Features:
* Dispatcher farms now have `priority` attribute for load ordering.
* CRX Package upload, installation, removal support.

## 2016-06-12 - Release 2.3.2
### Summary
Update to support new features in Dispatcher v4.2.

## 2016-06-12 - Release 2.3.1
### Summary
Update to notify the Apache Service when a change occurs in any of the dispatcher files.

## 2016-06-12 - Release 2.3.0
### Summary
Adding support for arbitrary Sling Resource creation. Also support for Replication agents; with custom type helpers.

#### Features:
* New `aem_sling_resource` Type for managing Sling Resources.
* New `aem::agent::replication` defines for managing Replication agents with support for all attributes.
* New `aem::agent::replication::publish` defines for managing Publish replication agents.
* New `aem::agent::replication::flush` defines for managing Flush replication agents.
* New `aem::agent::replication::reverse` defines for managing Reverse replication agents.
* New `aem::agent::replication::static` defines for managing Static replication agents.

## 2016-01-26 - Release 2.2.1
### Summary
Added ability to specify PID when configuring OSGi items. This allows multiple definitions, when more than one AEM instance exists on a server.

## 2016-01-12 - Release 2.2.0
### Summary
Added support for Dispatcher module, Dispatcher Farms, and OSGi configurations. Significant testing updates. Also significant updates to documentation and examples.

#### Features:
* New `aem::dispatcher` Class for managing Dispatcher module
* New `aem::dispatcher::farm` defines for defining a Dispatcher farm instance
* New `aem::osgi::config` defines for creating and managing OSGi Configurations

## 2015-10-01 - Release 2.1.0
### Summary
Adding service support; AEM instances are now automatically service enabled and started. All license types are included in resource lifecycle.

#### Features:
* New `aem::instance` property: *status*.
* New `aem::service` defines. See documentation on use.


## 2015-09-24 - Release 2.0.1
### Summary
Bug fix release.

#### Features:
Moved *start* file to templates folder to fix issue with module build.

## 2015-09-17 - Release 2.0.0
### Summary
Fully functional AEM installation module management. Installs and allows changing of standard AEM run configuration options.

#### Features:

Now works in Master/Agent environment.
Redesigned implementation to use DSL over custom types.

## 2015-07-28 - Release 1.0.0
### Summary
Fully functional AEM installation module management. Installs and allows changing of standard AEM run configuration options.

#### Features:
- README Updates.
- Significant unit test implementations.
- Support parameters: `context_root`, `debug_port`, `group`, `jvm_mem_opts`, `jvm_opts`, `port`, `runmodes`, `samplecontent`, `snooze`, `timeout`, `user`, `version`.
- Numerous bug fixes.

## 2015-07-29 - Release 0.1.0
### Summary
Initial release of functionality supporting definition and management of an AEM Installation.

#### Features:
- Specify `type` and `user`.
