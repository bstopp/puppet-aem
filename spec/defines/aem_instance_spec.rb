require 'spec_helper'

# Tests for the resources created by the class.
describe 'aem::instance', :type => :defines do

  let :default_facts do
    {
      :kernel           => 'Linux',
      :operatingsystem  => 'CentOS',
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

  context 'default install' do

    let :params do
      default_params
    end
    let :facts do
      default_facts
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_user('aem').with(
        'ensure' => 'present',
        'gid' => 'aem'
      )
    end

    it { is_expected.to contain_group('aem').with('ensure' => 'present') }

    it { is_expected.to contain_anchor('aem::aem::begin') }

    it do
      is_expected.to contain_aem__package(
        'aem'
      ).with(
        'ensure'        => 'present',
        'group'         => 'aem',
        'home'          => '/opt/aem',
        'manage_home'   => true,
        'source'        => '/tmp/aem-quickstart.jar',
        'user'          => 'aem'
      )
    end

    it do
      is_expected.to contain_aem__service('aem').with(
        'ensure' => 'present',
        'status' => 'enabled',
        'home'   => '/opt/aem',
        'user'   => 'aem',
        'group'  => 'aem'
      )
    end

    it do
      is_expected.to contain_aem__config(
        'aem'
      ).with(
        'context_root'    => nil,
        'debug_port'      => nil,
        'group'           => 'aem',
        'home'            => '/opt/aem',
        'jvm_mem_opts'    => '-Xmx1024m -XX:MaxPermSize=256M',
        'jvm_opts'        => nil,
        'port'            => 4502,
        'runmodes'        => [],
        'sample_content'  => true,
        'type'            => 'author',
        'user'            => 'aem'
      )
    end

    it do
      is_expected.to contain_aem_installer(
        'aem'
      ).with(
        'ensure'        => 'present',
        'context_root'  => nil,
        'group'         => 'aem',
        'home'          => '/opt/aem',
        'port'          => 4502,
        'snooze'        => 10,
        'timeout'       => 600,
        'user'          => 'aem'
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


    it do
      is_expected.to contain_file(
        '/opt/aem'
      ).with(
        'ensure'  => 'directory',
        'group'   => 'aem',
        'owner'   => 'aem'
      )
    end

    it do
      is_expected.to contain_exec(
        'aem unpack'
      ).with(
        'command'     => 'java -jar /tmp/aem-quickstart.jar -b /opt/aem -unpack',
        'creates'     => '/opt/aem/crx-quickstart',
        'group'       => 'aem',
        'onlyif'      => ['which java', 'test -f /tmp/aem-quickstart.jar'],
        'user'        => 'aem'
      )
    end

    it { is_expected.to contain_exec('aem unpack').that_requires('File[/opt/aem]') }

    it do
      is_expected.to contain_file(
        '/opt/aem/crx-quickstart/bin/start-env'
      ).with(
        'ensure'      => 'file',
        'content'     => /.*/,
        'group'       => 'aem',
        'owner'       => 'aem'
      )
    end

    it do
      is_expected.to contain_file(
        '/opt/aem/crx-quickstart/bin/start.orig'
      ).with(
        'ensure'      => 'file',
        'group'       => 'aem',
        'source'      => '/opt/aem/crx-quickstart/bin/start',
        'owner'       => 'aem'
      )
    end

    it do
      is_expected.to contain_file(
        '/opt/aem/crx-quickstart/bin/start'
      ).with(
        'ensure'      => 'file',
        'content'     => /.*/,
        'group'       => 'aem',
        'owner'       => 'aem'
      ).that_requires(
        'File[/opt/aem/crx-quickstart/bin/start.orig]'
      )
    end

  end

  describe 'osgi configs' do

    context 'single definition' do
      let :params do
        default_params.merge({
          :osgi_configs => {
            'osgi.name' => {
              'key' => 'value',
              'key2' => 'value2',
            }
          }
        })
      end

      let :facts do
        default_facts
      end

      it { is_expected.to compile.with_all_deps }
      it do
        is_expected.to contain_file(
          '/opt/aem/install/osgi.name.config'
        ).with(
          'ensure'    => 'file',
          'content'   => /key=\"value\"\nkey2=\"value2\"/,
          'group'     => 'aem',
          'owner'     => 'aem'
        )
      end

    end

    context 'multiple definitions' do
      let :params do
        default_params.merge({
          :osgi_configs => [
            {
              'osgi.name' => {
                'key' => 'value',
                'key2' => 'value2',
              }
            },
            {
              'osgi2.name' => {
                'key3' => 'value3',
                'key4' => 'value4',
              }
            }
          ]
        })
      end

      let :facts do
        default_facts
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_file(
          '/opt/aem/install/osgi.name.config'
        ).with(
          'ensure'    => 'file',
          'content'   => /key=\"value\"\nkey2=\"value2\"/,
          'group'     => 'aem',
          'owner'     => 'aem'
        )
      end
      it do
        is_expected.to contain_file(
          '/opt/aem/install/osgi2.name.config'
        ).with(
          'ensure'    => 'file',
          'content'   => /key3=\"value3\"\nkey4=\"value4\"/,
          'group'     => 'aem',
          'owner'     => 'aem'
        )
      end

    end

    context 'property types' do
      let :params do
        default_params.merge({
          :osgi_configs => {
            'osgi.name' => {
              'booltrue'  => true,
              'boolfalse' => false,
              'int'       => 12345,
            }
          }
        })
      end

      let :facts do
        default_facts
      end

      it { is_expected.to compile.with_all_deps }
      it do
        is_expected.to contain_file(
          '/opt/aem/install/osgi.name.config'
        ).with(
          'ensure'    => 'file',
          'content'   => /booltrue=B"true"\sboolfalse=B"false"\sint=L"12345"/,
          'group'     => 'aem',
          'owner'     => 'aem'
        )
      end

    end
  end

  context 'default remove' do

    let :params do
      default_params.merge(:ensure => 'absent')
    end
    let :facts do
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
