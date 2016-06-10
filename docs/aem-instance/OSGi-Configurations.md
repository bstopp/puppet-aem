
## Specify OSGi Configurations Example


**Note**: OSGi Configuraton Factories are not supported; Felix does not have a mechanism for correctly defining them via a file.

* [Single Configuration](#single-configuration)
* [Single Configuration w/ PID](#single-configuration-w-pid)
* [Multiple Configurations](#multiple-configurations)
* [Multiple Configurations w/ PID](#multiple-configurations-w-pid)

### Single Configuration

You can provide OSGi configurations to be applied prior to the initial AEM Startup. This is necessary for some OSGi settings such as using MongoDB for document node storage or Amazon's S3 Data store. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/platform/data-store-config.html))

This parameter creates `aem::osgi::config` resources with *type => file*

~~~ puppet
$osgi = {
  'org.apache.jackrabbit.oak.plugins.document.DocumentNodeStoreService' => {
    'mongouri'        => 'mongodb://localhost:27017',
    'db'              => 'aem',
  }
}


aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  osgi_configs => $osgi,
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following additions:**

* Use Mongo for the Document Store

### Single Configuration w/ PID

This parameter creates `aem::osgi::config` resources with *type => file*

~~~ puppet
$osgi = {
  'DocumentNodeStoreService-Author' => {
    'pid'        => 'org.apache.jackrabbit.oak.plugins.document.DocumentNodeStoreService',
    'properties' => {
      'mongouri'        => 'mongodb://localhost:27017',
      'db'              => 'aem',
    }
  }
}


aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  osgi_configs => $osgi,
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following additions:**

* Use Mongo for the Document Store

### Multiple Configurations

You can provide an array of OSGi configurations to be applied.

~~~
$osgi = [
  {
    'org.apache.jackrabbit.oak.plugins.document.DocumentNodeStoreService' => {
      'mongouri'        => 'mongodb://localhost:27017',
      'db'              => 'aem',
      'customBlobStore' => true,
    },
    'org.apache.jackrabbit.oak.plugins.blob.datastore.S3DataStore' => {
      'accessKey' => 'username',
      'secretKey' => 'password',
      's3Bucket'  => 'bucket-name',
      's3Region'  => 'aws-region',
    }
  }
]

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  osgi_configs => $osgi,
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following additions:**

* Use Mongo for the Document Store
* Use Amazon's S3 Bucket for the Blob Data Store

### Multiple Configurations w/ PID

You can provide an array of OSGi configurations to be applied.

~~~
$osgi = [
  {
    'DocumentNodeStoreService-Author' => {
      'pid'        => 'org.apache.jackrabbit.oak.plugins.document.DocumentNodeStoreService', 
      'properties' => {
        'mongouri'        => 'mongodb://localhost:27017',
        'db'              => 'aem',
        'customBlobStore' => true,
      }
    },
    'S3DataStore-Author' => {
      'pid'        => 'org.apache.jackrabbit.oak.plugins.blob.datastore.S3DataStore',
      'properties' => {
        'accessKey' => 'username',
        'secretKey' => 'password',
        's3Bucket'  => 'bucket-name',
        's3Region'  => 'aws-region',
      }
    }
  }
]

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  osgi_configs => $osgi,
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following additions:**

* Use Mongo for the Document Store
* Use Amazon's S3 Bucket for the Blob Data Store

