require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::instance', :type => :defines do

  let :default_facts do
    {
      :kernel           => 'Linux',
      :operatingsystem  => 'CentOS',
      :operatingsystemmajrelease  => '7',
    }
  end

  let :title do
    'aem'
  end

  let :default_params do
    {
      :source => '/tmp/aem-quickstart.jar'
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
end
