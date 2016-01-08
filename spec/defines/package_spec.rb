require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::package', :type => :defines do

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
      :ensure      => 'present',
      :group       => 'aem',
      :home        => '/opt/aem',
      :manage_home => true,
      :source      => '/tmp/aem-quickstart.jar',
      :user        => 'aem'
    }
  end

  describe 'ensure present' do
    let :facts do
      default_facts
    end
    let :params do
      default_params
    end

    it { is_expected.to compile.with_all_deps }

    context 'manage_home == true' do

      context 'not defined already' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            '/opt/aem'
          ).with(
            :ensure => 'directory',
            :group  => 'aem',
            :owner  => 'aem',
            :mode   => '0775'
          )
        end

        it { is_expected.to contain_exec('aem unpack').that_requires('File[/opt/aem]') }
      end

      context 'already defined' do
        let(:pre_condition) { 'file { "/opt/aem" : }' }

        it { is_expected.to contain_exec('aem unpack').that_requires('File[/opt/aem]') }

      end
    end

    context 'manage_home == false' do

      let :params do
        default_params.merge(:manage_home => false)
      end

      it { is_expected.to_not contain_file('/opt/aem') }
      it { is_expected.to_not contain_exec('aem unpack').that_requires('File[/opt/aem]') }
    end

    context 'unpack' do

      it do
        is_expected.to contain_exec(
          'aem unpack'
        ).with(
          :command => 'java -jar /tmp/aem-quickstart.jar -b /opt/aem -unpack',
          :creates => '/opt/aem/crx-quickstart',
          :group   => 'aem',
          :onlyif  => ['which java', 'test -f /tmp/aem-quickstart.jar'],
          :user    => 'aem'
        )
      end
    end
  end

  describe 'ensure absent' do
    let :facts do
      default_facts
    end
    let :params do
      default_params.merge(:ensure => 'absent')
    end

    it { is_expected.to compile.with_all_deps }

    context 'install folder' do

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart'
        ).with(
          :ensure => 'absent',
          :force => true
        )
      end
    end

    context 'home directory' do
      context 'manage_home == true' do

        context 'home not defined' do
          it { is_expected.to contain_file('/opt/aem').with(:ensure => 'absent', :force => true) }
          it { is_expected.to contain_file('/opt/aem').that_requires('File[/opt/aem/crx-quickstart]') }
        end

        context 'home already defined' do
          let(:pre_condition) { 'file { "/opt/aem" : }' }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/opt/aem').that_requires('File[/opt/aem/crx-quickstart]') }
        end
      end

      context 'manage_home == false' do
        let :params do
          default_params.merge(:manage_home => false)
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_file('/opt/aem') }
        it { is_expected.to_not contain_exec('aem unpack').that_requires('File[/opt/aem]') }
      end
    end

  end
end
