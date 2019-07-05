node 'agent' {

  $props = {
    'jcr:primaryType' => 'nt:unstructured',
    'title'           => 'title string',
    'text'            => 'text string',
    'child'           => {
      'jcr:primaryType' => 'nt:unstructured',
      'property'        => 'value',
      'grandchild'      => {
        'jcr:primaryType' => 'nt:unstructured',
        'child attrib'    => 'another value',
        'array'           => ['this', 'is', 'an', 'array']
      }
    }
  }

  aem_sling_resource { 'test node':
    ensure         => present,
    path           => '/content/testnode',
    properties     => $props,
    handle_missing => 'remove',
    home           => '/opt/aem/author',
    password       => 'admin',
    username       => 'admin',
  }

}