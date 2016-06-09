require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::license', :type => :defines do

  let(:facts) do
    {
      :kernel => 'Linux'
    }
  end

  let(:title) do
    'aem'
  end

  let(:default_params) do
    {
      :customer    => 'adobe customer',
      :home        => '/opt/aem',
      :license_key => 'license-key-for-aem',
      :version     => '6.1.0'
    }
  end

  describe 'parameter validation' do

    context 'ensure' do

      context 'absent' do
        let(:params) do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_file('/opt/aem/license.properties').with('ensure' => 'absent') }
      end

      context 'invalid' do
        let(:params) do
          default_params.merge(:ensure => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'home' do

      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/Home directory must be specified./) }
      end

      context 'not absolute' do
        let(:params) do
          default_params.merge(:home => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'license' do

      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:license_key)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/License key must be specified./) }
      end

      context 'ensure absent but not specifed' do
        let(:params) do
          tmp = default_params.merge(:ensure => 'absent')
          tmp.delete(:license_key)
          tmp
        end
        it { is_expected.to compile }
      end
    end

  end

  describe 'creates the file' do

    let(:params) do
      default_params
    end

    context 'product name' do
      it do
        is_expected.to contain_file(
          '/opt/aem/license.properties'
        ).with_content(
          /license.product.name=Adobe Experience Manager\s/
        )
      end
    end

    context 'mode' do
      it { is_expected.to contain_file('/opt/aem/license.properties').with_mode('0664') }
    end

    context 'customer' do

      it do
        val = params[:customer]
        is_expected.to contain_file(
          '/opt/aem/license.properties'
        ).with_content(
          /license.customer.name=#{val}\s/
        )
      end
    end

    context 'group' do
      context 'default' do
        it { is_expected.to contain_file('/opt/aem/license.properties').with_group('aem') }
      end

      context 'specified group' do
        let(:params) do
          default_params.merge(:group => 'vagrant')
        end
        it { is_expected.to contain_file('/opt/aem/license.properties').with_group('vagrant') }
      end
    end

    context 'home' do
      it { is_expected.to contain_file('/opt/aem/license.properties') }
    end

    context 'license key' do

      it do
        val = params[:license_key]

        is_expected.to contain_file(
          '/opt/aem/license.properties'
        ).with_content(
          /license.downloadID=#{val}\s/
        )
      end
    end

    context 'user' do
      context 'default' do
        it { is_expected.to contain_file('/opt/aem/license.properties').with_owner('aem') }
      end

      context 'specified owner' do
        let(:params) do
          default_params.merge(:user => 'vagrant')
        end
        it { is_expected.to contain_file('/opt/aem/license.properties').with_owner('vagrant') }
      end
    end

    context 'version' do

      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:version)
          tmp
        end

        it do
          is_expected.to contain_file(
            '/opt/aem/license.properties'
          ).with_content(
            /license.product.version=\s/
          )
        end

      end

      context 'specified' do
        it do
          val = params[:version]

          is_expected.to contain_file(
            '/opt/aem/license.properties'
          ).with_content(
            /license.product.version=#{val}\s/
          )
        end

      end
    end

  end

  describe 'requires home directory' do
    let(:pre_condition) { 'file { "/opt/aem" : }' }

    let(:params) do
      default_params
    end

    context 'default' do
      it { is_expected.to contain_file('/opt/aem/license.properties').that_requires('File[/opt/aem]') }
    end

  end

end
