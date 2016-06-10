
# Specify OSGi Configurations Example
#
# Single Configuration using PID as resource title.

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

# Single Configuration using a the PID parameter

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


# Multiple Configurations

# Document Store and S3 Data store examples, PID as resource title.

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

# Multiple Configurations using PID parameters

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
