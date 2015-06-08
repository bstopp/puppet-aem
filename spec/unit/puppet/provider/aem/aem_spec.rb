#!/usr/bin/evn ruby

require 'spec_helper'

provider_class = Puppet::Type.type(:aem).provider(:aem)

describe provider_class do


  let(:source) { '/opt/aem/cq-author-4502.jar' }
  let (:install_name) { 'cq-quickstart-*-standalone*.jar' }

  let (:installs) do
    <<-FIND_OUTPUT
/opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar
/opt/aem/author/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar
/opt/aem/publish/crx-quickstart/app/cq-quickstart-6.1.0-standalone-launchpad.jar
FIND_OUTPUT
  end

  let(:aem_res) do
    Puppet::Type.type(:aem).new({
      :name     => 'aem',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
    })
  end

  let(:auth_res) do
    Puppet::Type.type(:aem).new({
      :name     => 'author',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem/author',
    })
  end

  let(:pub_res) do
    Puppet::Type.type(:aem).new({
      :name     => 'publish',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem/publish',
    })
  end
  
  let(:prov_resources) do
    providers = {}
    [aem_res, auth_res, pub_res].each do |res|
      provider = provider_class.new
      provider.resource = res
      providers[res[:name]] = provider
    end

    providers
  end

  
  before :each do
    Puppet::Util.stubs(:which).with('find').returns('/bin/find')
    provider_class.stubs(:which).with('find').returns('/bin/find')
  end


  describe 'self.instances' do

    it 'should have an instances method' do
      expect(described_class).to respond_to :instances
    end

    it 'returns an array of installs' do
      Puppet::Util::Execution.expects(:execpipe).with("/bin/find / -name #{install_name} -type f").yields(installs)

      installed = provider_class.instances

      expect(installed[0].properties).to eq(
        {
          :name     => '/opt/aem',
          :home     => '/opt/aem',
          :version  => '5.6.1',
          :ensure   => :present,
        }
      )
      expect(installed[1].properties).to eq(
        {
          :name     => '/opt/aem/author',
          :home     => '/opt/aem/author',
          :version  => '6.0.0',
          :ensure   => :present,
        }
      )
      expect(installed.last.properties).to eq(
        {
          :name     => '/opt/aem/publish',
          :home     => '/opt/aem/publish',
          :version  => '6.1.0',
          :ensure   => :present,
        }
      )

    end

  end

  describe 'self.prefetch' do
    # Why can't you test prefetch via unit tests?

#    it 'should have a prefetch  method' do
#      expect(described_class).to respond_to :prefetch
#    end
#
#    it 'should populate resources with provider' do
#
#      Puppet::Util::Execution.expects(:execpipe).at_least(:once).with("/bin/find / -name #{install_name} -type f").yields(installs)
#      File.stubs(:exists?).with(:source).returns(:true)
#      installs = provider_class.instances
#
#      expect(installs[0].name).to eq('/opt/aem')
#      expect(installs[1].name).to eq('/opt/aem/author')
#      expect(installs[2].name).to eq('/opt/aem/publish')
#
#      provider_class.prefetch(prov_resources)
#
#      # Just need to make sure resource names don't change.
#      expect(prov_resources['aem'].name).to eq(aem_res[:name])
#      expect(prov_resources['aem'].home).to eq(aem_res[:home])
#      expect(prov_resources['author'].name).to eq(auth_res[:name])
#      expect(prov_resources['publish'].name).to eq(pub_res[:name])
#
#    end
  end

  describe 'destroy' do

    it 'deletes the home directory' do
      Puppet::Util::Execution.expects(:execpipe).with("/bin/find / -name #{install_name} -type f").yields(installs)
      File.stubs(:exists?).with(source).returns(true)

      aem = Puppet::Type.type(:aem).new({
        :name     => 'aem',
        :ensure   => :present,
        :source   => source,
        :version  => '6.1',
      })

      FileUtils.stubs(:remove_entry_secure).with(aem[:home])


      provider = provider_class.new
      provider.resource = aem

      provider.destroy

    end

  end

end

