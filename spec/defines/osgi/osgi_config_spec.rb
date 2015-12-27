require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::osgi::config', :type => :defines do

  let :facts do
    {
      :kernel => 'Linux'
    }
  end

  let :title do
    'aem'
  end

  let :default_params do
    {
      :home       => '/opt/aem',
      :properties => {
        'boolean' => false,
        'long'    => 123456789,
        'string'  => 'string',
        'array'   => ['an', 'array', 'of', 'values']
      }
    }
  end

  describe 'parameter validation' do

    context 'ensure' do

      context 'absent' do
        let :params do
          default_params.merge(:ensure => 'absent', :type => 'file')
        end
        it { is_expected.to compile }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:ensure => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'home' do

      context 'not specified' do
        let :params do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

      context 'not absolute' do
        let :params do
          default_params.merge(:home => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'properties' do
      context 'not specifed' do
        let :params do
          tmp = default_params.clone
          tmp.delete(:properties)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/must contain at least one entry/) }
      end

      context 'not a hash' do
        let :params do
          default_params.merge(:properties => ['this', 'is', 'not', 'a', 'hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/must be a Hash of values/) }
      end
    end
  end


  describe 'defines resource based on type' do

    context 'file type' do
      let :params do
        default_params.merge(:type => 'file')
      end

      context 'default params' do
        it do
          is_expected.to contain_aem__osgi__config__file(
            'aem'
          ).with(
            'ensure'     => 'present',
            'group'      => 'aem',
            'home'       => '/opt/aem',
            'properties' => params[:properties],
            'user'       => 'aem'
          )
        end
      end

      context 'ensure absent' do
        let :params do
          default_params.merge(:ensure => 'absent', :type => 'file')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with('ensure' => 'absent') }
      end

    end

    context 'invalid type' do
      let :params do
        default_params.merge(:type => 'invalid')

        it { is_expected.to raise_error(/not supported for type/) }
      end
    end
  end

end
