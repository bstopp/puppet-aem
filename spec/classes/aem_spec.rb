# frozen_string_literal: true

require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem' do

  context 'default params' do
    let(:facts) do
      {
        is_pe: false,
        puppetversion: '4.0.0'
      }
    end

    let(:crx_client_ver) { '1.3.0' }

    it do
      is_expected.to compile.with_all_deps
      is_expected.to contain_class('aem').only_with(
        crx_packmgr_api_client_ver: crx_client_ver,
        name: 'Aem',
        puppetgem: 'puppet_gem',
        xmlsimple_ver: '>=1.1.5'
      )
    end
  end

end
