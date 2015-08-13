require 'spec_helper'

describe 'aem', :type => :class do

  let :default_facts do
    {
      :kernel     => 'Linux'
    }
  end

  let :title do 'aem' end

  let :default_params do
    {
      :source => '/tmp/aem-quickstart.jar'
    }
  end

  context 'start env script options' do
    let :facts do default_facts end

    describe 'context root' do
      let :params do
        default_params.merge({
          :context_root => 'contextroot'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'context_root'          => 'contextroot',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with_content(/CONTEXT_ROOT='contextroot'/)
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/monitor'
        ).with_content(/uri_s = "\#{uri_s}contextroot\/"/)
      }
    end

    describe 'debug port' do
      let :params do
        default_params.merge({
          :debug_port => 12345
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'debug_port'            => 12345,
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with_content(/DEBUG_PORT=12345/)
      }
    end

    describe 'group' do
      let :params do
        default_params.merge({
          :debug_port => 12345
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with_content(/DEBUG_PORT=12345/)
      }
    end

    describe 'group' do
      let :params do
        default_params.merge({
          :group => 'notaem'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'notaem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }
    end

    describe 'home' do
      let :params do
        default_params.merge({
          :home => '/a/new/path/to/home'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'home'                  => '/a/new/path/to/home',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }
    end

    describe 'jvm_mem_opts' do
      let :params do
        default_params.merge({
          :jvm_mem_opts => '-XmxAllYourMemory'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-XmxAllYourMemory',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /JVM_MEM_OPTS='-XmxAllYourMemory'/
        )
      }
    end

    describe 'jvm_opts' do
      let :params do
        default_params.merge({
          :jvm_opts => 'Some Options'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'jvm_opts'              => 'Some Options',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /JVM_OPTS='Some Options'/
        )
      }
    end

    describe 'port' do
      let :params do
        default_params.merge({
          :port => 12345
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 12345,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /PORT=12345/
        )
      }
      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/monitor'
        ).with(
        'content' => /"http:\/\/localhost:12345\/"/
        )
      }
    end

    describe 'runmodes' do
      let :params do
        default_params.merge({
          :runmodes => ['test', 'runmodes']
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'runmodes'              => ['test', 'runmodes'],
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /RUNMODES='test,runmodes'/
        )
      }
    end

    describe 'sample content' do
      let :params do
        default_params.merge({
          :sample_content => false
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => false,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /SAMPLE_CONTENT='nosamplecontent'/
        )
      }
    end

    describe 'sample content' do
      let :params do
        default_params.merge({
          :sample_content => false
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => false,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /SAMPLE_CONTENT='nosamplecontent'/
        )
      }
    end

    describe 'snooze' do
      let :params do
        default_params.merge({
          :snooze => 30
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 30,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/monitor'
        ).with(
        'content' => /sleep 30/
        )
      }
    end

    describe 'timeout' do
      let :params do
        default_params.merge({
          :timeout => 1000
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 1000,
        'type'                  => 'author',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/monitor'
        ).with(
        'content' => /Timeout.timeout\(1000\)/
        )
      }
    end

    describe 'type' do
      let :params do
        default_params.merge({
          :type => 'publish'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'publish',
        'user'                  => 'aem'
        )
      }

      it { is_expected.to contain_file('/opt/aem/crx-quickstart/bin/start-env'
        ).with(
        'content' => /TYPE='publish'/
        )
      }
    end

    describe 'user' do
      let :params do
        default_params.merge({
          :user => 'notaem'
        })
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('aem').with(
        'ensure'                => 'present',
        'group'                 => 'aem',
        'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
        'manage_group'          => true,
        'manage_home'           => true,
        'manage_user'           => true,
        'port'                  => 4502,
        'sample_content'        => true,
        'snooze'                => 10,
        'timeout'               => 600,
        'type'                  => 'author',
        'user'                  => 'notaem'
        )
      }
    end

    describe 'version' do
      context 'major minor' do
        let :params do
          default_params.merge({
            :version => '1.2'
          })
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('aem').with(
          'ensure'                => 'present',
          'group'                 => 'aem',
          'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
          'manage_group'          => true,
          'manage_home'           => true,
          'manage_user'           => true,
          'port'                  => 4502,
          'sample_content'        => true,
          'snooze'                => 10,
          'timeout'               => 600,
          'type'                  => 'author',
          'user'                  => 'aem',
          'version'               => '1.2'
          )
        }
      end

      context 'major minor bug' do
        let :params do
          default_params.merge({
            :version => '1.2.3'
          })
        end

        it { is_expected.to compile }

        it { is_expected.to contain_class('aem').with(
          'ensure'                => 'present',
          'group'                 => 'aem',
          'jvm_mem_opts'          => '-Xmx1024m -XX:MaxPermSize=256M',
          'manage_group'          => true,
          'manage_home'           => true,
          'manage_user'           => true,
          'port'                  => 4502,
          'sample_content'        => true,
          'snooze'                => 10,
          'timeout'               => 600,
          'type'                  => 'author',
          'user'                  => 'aem',
          'version'               => '1.2.3'
          )
        }
      end

    end
  end
end