# AEM Instance

## Specify Type Example

You can specify the type of AEM installation to create. This is either `author`, `publish`, or `standby`, which will also be added to the runmodes (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-3/deploy/configuring/configure-runmodes.html#Installation Run Modes)). 

The `standby` type can be used to obtain high availability in the case of a single author setup ([TarMK Cold Standby](https://helpx.adobe.com/experience-manager/6-3/sites/deploying/using/tarmk-cold-standby.html)). It is the only type where it makes sense to actually change it at some point in time, i.e. at failover.
By making it a separate type there is no risk of any runmode specific OSGi services from becoming active on the standby instance. This can have very nasty side effects if the assumption was made that there will only be one instance at any time (e.g. MQ listener services that start processing messages).  


~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  type   => 'publish',
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* Start in mode: *publish*

