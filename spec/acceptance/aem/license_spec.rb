# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'create license file' do

  let(:license) do
    ENV['AEM_LICENSE'] || 'fake-key-for-testing'
  end

  it 'should have license file' do
    shell('test -f /opt/aem/author/license.properties', acceptable_exit_codes: 0)
  end

  it 'should have correct owner:group' do
    shell('stat -c "%U:%G" /opt/aem/author/license.properties') do |result|
      expect(result.stdout).to match('vagrant:vagrant')
    end
  end

  it 'should contain customer' do
    shell('grep "license.customer.name=puppet-testing" /opt/aem/author/license.properties',
          acceptable_exit_codes: 0)
  end

  it 'should contain licnese_key' do
    shell("grep -- \"license.downloadID=#{license}\" /opt/aem/author/license.properties",
          acceptable_exit_codes: 0)
  end

  it 'should contain version' do
    shell('grep "license.product.version=6.5.0" /opt/aem/author/license.properties',
          acceptable_exit_codes: 0)
  end
end
