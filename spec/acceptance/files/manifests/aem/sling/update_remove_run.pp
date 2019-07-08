node 'agent' {

  $props = {
    'jcr:primaryType' => 'nt:unstructured',
    'jcr:title'       => 'title string',
    'newtext'         => 'text string',
    'child'           => {
      'anotherproperty' => 'new value',
      'grandchild2'     => {
        'jcr:primaryType' => 'nt:unstructured',
        'child attrib'    => 'changed value',
        'array'           => ['this', 'is', 'a', 'longer', 'array']
      }
    },
    'child2'          => {
      'jcr:primaryType' => 'nt:unstructured',
      'property'        => 'value',
      'grandchild'      => {
        'jcr:primaryType' => 'nt:unstructured',
        'child attrib'    => 'another value'
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