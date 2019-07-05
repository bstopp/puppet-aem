node 'agent' {

  $props = {
    'jcr:primaryType' => 'nt:unstructured',
    'jcr:title'       => 'title string',
    'newtext'         => 'text string',
    'child'           => {
      'anotherproperty' => 'value',
      'grandchild2'     => {
        'jcr:primaryType' => 'nt:unstructured',
        'child attrib'    => 'another value',
        'array'           => ['this', 'is', 'an', 'array']
      }
    },
    'child2'          => {
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
    handle_missing => 'ignore',
    home           => '/opt/aem/author',
    password       => 'admin',
    username       => 'admin',
  }
}
