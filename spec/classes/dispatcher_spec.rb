require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem::dispatcher', type: :class do

  let(:pre_condition) do
    'class { "apache" :
      default_vhost => false,
      default_mods => false,
      vhost_enable_dir => "/etc/apache2/sites-enabled"
    }'
  end

  let(:default_params) do
    {
      module_file: '/tmp/dispatcher-apache2.X-4.1.X.so'
    }
  end

  let(:default_facts) do
    {
      osfamily: 'RedHat',
      operatingsystemrelease: '7.1.1503',
      operatingsystem: 'CentOS',
      concat_basedir: '/dne',
      id: 'root',
      kernel: 'Linux',
      path: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    }
  end

  context 'default parameters' do
    let(:facts) { default_facts }
    let(:params) { default_params }

    it { is_expected.to compile.with_all_deps }
    it do
      is_expected.to contain_class('aem::dispatcher').only_with(
        'name'              => 'Aem::Dispatcher',
        'ensure'            => 'present',
        'decline_root'      => 'off',
        'group'             => 'root',
        'log_file'          => '/var/log/httpd/dispatcher.log',
        'log_level'         => 'warn',
        'module_file'       => '/tmp/dispatcher-apache2.X-4.1.X.so',
        'pass_error'        => '0',
        'use_processed_url' => 'off',
        'user'              => 'root'
      )
    end

    it do
      is_expected.to contain_file('/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so').with(
        'ensure'  => 'file',
        'path'    => '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so',
        'group'   => 'root',
        'owner'   => 'root',
        'replace' => 'true',
        'source'  => '/tmp/dispatcher-apache2.X-4.1.X.so'
      )
    end

    it do
      is_expected.to contain_file('/etc/httpd/modules/mod_dispatcher.so').with(
        'ensure'  => 'link',
        'path'    => '/etc/httpd/modules/mod_dispatcher.so',
        'group'   => 'root',
        'owner'   => 'root',
        'replace' => 'true',
        'target'  => '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so'
      )
    end

    it do
      is_expected.to contain_file('/etc/httpd/conf.modules.d/dispatcher.conf').with(
        'ensure'  => 'file',
        'path'    => '/etc/httpd/conf.modules.d/dispatcher.conf',
        'group'   => 'root',
        'owner'   => 'root',
        'replace' => 'true'
      ).with_content(
        %r|.*DispatcherConfig\s*/etc/httpd/conf.modules.d/dispatcher.farms.any|
      ).with_content(
        %r|.*DispatcherLog\s*/var/log/httpd/dispatcher.log|
      ).with_content(
        /.*DispatcherLogLevel\s*warn/
      ).with_content(
        /.*DispatcherDeclineRoot\s*off/
      ).with_content(
        /.*DispatcherUseProcessedURL\s*off/
      ).with_content(
        /.*DispatcherPassError\s*0/
      )
    end

    it { is_expected.to contain_anchor('aem::dispatcher::begin') }
    it { is_expected.to contain_anchor('aem::dispatcher::end') }

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so'
      ).that_requires(
        'Anchor[aem::dispatcher::begin]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/mod_dispatcher.so'
      ).that_requires(
        'File[/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so]'
      )
    end

    it do
      is_expected.to contain_apache__mod(
        'dispatcher'
      ).that_requires(
        'File[/etc/httpd/modules/mod_dispatcher.so]'
      )
    end
    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.farms.any'
      ).that_requires(
        'Apache::Mod[dispatcher]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.conf'
      ).that_requires(
        'File[/etc/httpd/conf.modules.d/dispatcher.farms.any]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.conf'
      ).that_notifies(
        'Service[httpd]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.farms.any'
      ).that_notifies(
        'Service[httpd]'
      )
    end

  end

  describe 'parameter validation' do
    let(:facts) { default_facts }

    context 'ensure' do
      context 'should accept present' do
        let(:params) do
          default_params.merge(ensure: 'present')
        end
        it { is_expected.to compile.with_all_deps }
      end

      context 'should accept absent' do
        let(:params) do
          default_params.merge(ensure: 'absent')
        end
        it { is_expected.to compile.with_all_deps }
      end

      context 'should not accept any other value' do
        let(:params) do
          default_params.merge(ensure: 'invalid')
        end
        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end

    end

    context 'decline_root' do
      context 'numeric' do
        context 'should accept 0' do
          let(:params) do
            default_params.merge(decline_root: '0')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept 1' do
          let(:params) do
            default_params.merge(decline_root: '1')
          end
          it { is_expected.to compile.with_all_deps }
        end

        context 'should not accept any other positive value' do
          let(:params) do
            default_params.merge(decline_root: '2')
          end
          it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
        end
        context 'should not accept any negative value' do
          let(:params) do
            default_params.merge(decline_root: '-1')
          end
          it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
        end
      end

      context 'on/off' do
        context 'should accept on' do
          let(:params) do
            default_params.merge(decline_root: 'on')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept off' do
          let(:params) do
            default_params.merge(decline_root: 'off')
          end
          it { is_expected.to compile.with_all_deps }
        end

        context 'should not accept any other value' do
          let(:params) do
            default_params.merge(decline_root: 'invalid')
          end
          it { expect { is_expected.to compile }.to raise_error(/not supported for decline_root/) }
        end
      end
    end

    context 'log_level' do
      context 'numeric' do
        context 'should accept 0' do
          let(:params) do
            default_params.merge(log_level: '0')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept 1' do
          let(:params) do
            default_params.merge(log_level: '1')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept 2' do
          let(:params) do
            default_params.merge(log_level: '2')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept 3' do
          let(:params) do
            default_params.merge(log_level: '3')
          end
          it { is_expected.to compile.with_all_deps }
        end

        context 'should not accept any other positive value' do
          let(:params) do
            default_params.merge(log_level: '4')
          end
          it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
        end
        context 'should not accept any negative value' do
          let(:params) do
            default_params.merge(log_level: '-1')
          end
          it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
        end
      end

      context 'named values' do
        context 'should accept error' do
          let(:params) do
            default_params.merge(log_level: 'error')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept warn' do
          let(:params) do
            default_params.merge(log_level: 'warn')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept info' do
          let(:params) do
            default_params.merge(log_level: 'info')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept debug' do
          let(:params) do
            default_params.merge(log_level: 'debug')
          end
          it { is_expected.to compile.with_all_deps }
        end

        context 'should not accept any other value' do
          let(:params) do
            default_params.merge(log_level: 'invalid')
          end
          it { expect { is_expected.to compile }.to raise_error(/not supported for log_level/) }
        end
      end
    end

    context 'use_processed_url' do
      context 'numeric' do
        context 'should accept 0' do
          let(:params) do
            default_params.merge(use_processed_url: '0')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept 1' do
          let(:params) do
            default_params.merge(use_processed_url: '1')
          end
          it { is_expected.to compile.with_all_deps }
        end

        context 'should not accept any other positive value' do
          let(:params) do
            default_params.merge(use_processed_url: '2')
          end
          it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
        end
        context 'should not accept any negative value' do
          let(:params) do
            default_params.merge(use_processed_url: '-1')
          end
          it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
        end
      end

      context 'on/off' do
        context 'should accept on' do
          let(:params) do
            default_params.merge(use_processed_url: 'on')
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept off' do
          let(:params) do
            default_params.merge(use_processed_url: 'off')
          end
          it { is_expected.to compile.with_all_deps }
        end

        context 'should not accept any other value' do
          let(:params) do
            default_params.merge(use_processed_url: 'invalid')
          end
          it { expect { is_expected.to compile }.to raise_error(/not supported for use_processed_url/) }
        end
      end
    end
  end

  context 'apache not managed' do
    let(:facts) { default_facts }
    let(:params) do
      default_params.merge(ensure: 'present')
    end
    let(:pre_condition) do
      'class { "apache" :
        default_vhost    => false,
        default_mods     => false,
        service_manage   => false,
        vhost_enable_dir => "/etc/apache2/sites-enabled"
      }'
    end

    it { is_expected.to compile.with_all_deps }
    it do
      is_expected.to contain_class('aem::dispatcher').only_with(
        'name'              => 'Aem::Dispatcher',
        'ensure'            => 'present',
        'decline_root'      => 'off',
        'group'             => 'root',
        'log_file'          => '/var/log/httpd/dispatcher.log',
        'log_level'         => 'warn',
        'module_file'       => '/tmp/dispatcher-apache2.X-4.1.X.so',
        'pass_error'        => '0',
        'use_processed_url' => 'off',
        'user'              => 'root'
      )
    end

    it do
      is_expected.to contain_file('/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so').with(
        'ensure'  => 'file',
        'path'    => '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so',
        'group'   => 'root',
        'owner'   => 'root',
        'replace' => 'true',
        'source'  => '/tmp/dispatcher-apache2.X-4.1.X.so'
      )
    end

    it do
      is_expected.to contain_file('/etc/httpd/modules/mod_dispatcher.so').with(
        'ensure'  => 'link',
        'path'    => '/etc/httpd/modules/mod_dispatcher.so',
        'group'   => 'root',
        'owner'   => 'root',
        'replace' => 'true',
        'target'  => '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so'
      )
    end

    it do
      is_expected.to contain_file('/etc/httpd/conf.modules.d/dispatcher.conf').with(
        'ensure'  => 'file',
        'path'    => '/etc/httpd/conf.modules.d/dispatcher.conf',
        'group'   => 'root',
        'owner'   => 'root',
        'replace' => 'true'
      ).with_content(
        %r|.*DispatcherConfig\s*/etc/httpd/conf.modules.d/dispatcher.farms.any|
      ).with_content(
        %r|.*DispatcherLog\s*/var/log/httpd/dispatcher.log|
      ).with_content(
        /.*DispatcherLogLevel\s*warn/
      ).with_content(
        /.*DispatcherDeclineRoot\s*off/
      ).with_content(
        /.*DispatcherUseProcessedURL\s*off/
      ).with_content(
        /.*DispatcherPassError\s*0/
      )
    end

    it { is_expected.to contain_anchor('aem::dispatcher::begin') }
    it { is_expected.to contain_anchor('aem::dispatcher::end') }

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so'
      ).that_requires(
        'Anchor[aem::dispatcher::begin]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/mod_dispatcher.so'
      ).that_requires(
        'File[/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so]'
      )
    end

    it do
      is_expected.to contain_apache__mod(
        'dispatcher'
      ).that_requires(
        'File[/etc/httpd/modules/mod_dispatcher.so]'
      )
    end
    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.farms.any'
      ).that_requires(
        'Apache::Mod[dispatcher]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.conf'
      ).that_requires(
        'File[/etc/httpd/conf.modules.d/dispatcher.farms.any]'
      )
    end
  end

  context 'ensure absent' do
    let(:facts) { default_facts }
    let(:params) do
      default_params.merge(ensure: 'absent')
    end

    it { is_expected.to compile.with_all_deps }
    it do
      is_expected.to contain_class('aem::dispatcher').only_with(
        'name'              => 'Aem::Dispatcher',
        'ensure'            => 'absent',
        'decline_root'      => 'off',
        'group'             => 'root',
        'log_file'          => '/var/log/httpd/dispatcher.log',
        'log_level'         => 'warn',
        'module_file'       => '/tmp/dispatcher-apache2.X-4.1.X.so',
        'pass_error'        => '0',
        'use_processed_url' => 'off',
        'user'              => 'root'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so'
      ).with(
        'ensure' => 'absent'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/mod_dispatcher.so'
      ).with(
        'ensure' => 'absent'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.conf'
      ).with(
        'ensure' => 'absent'
      )
    end

    it { is_expected.to contain_anchor('aem::dispatcher::begin') }
    it { is_expected.to contain_anchor('aem::dispatcher::end') }

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.conf'
      ).that_requires(
        'Anchor[aem::dispatcher::begin]'
      )
    end
    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.farms.any'
      ).that_requires(
        'File[/etc/httpd/conf.modules.d/dispatcher.conf]'
      )
    end
    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/dispatcher-apache2.X-4.1.X.so'
      ).that_requires(
        'File[/etc/httpd/conf.modules.d/dispatcher.farms.any]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/modules/mod_dispatcher.so'
      ).that_requires(
        'File[/etc/httpd/conf.modules.d/dispatcher.conf]'
      )
    end

    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.farms.any'
      ).that_notifies(
        'Service[httpd]'
      )
    end
    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.conf'
      ).that_notifies(
        'Service[httpd]'
      )
    end
  end
end
