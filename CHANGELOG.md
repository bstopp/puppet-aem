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