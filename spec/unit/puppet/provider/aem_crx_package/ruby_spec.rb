require 'spec_helper'
require 'crx_packmgr_api_client'

describe Puppet::Type.type(:aem_crx_package).provider(:ruby) do

  let(:source) do
    File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'test-1.0.0.zip')
  end

  let(:resource) do

    Puppet::Type.type(:aem_crx_package).new(
      ensure: :present,
      name: 'test',
      group: 'my_packages',
      home: '/opt/aem',
      password: 'admin',
      source: source,
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

  let(:service_response) do
    File.new(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'api_response.xml')).read
  end

  let(:service_failure) do
    File.new(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'api_error.xml')).read
  end

  describe 'retrieve ensure value' do
    shared_examples 'resource_check' do |opts|
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
          path: '/etc/packages/my_packages/test-1.0.0.zip'
        ).and_return(pkg_list)

        expect(provider.retrieve).to eq(opts[:expected])
      end
    end

    describe 'package exists' do
      it_should_behave_like(
        'resource_check',
        return_val: 'exists',
        expected: :present
      )
    end
    describe 'package does not exist' do
      it_should_behave_like(
        'resource_check',
        return_val: 'installed',
        expected: :installed
      )
    end
    describe 'package does not exist' do
      it_should_behave_like(
        'resource_check',
        return_val: 'missing',
        expected: :absent
      )
    end

    describe 'supports context root' do
      it_should_behave_like(
        'resource_check',
        return_val: 'exists',
        expected: :present,
        context_root: 'contextroot'
      )
    end

    describe 'supports port' do
      it_should_behave_like(
        'resource_check',
        return_val: 'exists',
        expected: :present,
        port: '8080'
      )
    end
  end

  describe 'flush' do
    describe 'ensure present' do
      context 'resource does not exist' do
        it 'should upload source file' do
          envdata = <<-EOF
          PORT=4502
          EOF

          expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

          # Setup Missing API Call
          hash = JSON.parse(list_missing, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          # Should upload file
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:service_post).with(
            instance_of(File), install: false
          ).and_return(service_response)

          # Should repopulate data after upload
          hash = JSON.parse(list_exists, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          expect { provider.retrieve }.not_to raise_error
          expect { provider.upload }.not_to raise_error
          expect { provider.flush }.not_to raise_error

          expect(provider.resource[:group]).to eq('my_packages')
          expect(provider.resource[:name]).to eq('test')
          expect(provider.resource[:version]).to eq('1.0.0')
          expect(provider.resource[:ensure]).to eq(:present)
        end
      end

      context 'resource exists and installed' do
        it 'should uninstall package' do
          envdata = <<-EOF
          PORT=4502
          EOF

          expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

          # Setup Installed API Call
          hash = JSON.parse(list_installed, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          # Should uninstall package
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:service_get).with(
            'uninst', name: 'test', group: 'my_packages'
          ).and_return(service_response)

          # Should repopulate data after upload
          hash = JSON.parse(list_exists, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          expect { provider.retrieve }.not_to raise_error
          expect { provider.upload }.not_to raise_error
          expect { provider.flush }.not_to raise_error

          expect(provider.resource[:group]).to eq('my_packages')
          expect(provider.resource[:name]).to eq('test')
          expect(provider.resource[:version]).to eq('1.0.0')
          expect(provider.resource[:ensure]).to eq(:present)
        end
      end
    end

    describe 'install' do
      context 'does not exist' do
        let(:resource) do

          source = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'test-1.0.0.zip')

          Puppet::Type.type(:aem_crx_package).new(
            ensure: :installed,
            name: 'test',
            group: 'my_packages',
            home: '/opt/aem',
            password: 'admin',
            source: source,
            timeout: 1,
            username: 'admin',
            version: '1.0.0'
          )
        end
        it 'should upload source file with install == true' do
          envdata = <<-EOF
          PORT=4502
          EOF

          expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

          # Setup Missing API Call
          hash = JSON.parse(list_missing, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          # Should upload/install file
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:service_post).with(
            instance_of(File), install: true
          ).and_return(service_response)

          # Should repopulate data after upload
          hash = JSON.parse(list_exists, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          expect { provider.retrieve }.not_to raise_error
          expect { provider.install }.not_to raise_error
          expect { provider.flush }.not_to raise_error

          expect(provider.resource[:group]).to eq('my_packages')
          expect(provider.resource[:name]).to eq('test')
          expect(provider.resource[:version]).to eq('1.0.0')
          expect(provider.resource[:ensure]).to eq(:installed)
        end
      end

      context 'exists' do
        let(:resource) do

          source = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'files', 'test-1.0.0.zip')

          Puppet::Type.type(:aem_crx_package).new(
            ensure: :installed,
            name: 'test',
            group: 'my_packages',
            home: '/opt/aem',
            password: 'admin',
            source: source,
            timeout: 1,
            username: 'admin',
            version: '1.0.0'
          )
        end
        it 'should install package' do
          envdata = <<-EOF
          PORT=4502
          EOF

          expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

          # Setup Missing API Call
          hash = JSON.parse(list_exists, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          # Should upload/install file
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:service_get).with(
            'inst', name: 'test', group: 'my_packages'
          ).and_return(service_response)

          # Should repopulate data after upload
          hash = JSON.parse(list_installed, symbolize_names: true).to_hash
          pkg_list = CrxPackageManager::PackageList.new
          pkg_list = pkg_list.build_from_hash(hash)
          expect_any_instance_of(
            CrxPackageManager::DefaultApi
          ).to receive(:list).with(
            path: '/etc/packages/my_packages/test-1.0.0.zip'
          ).and_return(pkg_list)

          expect { provider.retrieve }.not_to raise_error
          expect { provider.install }.not_to raise_error
          expect { provider.flush }.not_to raise_error

          expect(provider.resource[:group]).to eq('my_packages')
          expect(provider.resource[:name]).to eq('test')
          expect(provider.resource[:version]).to eq('1.0.0')
          expect(provider.resource[:ensure]).to eq(:installed)
        end
      end
    end

    describe 'absent' do
      let(:resource) do
        Puppet::Type.type(:aem_crx_package).new(
          ensure: :absent,
          name: 'test',
          group: 'my_packages',
          home: '/opt/aem',
          password: 'admin',
          username: 'admin',
          version: '1.0.0'
        )
      end
      it 'should remove package' do
        envdata = <<-EOF
        PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        # Setup Missing API Call
        hash = JSON.parse(list_exists, symbolize_names: true).to_hash
        pkg_list = CrxPackageManager::PackageList.new
        pkg_list = pkg_list.build_from_hash(hash)
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:list).with(
          path: '/etc/packages/my_packages/test-1.0.0.zip'
        ).and_return(pkg_list)

        # Should remove the file
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:service_get).with(
          'rm', group: 'my_packages', name: 'test'
        ).and_return(service_response)

        # Should repopulate data after upload
        hash = JSON.parse(list_missing, symbolize_names: true).to_hash
        pkg_list = CrxPackageManager::PackageList.new
        pkg_list = pkg_list.build_from_hash(hash)
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:list).with(
          path: '/etc/packages/my_packages/test-1.0.0.zip'
        ).and_return(pkg_list)

        expect { provider.retrieve }.not_to raise_error
        expect { provider.remove }.not_to raise_error
        expect { provider.flush }.not_to raise_error

        expect(provider.resource[:group]).to eq('my_packages')
        expect(provider.resource[:name]).to eq('test')
        expect(provider.resource[:version]).to eq('1.0.0')
        expect(provider.resource[:ensure]).to eq(:absent)

      end
    end
  end
  describe 'error cases' do
    describe 'ensure installed upload call fails' do

      it 'should raise an error' do
        envdata = <<-EOF
        PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        # Setup Missing API Call
        hash = JSON.parse(list_missing, symbolize_names: true).to_hash
        pkg_list = CrxPackageManager::PackageList.new
        pkg_list = pkg_list.build_from_hash(hash)
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:list).with(
          path: '/etc/packages/my_packages/test-1.0.0.zip'
        ).and_return(pkg_list)

        # Should raise an error file
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:service_post).with(
          instance_of(File), install: false
        ).and_return(service_failure)

        expect { provider.retrieve }.not_to raise_error
        expect { provider.upload }.not_to raise_error
        expect { provider.flush }.to raise_error(/An Error Occurred/)

      end
    end

    context 'ensure absent remove call fails' do
      let(:resource) do
        Puppet::Type.type(:aem_crx_package).new(
          ensure: :absent,
          name: 'test',
          group: 'my_packages',
          home: '/opt/aem',
          password: 'admin',
          username: 'admin',
          version: '1.0.0'
        )
      end

      it 'should raise an error' do
        envdata = <<-EOF
        PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        # Setup Missing API Call
        hash = JSON.parse(list_exists, symbolize_names: true).to_hash
        pkg_list = CrxPackageManager::PackageList.new
        pkg_list = pkg_list.build_from_hash(hash)
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:list).with(
          path: '/etc/packages/my_packages/test-1.0.0.zip'
        ).and_return(pkg_list)

        # Should raise an error file
        expect_any_instance_of(
          CrxPackageManager::DefaultApi
        ).to receive(:service_get).with(
          'rm', group: 'my_packages', name: 'test'
        ).and_return(service_failure)

        expect { provider.retrieve }.not_to raise_error
        expect { provider.remove }.not_to raise_error
        expect { provider.flush }.to raise_error(/An Error Occurred/)

      end
    end
  end
end
