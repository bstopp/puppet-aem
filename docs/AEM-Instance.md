# AEM Instance

The `aem::instance` resource definition is used to install and manage an AEM instance. An AEM installation is considered complete when the following steps have occurred:

* Unpacking the source file (See [documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Further options available from the Quickstart file).)
* Configuring the start script (See [documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/command-line-start-and-stop.html).)
* Starting & Stopping the server, creating base repository.

_Configuring an AEM installation where an unmanaged one exists is undefined (Theoretically it should work)._

#### Examples

* [Minimal](aem-instance/Minimal.md)
* [Home Directory](aem-instance/Home-Directory.md)
* [User/Group](aem-instance/User-Group.md)
* [Type](aem-instance/Type.md)
* [Port](aem-instance/Port.md)
* [Samplecontent](aem-instance/Samplecontent.md)
* [JVM Memory](aem-instance/JVM-Memory.md)
* [Sevice Configruation](aem-instance/Service-Configuration.md)
* [Runmodes](aem-instance/Runmodes.md)
* [Context Root](aem-instance/Context-Root.md)
* [Debug Port](aem-instance/Debug-Port.md)
* [JVM Options](aem-instance/JVM-Options.md)
* [OSGi Configurations](aem-instance/OSGi-Configurations.md)

