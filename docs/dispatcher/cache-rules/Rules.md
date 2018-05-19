# Dispatcher - Cache Rules

### Rules Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Specifying%20the%20Documents%20to%20Cache)

The *rank* configuration is used to prioritize the order in which the rules are output, the lower the number the higher in the sequence. Default rank is *-1*.


There are two methods for defining a Cache-rule hash. If the hash contains the _glob_ key, then only the _type_ and _glob_ values will be used. Otherwise the advanced attributes are used, which contain:

  * type
  * url
  * query
  * protocol
  * path
  * selectors
  * extension
  * suffix

dispatcher.any supports regular globbing and POSIX expressions, which interpreter to use is defined by different quotes (single quotes `'` for POSIX, double quotes `"` for regular globbing.)  Cache rules can use regular globbing using `glob` or `method`,`url`,`query`,`protocol`,`path`,`suffix`, or it can use POSIX interpreter using `glob_e` or `method_e`,`url_e`,`query_e`,`protocol_e`,`path_e`,`suffix_e`. `selectors_e` and `extension_e` had been default using `selectors` and `extension` before and both will always output POSIX for compatibility.

Specifying the Cache Rules:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  cache_rules => [
    {
      'rank' => 310,
      'glob' => '*.html',
      'type' => 'allow'
    },
    {
      'rank' => 300,
      'glob' => '*',
      'type' => 'deny'
    },
    {
      'rank' => 320,
      'method_e' => '(GET|POST)',
      'path_e' => '/etc[./](clientlibs|designs).*',
      'extension_e' => '(css|js|jpe?g|png)',
      'type' => 'allow'
    }
  ],
}
~~~

This definition will create a file *dispatcher.site.any* with the following contents:

~~~
/anothersite {

  /clientheaders {
    "*"
  }

  /virtualhosts {
    "*"
  }

  /renders {
    /renderer0 {
      /hostname "localhost"
      /port "4503"
    }
  }

  /filter {
    /0 { /type "allow" /glob "*" }
  }

  /cache {

    /docroot "/var/www"

    /allowAuthorized "1"

    /rules {
      /000 { /type "deny" /glob "*" }
      /001 { /type "allow" /glob "*.html" }
      /002 { /type "allow" /method '(GET|POST)' /path '/etc[./](clientlibs|designs).*' /extension '/etc[./](clientlibs|designs).*' }
    }

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }
}
~~~