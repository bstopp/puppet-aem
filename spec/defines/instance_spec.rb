require 'spec_helper'

# Tests for the resources created by the class.
describe 'aem::instance', :type => :defines do

  let(:default_facts) do
    {
      :kernel                     => 'Linux',
      :operatingsystem            => 'CentOS',
      :operatingsystemmajrelease  => '7'
    }
  end

  let(:title) do
    'aem'
  end

  let(:default_params) do
    {
      :source => '/tmp/aem-quickstart.jar'
    }
  end

  context 'default install' do

    let(:params) do
      default_params
    end
    let(:facts) do
      default_facts
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_user('aem').with(
        :ensure => 'present',
        :gid    => 'aem'
      )
    end

    it { is_expected.to contain_group('aem').with('ensure' => 'present') }

    it { is_expected.to contain_anchor('aem::aem::begin') }

    it do
      is_expected.to contain_aem__package(
        'aem'
      ).with(
        :ensure      => 'present',
        :group       => 'aem',
        :home        => '/opt/aem',
        :manage_home => true,
        :source      => '/tmp/aem-quickstart.jar',
        :user        => 'aem'
      )
    end

    it do
      is_expected.to contain_aem__service('aem').with(
        :ensure => 'present',
        :status => 'enabled',
        :home   => '/opt/aem',
        :user   => 'aem',
        :group  => 'aem'
      )
    end

    it do
      is_expected.to contain_aem__config(
        'aem'
      ).with(
        :context_root   => nil,
        :debug_port     => nil,
        :group          => 'aem',
        :home           => '/opt/aem',
        :jvm_mem_opts   => '-Xmx1024m',
        :jvm_opts       => nil,
        :osgi_configs   => nil,
        :port           => 4502,
        :runmodes       => [],
        :sample_content => true,
        :type           => 'author',
        :user           => 'aem'
      )
    end

    it do
      is_expected.to contain_aem_installer(
        'aem'
      ).with(
        :ensure  => 'present',
        :home    => '/opt/aem',
        :snooze  => 10,
        :timeout => 600
      )
    end

    it { is_expected.to contain_aem__package('aem').that_requires('Group[aem]') }
    it { is_expected.to contain_group('aem').that_requires('Anchor[aem::aem::begin]') }

    it { is_expected.to contain_group('aem').that_requires('Anchor[aem::aem::begin]') }
    it { is_expected.to contain_user('aem').that_requires('Anchor[aem::aem::begin]') }

    it { is_expected.to contain_aem_installer('aem').that_requires('Aem::Config[aem]') }
    it { is_expected.to contain_aem__config('aem').that_requires('Aem::Package[aem]') }
    it { is_expected.to contain_aem__config('aem').that_notifies('Aem::Service[aem]') }

    it { is_expected.to contain_aem__package('aem').that_requires('Anchor[aem::aem::begin]') }

  end

  describe 'osgi configs' do

    context 'single definition' do
      let(:cfg_props) do
        {
          'key'  => 'value',
          'key2' => 'value2'
        }
      end
      let(:params) do
        default_params.merge(
          :osgi_configs => {
            'osgi.name' => { 'properties' => cfg_props }
          }
        )
      end

      let(:facts) do
        default_facts
      end

      it { is_expected.to compile.with_all_deps }
      it do
        is_expected.to contain_aem__config(
          'aem'
        ).with(
          :context_root   => nil,
          :debug_port     => nil,
          :group          => 'aem',
          :home           => '/opt/aem',
          :jvm_mem_opts   => '-Xmx1024m',
          :jvm_opts       => nil,
          :osgi_configs   => { 'osgi.name' => { 'properties' => cfg_props } },
          :port           => 4502,
          :runmodes       => [],
          :sample_content => true,
          :type           => 'author',
          :user           => 'aem'
        )
      end

    end

    context 'multiple definitions' do
      let(:cfg_props1) do
        {
          'key' => 'value',
          'key2' => 'value2'
        }
      end
      let(:cfg_props2) do
        {
          'key3' => 'value3',
          'key4' => 'value4'
        }
      end
      let(:params) do
        default_params.merge(
          :osgi_configs => [
            {
              'osgi.name' =>  { 'properties' => cfg_props1 }
            },
            {
              'osgi2.name' => { 'properties' => cfg_props2 }
            }
          ]
        )
      end

      let(:facts) do
        default_facts
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_aem__config(
          'aem'
        ).with(
          :context_root   => nil,
          :debug_port     => nil,
          :group          => 'aem',
          :home           => '/opt/aem',
          :jvm_mem_opts   => '-Xmx1024m',
          :jvm_opts       => nil,
          :osgi_configs   => [
            {
              'osgi.name' => {
                'properties' => cfg_props1
              }
            },
            {
              'osgi2.name' => {
                'properties' => cfg_props2
              }
            }
          ],
          :port           => 4502,
          :runmodes       => [],
          :sample_content => true,
          :type           => 'author',
          :user           => 'aem'
        )
      end
    end

  end

  context 'default remove' do

    let(:params) do
      default_params.merge(:ensure => 'absent')
    end
    let(:facts) do
      default_facts
    end

    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_file('/opt/aem').with('ensure' => 'absent') }

    it { is_expected.to contain_file('/opt/aem').that_requires('File[/opt/aem/crx-quickstart]') }

    it { is_expected.to contain_user('aem').with('ensure' => 'absent') }
    it { is_expected.to contain_group('aem').with('ensure' => 'absent') }

    it { is_expected.to contain_aem__package('aem').with('ensure' => 'absent') }
    it { is_expected.to contain_aem__service('aem').with('ensure' => 'absent') }

    it { is_expected.to contain_aem__service('aem').that_requires('Anchor[aem::aem::begin]') }
    it { is_expected.to contain_aem__package('aem').that_requires('Aem::Service[aem]') }
  end
end
