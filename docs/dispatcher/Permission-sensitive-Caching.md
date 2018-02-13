# Dispatcher

## Permission-sensitive caching

[See Documentation](https://helpx.adobe.com/experience-manager/dispatcher/using/permissions-cache.html)

This example creates a Farm definition that performs permission checks only on secure HTML resources:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot        => '/var/www',
  auth_checker => {
    url => '/bin/permissioncheck',
    filter => [
      {
        'type' => 'deny',
        'glob' => '*',
      },
      {
        'type' => 'allow',
        'glob' => '/content/secure/*.html',
      }
    ],
    headers => [
      {
        'type' => 'deny',
        'glob' => '*',
      },
      {
        'type' => 'allow',
        'glob' => 'Set-Cookie:*',
      }
    ],
  },
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

    /rules {
      /0 { /type "deny" /glob "*" }
    }

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }

  /auth_checker {

    /url "/bin/permissioncheck"

    /filter {
      /0 { /type "deny" /glob "*" }
      /1 { /type "allow" /glob "/content/secure/*.html" }
    }

    /headers {
      /0 { /type "deny" /glob "*" }
      /1 { /type "allow" /glob "Set-Cookie:*" }
    }
  }
}
~~~
