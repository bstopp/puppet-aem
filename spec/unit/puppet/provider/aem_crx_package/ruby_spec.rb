require 'spec_helper'
require 'crx_packmgr_api_client'

describe Puppet::Type.type(:aem_crx_package).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:aem_crx_package).new(
      ensure: :present,
      name: 'crx-package',
      group: 'my_packages',
      home: '/opt/aem',
      password: 'admin',
      timeout: 1,
      username: 'admin',
      version: '1.0.0'
    )
  end

  let(:provider) do
    provider = described_class.new(resource)
    provider
  end

  let(:exception) do
    Errno::ECONNREFUSED.new
  end

  let(:list_exists) do
    path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'package_list_exists.json')
    file = File.new(path)
    data = file.read
    data
  end

  let(:list_installed) do
    path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'package_list_installed.json')
    file = File.new(path)
    data = file.read
    data
  end

  let(:list_missing) do
    path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'package_list_missing.json')
    file = File.new(path)
    data = file.read
    data
  end

  describe 'exists?' do
    shared_examples 'exists_check' do |opts|
      it do

        opts[:port] ||= 4502
        case opts[:return_val]
        when 'exists'
          hash = JSON.parse(list_exists, symbolize_names: true).to_hash
        when 'installed'
          hash = JSON.parse(list_installed, symbolize_names: true).to_hash
        when 'missing'
          hash = JSON.parse(list_missing, symbolize_names: true).to_hash
        end

        pkg_list = CrxPackageManager::PackageList.new
        pkg_list = pkg_list.build_from_hash(hash)

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<-EOF
PORT=#{opts[:port]}
        #{crline}
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:list).with(
          path: '/etc/packages/my_packages/crx-package-1.0.0.zip'
        ).and_return(pkg_list)

        expect(provider.exists?).to eq(opts[:expected])
      end
    end

    describe 'ensure is present' do
      describe 'package exists' do
        it_should_behave_like(
          'exists_check',
          return_val: 'exists',
          expected: true
        )
      end
      describe 'package does not exist' do
        it_should_behave_like(
          'exists_check',
          return_val: 'installed',
          expected: true
        )
      end
      describe 'package does not exist' do
        it_should_behave_like(
          'exists_check',
          return_val: 'missing',
          expected: false
        )
      end
    end
  end
end
