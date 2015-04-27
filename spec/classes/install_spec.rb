  context 'invalid aem home path' do
    let :params do
      {
        'jar'       => '/opt/aem/cq-author-4502.jar',
        :aem_home => 'not/a/fully/qualified/path',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /absolute path/)
    end
  end
