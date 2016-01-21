require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::config', :type => :defines do

  let :default_facts do
    {
      :kernel                    => 'Linux',
      :operatingsystem           => 'CentOS',
      :operatingsystemmajrelease => '7'
    }
  end

  let :title do
    'aem'
  end

  let :default_params do
    {
      :context_root   => :undef,
      :debug_port     => :undef,
      :group          => 'aem',
      :home           => '/opt/aem',
      :jvm_mem_opts   => :undef,
      :jvm_opts       => :undef,
      :osgi_configs   => :undef,
      :port           => :undef,
      :runmodes       => [],
      :sample_content => true,
      :type           => 'author',
      :user           => 'aem'
    }
  end

  describe 'start env script options' do
    let :facts do
      default_facts
    end
    let :params do
      default_params
    end

    context 'context root' do
      let :params do
        default_params.merge(:context_root => 'contextroot')
      end

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with_content(
          /CONTEXT_ROOT='contextroot'/
        )
      end

    end

    context 'debug port' do
      let :params do
        default_params.merge(:debug_port => 12_345)
      end

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with_content(
          /DEBUG_PORT=12345/
        )
      end
    end

    context 'jvm_mem_opts' do
      let :params do
        default_params.merge(:jvm_mem_opts => '-XmxAllYourMemory')
      end

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with(
          'content' => /JVM_MEM_OPTS='-XmxAllYourMemory'/
        )
      end
    end

    context 'jvm_opts' do
      let :params do
        default_params.merge(:jvm_opts => 'Some Options')
      end

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with(
          'content' => /JVM_OPTS='Some Options'/
        )
      end
    end

    context 'port' do
      let :params do
        default_params.merge(:port => 12_345)
      end

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with(
          'content' => /PORT=12345/
        )
      end
    end

    context 'runmodes' do
      let :params do
        default_params.merge(:runmodes => %w(test runmodes))
      end

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with(
          'content' => /RUNMODES='test,runmodes'/
        )
      end
    end

    context 'sample content' do
      context 'disabled' do
        let :params do
          default_params.merge(:sample_content => false)
        end

        it do
          is_expected.to contain_file(
            '/opt/aem/crx-quickstart/bin/start-env'
          ).with('content' => /SAMPLE_CONTENT='nosamplecontent'/)
        end
      end

      context 'enabled' do
        it do
          is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env').with('content' => /SAMPLE_CONTENT=''/)
        end
      end
    end

    context 'type' do
      context 'author' do
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env').with('content' => /TYPE='author'/) }
      end
      context 'publish' do
        let :params do
          default_params.merge(:type => 'publish')
        end
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env').with('content' => /TYPE='publish'/) }
      end
    end

  end

  describe 'file defintions' do
    let :facts do
      default_facts
    end
    let :params do
      default_params
    end

    context 'group' do
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with(
          :group => 'aem'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start.orig'
        ).with(
          :group => 'aem'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start'
        ).with(
          :group => 'aem'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install'
        ).with(
          :group => 'aem'
        )
      end
    end

    context 'user' do
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start-env'
        ).with(
          :owner => 'aem',
          :mode => '0775'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start.orig'
        ).with(
          :owner => 'aem'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/bin/start'
        ).with(
          :owner => 'aem'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install'
        ).with(
          :ensure => :directory,
          :owner => 'aem'
        )
      end
    end
  end

  describe 'osgi configurations' do
    let :facts do
      default_facts
    end
    let :params do
      default_params
    end

    let :cfg_props1 do
      {
        'key' => 'value',
        'key2' => 'value2',
      }
    end
    let :cfg_props2 do
      {
        'key3' => 'value3',
        'key4' => 'value4',
      }
    end
    let :params do
      default_params.merge({
        :osgi_configs => [
          {
            'osgi.name' => { 'properties' => cfg_props1 }
          },
          {
            'osgi2.name' => { 'properties' => cfg_props2 }
          }
        ]
      })
    end
    
    context 'defines first config resource' do
      it do
        is_expected.to contain_aem__osgi__config(
          'osgi.name'
        ).with(
          :group       => 'aem',
          :home        => '/opt/aem',
          :properties  => cfg_props1,
          :type        => 'file',
          :user        => 'aem'
        )
      end
    end
    context 'defines second config resource' do
      it do
        is_expected.to contain_aem__osgi__config(
          'osgi2.name'
        ).with(
          :group       => 'aem',
          :home        => '/opt/aem',
          :properties  => cfg_props2,
          :type        => 'file',
          :user        => 'aem'
        )
      end
    end
  end

  describe 'osgi configurations with pid' do
    let :facts do
      default_facts
    end
    let :params do
      default_params
    end

    let :cfg_props1 do
      {
        'key' => 'value',
        'key2' => 'value2',
      }
    end
    let :cfg_props2 do
      {
        'key3' => 'value3',
        'key4' => 'value4',
      }
    end
    let :params do
      default_params.merge({
        :osgi_configs => [
          {
            'osgi.name' => {
              'pid'        => 'aem.config1',
              'properties' => cfg_props1
            }
          },
          {
            'osgi2.name' => {
              'pid'        => 'aem.config2',
              'properties' => cfg_props2
            }
          }
        ]
      })
    end
    
    context 'defines first config resource' do
      it do
        is_expected.to contain_aem__osgi__config(
          'osgi.name'
        ).with(
          :group       => 'aem',
          :home        => '/opt/aem',
          :pid         => 'aem.config1',
          :properties  => cfg_props1,
          :type        => 'file',
          :user        => 'aem'
        )
      end
    end
    context 'defines second config resource' do
      it do
        is_expected.to contain_aem__osgi__config(
          'osgi2.name'
        ).with(
          :group       => 'aem',
          :home        => '/opt/aem',
          :pid         => 'aem.config2',
          :properties  => cfg_props2,
          :type        => 'file',
          :user        => 'aem'
        )
      end
    end
  end
end
