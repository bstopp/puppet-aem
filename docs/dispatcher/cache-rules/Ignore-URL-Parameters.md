### Ignore URL Parameters Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Ignoring%20URL%20Parameters)

Specifying the URL parameters to ignore:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot           => '/var/www',
  ignore_parameters => [
    {
      'rank' => 310,
      'glob' => 'param=*',
      'type' => 'allow'
    },
    {
      'rank' => 300,
      'glob' => '*',
      'type' => 'deny'
    },
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
      /0 { /type "deny" /glob "*" }
    }

    /statfileslevel "3"

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }

    /ignoreUrlParams {
      /0 { /type "deny" /glob "*" }
      /1 { /type "allow" /glob "param=*" }
    }

  }
}
~~~