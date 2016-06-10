
## Specify Debug Port Example

You can start AEM with it listening for socket debugging requests. (See [AEM Help](https://helpx.adobe.com/experience-manager/kb/CQ5HowToSetupRemoteDebuggingWithEclipse.html))

~~~ puppet
aem::instance { 'aem' :
  source     => '/path/to/aem-quickstart.jar',
  debug_port => 30303,
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following additions:**

* AEM will listen on port 30303 for remote debugging.
