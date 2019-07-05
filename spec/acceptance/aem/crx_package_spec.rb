# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'crx_packmgr_api_client'

def manifest(file)
  step 'Create Manifest' do
    pp = <<~MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          source => '#{file}'
      }
    MANIFEST
    apply_manifest_on(master, pp, catch_failures: true)
  end
end

def agent
  step 'Run Agent' do
    with_puppet_running_on(master, {}, '/tmp') do

      on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0, 2])
      on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0])
    end
  end
end

describe 'crx package mgr api', license: false do

  it 'should purge package' do
    step 'Pretest Validation' do

      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end

      cmd = 'curl -s "http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip'
      cmd += '&includeVersions=true" '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(2)
      end
    end
    step 'Run Test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/purge_run.pp')
      agent

      cmd = 'curl -s "http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip'
      cmd += '&includeVersions=false" '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end

      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end

      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
    end
  end

  it 'should upload package' do
    step 'Pretest Validation' do
      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/upload_run.pp')
      agent
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).to be_nil
      end
    end
  end

  it 'should remove existing package' do
    step 'Pretest Validation' do
      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/remove_run.pp')
      agent
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
        expect(list.results).to eq([])
      end
    end
  end

  it 'should support upload but not install package' do
    step 'Pretest Validation' do

      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/upload_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]

        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).to be_nil
      end

      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end
    end
  end

  it 'should install existing package' do
    step 'Pretest Validation' do
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end

      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).to be_nil
      end
    end
    step 'Run Test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/install_existing_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).not_to be_nil
      end

      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
    end
  end
  it 'should uninstall existing package' do
    step 'Pretest Validation' do

      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).not_to be_nil
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
    end
    step 'Run Test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/uninstall_existing_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).to be_nil
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end
    end
  end

  it 'should remove uploaded package' do
    step 'Pretest Validation' do

      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).to be_nil
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/purge_existing_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
      end
    end
  end

  it 'should install package' do
    step 'Pretest Validation' do
      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/install_new_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).not_to be_nil
      end
    end
  end

  it 'should install new version of package' do
    step 'Pretest Validation' do
      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/install_version_run.pp')
      agent


      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-3.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).not_to be_nil
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
    end
  end

  it 'should purge new version of package' do
    step 'Pretest Validation' do

      # Make sure its in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-3.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(1)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end

    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/purge_version_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-3.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)
        expect(list.total).to eq(0)
      end
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)
        expect(list.total).to eq(1)
        pkg = list.results[0]
        expect(pkg.last_unwrapped).not_to be_nil
        expect(pkg.last_unpacked).not_to be_nil
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/200/)
      end
      cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end
    end
  end

  it 'should support multiple packages defined in one manifest' do
    step 'Pretest Validation' do
      # Make sure it's in the right state to start
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-3.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/secondtest-1.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)

        expect(list.total).to eq(0)
      end
    end
    step 'Run test' do
      manifest('/vagrant/puppet/files/manifests/aem/crx_package/multiple_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-3.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)
        expect(list.total).to eq(1)
      end
      cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/secondtest-1.0.0.zip '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout, symbolize_names: true)
        list = CrxPackageManager::PackageList.new
        list.build_from_hash(jsonresult)
        expect(list.total).to eq(1)
      end
    end
  end
end