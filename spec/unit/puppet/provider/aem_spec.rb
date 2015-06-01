#!/usr/bin/evn ruby

require 'spec_helper'

provider_class = Puppet::Type.type(:aem).provider(:aem)

describe provider_class do

  let (:install_name) { 'cq-quickstart-*-standalone.jar' }

  let (:installs) do
    <<-FIND_OUTPUT
/opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar
/opt/aem/author/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar
/opt/aem/publish/crx-quickstart/app/cq-quickstart-6.1.0-standalone.jar
FIND_OUTPUT
  end

  before :each do
    Puppet::Util.stubs(:which).with('find').returns('/bin/find')
    provider_class.stubs(:which).with('find').returns('/bin/find')
  end

  describe 'self.instances' do
    
    it 'returns an array of installs' do
      Puppet::Util::Execution.expects(:execpipe).with("/bin/find / -name #{install_name} -type f").yields(installs)

      installed = provider_class.instances

      expect(installed[0].properties).to eq(
        {
          :home     => '/opt/aem',
          :version  => '5.6.1',
          :provider => :aem,
          :ensure   => :present,
        }
      )
      expect(installed[1].properties).to eq(
        {
          :home     => '/opt/aem/author',
          :version  => '6.0.0',
          :provider => :aem,
          :ensure   => :present,
        }
      )
      expect(installed.last.properties).to eq(
        {
          :home     => '/opt/aem/publish',
          :version  => '6.1.0',
          :provider => :aem,
          :ensure   => :present,
        }
      )

    end
  end

end

