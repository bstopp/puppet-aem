
### Auto Invalidate Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Automatically%20Invalidating%20Cached%20Files)

The *rank* configuration is used to prioritize the order in which the auto-invalidate rules are output, the lower the number the higher in the sequence. Default rank is *-1*.

Specifying the Auto Invalidate Rules:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot    => '/var/www',
  invalidate => [
    {
      'rank' => 310,
      'glob' => '*.html',
      'type' => 'allow'
    },
    {
      'rank' => 300,
      'glob' => '*',
      'type' => 'deny'
    }
  ],
}
~~~

This definition will create a file *dispatcher.site.any* with the following contents:

~~~ puppet
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
      /0 { /type "deny" /glob "*" }
    }

    /statfileslevel "3"

    /invalidate {
      /0 { /type "deny" /glob "*" }
      /1 { /type "allow" /glob "*.html" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }
}
~~~