require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem::dispatcher::farm', :type => :define do

  let :pre_condition do
    '
    class { "apache": default_vhost => false, default_mods => false, vhost_enable_dir => "/etc/apache2/sites-enabled"}
    class { aem::dispatcher : module_file => "/tmp/module.so" }
    '
  end

  let :default_params do 
    {
      :docroot => '/path/to/docroot'
    }
  end

  let :title do
    'aem-site'
  end

  describe 'RedHat' do

    context 'RedHat 6.x' do
      let :facts do
        {
          :osfamily               => 'RedHat',
          :operatingsystemrelease => '6.6.0',
          :operatingsystem        => 'CentOS',
          :concat_basedir         => '/dne',
          :id                     => 'root',
          :kernel                 => 'Linux',
          :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        }
      end

      describe 'ensure present' do
        let :params do
          default_params.merge(:ensure => 'present')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.d/dispatcher.aem-site.any'
          ).with(:ensure => 'present')
        end
        it do
          is_expected.to contain_file_line(
            'include aem-site.any'
          ).with(
            :path => '/etc/httpd/conf.d/dispatcher.farms.any'
          ).that_requires(
            'File[/etc/httpd/conf.d/dispatcher.farms.any]'
          )
        end
      end

      describe 'ensure absent' do
        let :params do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.d/dispatcher.aem-site.any'
          ).with(
            :ensure => 'absent'
          ).that_requires(
            'File_line[include aem-site.any]'
          )
        end
        it do
          is_expected.to contain_file_line(
            'include aem-site.any'
          ).with(
            :path => '/etc/httpd/conf.d/dispatcher.farms.any'
          ).that_requires(
            'File[/etc/httpd/conf.d/dispatcher.farms.any]'
          )
        end
      end
    end

    context 'RedHat 7.x' do
      let :facts do
        {
          :osfamily               => 'RedHat',
          :operatingsystemrelease => '7.0.0',
          :operatingsystem        => 'CentOS',
          :concat_basedir         => '/dne',
          :id                     => 'root',
          :kernel                 => 'Linux',
          :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        }
      end

      describe 'ensure present' do
        let :params do
          default_params.merge(:ensure => 'present')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with(
            :ensure => 'present'
          )
        end
        it do
          is_expected.to contain_file_line(
            'include aem-site.any'
          ).with(
            :path => '/etc/httpd/conf.modules.d/dispatcher.farms.any'
          ).that_requires(
            'File[/etc/httpd/conf.modules.d/dispatcher.farms.any]'
          )
        end
      end

      describe 'ensure absent' do
        let :params do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with(
            :ensure => 'absent'
          ).that_requires(
            'File_line[include aem-site.any]'
          )
        end
        it do
          is_expected.to contain_file_line(
            'include aem-site.any'
          ).with(
            :path => '/etc/httpd/conf.modules.d/dispatcher.farms.any'
          )
        end
      end
    end
  end

  context 'Debian' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '7.0.0',
        :operatingsystem        => 'Debian',
        :concat_basedir         => '/dne',
        :id                     => 'root',
        :kernel                 => 'Linux',
        :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      }
    end

    describe 'ensure present' do
      let :params do
        default_params.merge(:ensure => 'present')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/apache2/mods-enabled/dispatcher.aem-site.any'
        ).with(
          :ensure => 'present'
        )
      end
      it do
        is_expected.to contain_file_line(
          'include aem-site.any'
        ).with(
          :path => '/etc/apache2/mods-enabled/dispatcher.farms.any'
        ).that_requires(
          'File[/etc/apache2/mods-enabled/dispatcher.farms.any]'
        )
      end
    end

    describe 'ensure absent' do
      let :params do
        default_params.merge(:ensure => 'absent')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/apache2/mods-enabled/dispatcher.aem-site.any'
        ).with(
          :ensure => 'absent'
        ).that_requires(
          'File_line[include aem-site.any]'
        )
      end
      it do
        is_expected.to contain_file_line(
          'include aem-site.any'
        ).with(
          :path => '/etc/apache2/mods-enabled/dispatcher.farms.any'
        )
      end
    end
  end

  context 'Ubuntu' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '12.04',
        :operatingsystem        => 'Ubuntu',
        :concat_basedir         => '/dne',
        :id                     => 'root',
        :kernel                 => 'Linux',
        :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      }
    end

    describe 'ensure present' do
      let :params do
        default_params.merge(:ensure => 'present')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/apache2/mods-enabled/dispatcher.aem-site.any'
        ).with(
          :ensure => 'present'
        )
      end
      it do
        is_expected.to contain_file_line(
          'include aem-site.any'
        ).with(
          :path => '/etc/apache2/mods-enabled/dispatcher.farms.any'
        ).that_requires(
          'File[/etc/apache2/mods-enabled/dispatcher.farms.any]'
        )
      end
    end

    describe 'ensure absent' do
      let :params do
        default_params.merge(:ensure => 'absent')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/apache2/mods-enabled/dispatcher.aem-site.any'
        ).with(
          :ensure => 'absent'
        ).that_requires(
          'File_line[include aem-site.any]'
        )
      end
      it do
        is_expected.to contain_file_line(
          'include aem-site.any'
        ).with(
          :path => '/etc/apache2/mods-enabled/dispatcher.farms.any'
        )
      end
    end
  end

end
