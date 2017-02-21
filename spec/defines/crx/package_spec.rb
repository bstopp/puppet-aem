require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::crx::package', type: :defines do

  let(:facts) do
    {
      kernel: 'Linux',
      osfamily: 'RedHat',
      operatingsystemmajrelease: '7',
      is_pe: false
    }
  end

  let(:title) do
    'aem'
  end

  let(:default_params) do
    {
      home: '/opt/aem',
      source: '/path/to/file.zip',
      username: 'admin',
      password: 'admin'
    }
  end

  describe 'parameter validation' do
    context 'ensure' do
      context 'present' do
        let(:params) do
          default_params.merge(type: 'file')
        end
        it { is_expected.to compile }
      end

      context 'absent' do
        let(:params) do
          default_params.merge(ensure: 'absent', type: 'file')
        end
        it { is_expected.to compile }
      end

      context 'installed' do
        let(:params) do
          default_params.merge(ensure: 'installed', type: 'file')
        end
        it { is_expected.to compile }
      end

      context 'purged' do
        let(:params) do
          default_params.merge(ensure: 'purged', type: 'file')
        end
        it { is_expected.to compile }
      end

      context 'installed' do
        let(:params) do
          default_params.merge(ensure: 'invalid', type: 'file')
        end
        it { is_expected.to raise_error(/not supported for ensure/) }
      end
    end

    context 'type' do
      context 'api' do
        let(:params) do
          default_params.merge(type: 'api', pkg_group: 'my_packages', pkg_name: 'test', pkg_version: '1')
        end
        it { is_expected.to compile }
      end
      context 'file' do
        let(:params) do
          default_params.merge(type: 'file')
        end
        it { is_expected.to compile }
      end
      context 'invalid' do
        let(:params) do
          default_params.merge(type: 'invalid')
        end
        it { expect { is_expected.to compile }.to raise_error(/not supported for type/) }
      end
    end

    context 'home' do

      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp.merge(type: 'file')
        end
        it { is_expected.to raise_error(/is not an absolute path/) }
      end

      context 'not absolute' do
        let(:params) do
          default_params.merge(home: 'not/absolute/path', type: 'file')
        end
        it { is_expected.to raise_error(/is not an absolute path/) }
      end

    end

    context 'type = api' do
      context 'username' do
        context 'should be required' do
          let(:params) do
            params = default_params.merge(type: 'api')
            params.delete(:username)
            params
          end
          it { is_expected.to raise_error(/username is required/i) }
        end
      end
      context 'password' do
        context 'should be required' do
          let(:params) do
            params = default_params.merge(type: 'api')
            params.delete(:password)
            params
          end
          it { is_expected.to raise_error(/password is required/i) }
        end
      end
      context 'package group' do
        context 'should be required' do
          let(:params) do
            default_params.merge(type: 'api')
          end
          it { is_expected.to raise_error(/package group is required/i) }
        end
      end

      context 'package name' do
        context 'should be required' do
          let(:params) do
            default_params.merge(type: 'api', pkg_group: 'my_packages')
          end
          it { is_expected.to raise_error(/package name is required/i) }
        end
      end

      context 'package version' do
        context 'should be required' do
          let(:params) do
            default_params.merge(type: 'api', pkg_group: 'my_packages', pkg_name: 'test')
          end
          it { is_expected.to raise_error(/package version is required/i) }
        end
      end

      context 'source' do

        context 'not specified' do
          let(:params) do
            tmp = default_params.clone
            tmp.delete(:source)
            tmp.merge(type: 'api')
          end
          it { is_expected.to raise_error(/is not an absolute path/) }
        end

        context 'not absolute' do
          let(:params) do
            default_params.merge(source: 'not/absolute/path', type: 'api')
          end
          it { is_expected.to raise_error(/is not an absolute path/) }
        end

        context 'purged allows unspecified' do
          let(:params) do
            tmp = default_params.clone
            tmp.delete(:source)
            tmp.merge(type: 'api', ensure: 'purged', pkg_group: 'my_packages', pkg_name: 'test', pkg_version: '1.0.0')
          end
          it { is_expected.to compile }
        end

        context 'absent allows unspecified' do
          let(:params) do
            tmp = default_params.clone
            tmp.delete(:source)
            tmp.merge(type: 'api', ensure: 'purged', pkg_group: 'my_packages', pkg_name: 'test', pkg_version: '1.0.0')
          end
          it { is_expected.to compile }
        end
      end
    end

    context 'type == file' do
      context 'package file' do
        context 'should be required' do
          let(:params) do
            params = default_params.merge(type: 'file')
            params.delete(:source)
            params
          end
          it { is_expected.to raise_error(/is not an absolute path/i) }
        end
      end
    end

  end

  describe 'defines resources based on type' do
    context 'type == file' do
      context 'ensure present' do
        let(:params) do
          default_params.merge(type: 'file')
        end

        it do
          is_expected.to contain_aem__crx__package__file(
            'aem'
          ).only_with(
            ensure: 'present',
            group:  'aem',
            home:   '/opt/aem',
            name:   'aem',
            source: '/path/to/file.zip',
            user:   'aem'
          )
        end
      end

      context 'ensure installed' do
        let(:params) do
          default_params.merge(ensure: 'installed', type: 'file')
        end

        it do
          is_expected.to contain_aem__crx__package__file(
            'aem'
          ).only_with(
            ensure: 'present',
            group:  'aem',
            home:   '/opt/aem',
            name:   'aem',
            source: '/path/to/file.zip',
            user:   'aem'
          )
        end
      end

      context 'ensure absent' do
        let(:params) do
          default_params.merge(ensure: 'absent', type: 'file')
        end

        it do
          is_expected.to contain_aem__crx__package__file(
            'aem'
          ).only_with(
            ensure: 'absent',
            group:  'aem',
            home:   '/opt/aem',
            name:   'aem',
            source: '/path/to/file.zip',
            user:   'aem'
          )
        end
      end

      context 'ensure purged' do
        let(:params) do
          default_params.merge(ensure: 'purged', type: 'file')
        end

        it do
          is_expected.to contain_aem__crx__package__file(
            'aem'
          ).only_with(
            ensure: 'absent',
            group:  'aem',
            home:   '/opt/aem',
            name:   'aem',
            source: '/path/to/file.zip',
            user:   'aem'
          )
        end
      end

      context 'passes parameters' do
        let(:params) do
          default_params.merge(
            group: 'vagrant',
            home:  '/opt/aem/author',
            type:  'file',
            user:  'vagrant'
          )
        end
        it do
          is_expected.to contain_aem__crx__package__file(
            'aem'
          ).only_with(
            ensure: 'present',
            group:  'vagrant',
            home:   '/opt/aem/author',
            name:   'aem',
            source: '/path/to/file.zip',
            user:   'vagrant'
          )
        end
      end
    end

    context 'type == api' do
      context 'ensure present' do
        let(:params) do
          default_params.merge(
            password:    'admin',
            pkg_group:   'my_packages',
            pkg_name:    'test',
            pkg_version: '1.0.0',
            type:        'api',
            username:    'admin'
          )
        end

        it do
          is_expected.to compile.with_all_deps

          is_expected.to contain_package('crx_packmgr_api_client').with(
            ensure:   '1.2.0',
            name:     'crx_packmgr_api_client',
            provider: 'puppet_gem'
          ).that_requires('Class[ruby::dev]')

          is_expected.to contain_package('xml-simple').with(
            ensure:   '>=1.1.5',
            name:     'xml-simple',
            provider: 'puppet_gem'
          ).that_requires('Class[ruby::dev]')

          is_expected.to contain_aem_crx_package(
            'aem'
          ).only_with(
            ensure:   'present',
            group:    'my_packages',
            home:     '/opt/aem',
            name:     'aem',
            password: 'admin',
            pkg:      'test',
            source:   '/path/to/file.zip',
            username: 'admin',
            version:  '1.0.0'
          ).that_requires('Package[crx_packmgr_api_client]')
        end
      end

      context 'ensure absent' do
        let(:params) do
          params = default_params.merge(
            ensure:      'absent',
            password:    'admin',
            pkg_group:   'my_packages',
            pkg_name:    'test',
            pkg_version: '1.0.0',
            type:        'api',
            username:    'admin'
          )
          params.delete(:source)
          params
        end

        it do
          is_expected.to compile.with_all_deps

          is_expected.to contain_package('crx_packmgr_api_client').with(
            ensure:   '1.2.0',
            name:     'crx_packmgr_api_client',
            provider: 'puppet_gem'
          ).that_requires('Class[ruby::dev]')

          is_expected.to contain_package('xml-simple').with(
            ensure:   '>=1.1.5',
            name:     'xml-simple',
            provider: 'puppet_gem'
          ).that_requires('Class[ruby::dev]')

          is_expected.to contain_aem_crx_package(
            'aem'
          ).only_with(
            ensure:   'absent',
            group:    'my_packages',
            home:     '/opt/aem',
            name:     'aem',
            password: 'admin',
            pkg:      'test',
            username: 'admin',
            version:  '1.0.0'
          ).that_requires('Package[crx_packmgr_api_client]')
        end
      end

      context 'ensure installed' do
        let(:params) do
          default_params.merge(
            ensure:      'installed',
            password:    'admin',
            pkg_group:   'my_packages',
            pkg_name:    'test',
            pkg_version: '1.0.0',
            type:        'api',
            username:    'admin'
          )
        end

        it do
          is_expected.to compile.with_all_deps

          is_expected.to contain_package('crx_packmgr_api_client').with(
            ensure:   '1.2.0',
            name:     'crx_packmgr_api_client',
            provider: 'puppet_gem'
          ).that_requires('Class[ruby::dev]')

          is_expected.to contain_package('xml-simple').with(
            ensure:   '>=1.1.5',
            name:     'xml-simple',
            provider: 'puppet_gem'
          ).that_requires('Class[ruby::dev]')

          is_expected.to contain_aem_crx_package(
            'aem'
          ).only_with(
            ensure:   'installed',
            group:    'my_packages',
            home:     '/opt/aem',
            name:     'aem',
            password: 'admin',
            pkg:      'test',
            source:   '/path/to/file.zip',
            username: 'admin',
            version:  '1.0.0'
          ).that_requires('Package[crx_packmgr_api_client]')
        end
      end

      context 'multiple defined' do
        let(:params) do
          default_params.merge(
            ensure:      'installed',
            password:    'admin',
            pkg_group:   'my_packages',
            pkg_name:    'test',
            pkg_version: '1.0.0',
            type:        'api',
            username:    'admin'
          )
        end
        let(:pre_condition) do
          'aem::crx::package { "existing" :
            ensure      => installed,
            home        => "/opt/aem",
            password    => "admin",
            pkg_group   => "my_packages",
            pkg_name    => "otherpackage",
            pkg_version => "1.0.0",
            source      => "/path/to/other.zip",
            type        => "api",
            username    => "admin"
          }'
        end
        it 'should work' do
          is_expected.to compile.with_all_deps
        end
      end

      context 'multiple same packages different targets' do
        let(:params) do
          default_params.merge(
            ensure:      'installed',
            password:    'admin',
            pkg_group:   'my_packages',
            pkg_name:    'test',
            pkg_version: '1.0.0',
            type:        'api',
            username:    'admin'
          )
        end
        let(:pre_condition) do
          'aem::crx::package { "existing" :
            ensure      => installed,
            home        =>"/opt/aem/other",
            password    => "admin",
            pkg_group   => "my_packages",
            pkg_name    => "test",
            pkg_version => "1.0.0",
            source      => "/path/to/file.zip",
            type        => "api",
            username    => "admin"
          }'
        end
        it 'should work' do
          is_expected.to compile.with_all_deps
        end
      end
    end
  end
end
