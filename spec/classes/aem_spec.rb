require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem', type: :class do

  context 'default params not pe' do
    let(:facts) do
      {
        is_pe: false,
        puppetversion: '4.0.0'
      }
    end

    it do
      is_expected.to compile.with_all_deps
      is_expected.to contain_class('aem').only_with(
        crx_packmgr_api_client_ver: '1.1.0',
        name:                       'Aem',
        puppetgem:                  'puppet_gem',
        xmlsimple_ver:              '>=1.1.5'
      )
    end
  end

  context 'default params pe ver < 3.7.0' do
    let(:facts) do
      {
        is_pe: true,
        pe_version: '3.6.0'
      }
    end

    it do
      is_expected.to compile.with_all_deps
      is_expected.to contain_class('aem').only_with(
        crx_packmgr_api_client_ver: '1.1.0',
        name:                       'Aem',
        puppetgem:                  'pe_gem',
        xmlsimple_ver:              '>=1.1.5'
      )
    end
  end

  context 'default params pe > 3.7' do
    let(:facts) do
      {
        is_pe: true,
        pe_version: '3.7.0'
      }
    end

    it do
      is_expected.to compile.with_all_deps
      is_expected.to contain_class('aem').only_with(
        crx_packmgr_api_client_ver: '1.1.0',
        name:                       'Aem',
        puppetgem:                  'pe_puppetserver_gem',
        xmlsimple_ver:              '>=1.1.5'
      )
    end
  end

end
