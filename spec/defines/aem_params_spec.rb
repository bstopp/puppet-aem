require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem::instance', :type => :defines do

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
      :source => '/tmp/aem-quickstart.jar'
    }
  end

  context 'default values' do
    let :facts do
      default_facts
    end

    let :params do
      default_params
    end

    it { is_expected.to compile.with_all_deps }
    it do
      is_expected.to contain_aem__instance('aem').only_with(
        'ensure'          => 'present',
        'group'           => 'aem',
        'home'            => nil,
        'jvm_mem_opts'    => '-Xmx1024m',
        'manage_group'    => true,
        'manage_home'     => true,
        'manage_user'     => true,
        'port'            => 4502,
        'runmodes'        => [],
        'sample_content'  => true,
        'status'          => 'enabled',
        'source'          => '/tmp/aem-quickstart.jar',
        'snooze'          => 10,
        'timeout'         => 600,
        'type'            => 'author',
        'user'            => 'aem'
      )
    end
  end

  context 'parameter validation' do
    let :facts do
      default_facts
    end

    let :params do
      default_params
    end

    context 'ensure' do

      context 'absent' do
        let :params do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('ensure' => 'absent') }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:ensure => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'context_root' do
      let :params do
        default_params.merge(:context_root => 'contextroot')
      end
      it { is_expected.to compile }
      it { is_expected.to contain_aem__instance('aem').with('context_root' => 'contextroot') }
    end

    context 'debug_port' do
      context 'valid' do
        let :params do
          default_params.merge(:debug_port => 12_345)
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('debug_port' => 12_345) }
      end

      context 'NaN' do
        let :params do
          default_params.merge(:debug_port => 'NaN')
        end
        it { expect { is_expected.to compile }.to raise_error(/to be an Integer/) }
      end
    end

    context 'group' do
      context 'non default value' do
        let :params do
          default_params.merge(:group => 'notaemgroup')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('group' => 'notaemgroup') }
      end
    end

    context 'home' do

      context 'not absolute' do
        let :params do
          default_params.merge(:home => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'jvm_mem_opts' do

      context 'non default value' do
        let :params do
          default_params.merge(:jvm_mem_opts => '-Xmx1.21GW')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('jvm_mem_opts' => '-Xmx1.21GW') }
      end

    end

    context 'jvm_opts' do
      context 'non default value' do
        let :params do
          default_params.merge(:jvm_opts => '-Da.jvm.param=foobar')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('jvm_opts' => '-Da.jvm.param=foobar') }
      end

    end

    context 'manage_group' do
      context 'false' do
        let :params do
          default_params.merge(:manage_group => false)
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('manage_group' => false) }
        it { is_expected.not_to contain_group('aem') }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:manage_group => 'not boolean')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not a boolean/) }
      end
    end

    context 'manage_home' do
      context 'false' do
        let :params do
          default_params.merge(:manage_home => false)
        end

        context 'home does not exist' do
          # Why doesn't this work
          # it { expect { is_expected.to compile }.to raise_error(/Could not retrieve dependency/) }
        end
        context 'home exists' do
          let :pre_condition do
            'file { "/opt/aem" : ensure => "directory" }'
          end
          it { is_expected.to compile }
          it { is_expected.to contain_aem__instance('aem').with('manage_home' => false) }
        end
      end

      context 'invalid' do
        let :params do
          default_params.merge(:manage_home => 'not boolean')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not a boolean/) }
      end
    end

    context 'manage_user' do
      context 'false' do
        let :params do
          default_params.merge(:manage_user => false)
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('manage_user' => false) }
        it { is_expected.not_to contain_user('aem') }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:manage_user => 'not boolean')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not a boolean/) }
      end
    end

    context 'osgi_configs' do
      context 'not a map' do
        let :params do
          default_params.merge(:osgi_configs => 'not a map')
        end
        it { expect { is_expected.to compile }.to raise_error(/Hash or an Array of Hashes/) }
      end

      context 'hash' do
        let :params do
          default_params.merge(:osgi_configs => {
            'test' => {
              'key' => 'value'
            }
          })
        end
        it { is_expected.to compile }
      end

      context 'array of hashes' do
        let :params do
          default_params.merge(:osgi_configs => [
            {
              'testa' => {
                'key' => 'value'
              }
            },
            {
              'testb' => {
                'key1' => 'value2'
              }
            }
          ])
        end
        it { is_expected.to compile }
      end
    end

    context 'port' do
      context 'NaN' do
        let :params do
          default_params.merge(:port => 'NaN')
        end
        it { expect { is_expected.to compile }.to raise_error(/to be an Integer/) }
      end
    end

    context 'runmodes' do

      context 'valid' do
        let :params do
          default_params.merge(:runmodes => %w(arunmode anotherrunmode))
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('runmodes' => %w(arunmode anotherrunmode)) }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:runmodes => { 'a' => 'hash' })
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an Array/) }
      end
    end

    context 'sample_content' do
      context 'false' do
        let :params do
          default_params.merge(:sample_content => false)
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('sample_content' => false) }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:sample_content => 'not boolean')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not a boolean/) }
      end
    end

    context 'status' do
      context 'enabled' do
        let :params do
          default_params.merge(:status => 'enabled')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('status' => 'enabled') }
      end

      context 'disabled' do
        let :params do
          default_params.merge(:status => 'disabled')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('status' => 'disabled') }
      end

      context 'running' do
        let :params do
          default_params.merge(:status => 'running')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('status' => 'running') }
      end

      context 'unmanaged' do
        let :params do
          default_params.merge(:status => 'unmanaged')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('status' => 'unmanaged') }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:status => 'invalid')
        end
        it do 
          expect do 
            is_expected.to compile 
          end.to raise_error(/Allowed values are 'enabled', 'disabled', 'running' and 'unmanaged'/)
        end
      end
    end

    context 'snooze' do
      context 'NaN' do
        let :params do
          default_params.merge(:snooze => 'NaN')
        end
        it { expect { is_expected.to compile }.to raise_error(/to be an Integer/) }
      end
    end

    context 'source' do
      context 'valid value' do
        let :params do
          default_params.merge(:source => '/tmp/aem-quickstart.jar')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_aem__instance('aem').with('source' => '/tmp/aem-quickstart.jar') }
      end

      context 'not absolute' do
        let :params do
          default_params.merge(:source => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'timeout' do
      context 'NaN' do
        let :params do
          default_params.merge(:timeout => 'NaN')
        end
        it { expect { is_expected.to compile }.to raise_error(/to be an Integer/) }
      end
    end

    context 'type' do

      context 'publish' do
        let :params do
          default_params.merge(:type => 'publish')
        end
        it { is_expected.to compile }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:type => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for type/) }
      end

    end

    context 'version' do

      context 'major' do
        let :params do
          default_params.merge(:version => '1')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a valid version/) }
      end

      context 'major minor' do
        let :params do
          default_params.merge(:version => '1.2')
        end

        it { is_expected.to compile }
      end

      context 'major minor bug' do
        let :params do
          default_params.merge(:version => '1.2.3')
        end

        it { is_expected.to compile }
      end

      context 'major minor bug other' do
        let :params do
          default_params.merge(:version => '1.2.3.4')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a valid version/) }
      end
    end

  end
end
