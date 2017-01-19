require 'spec_helper_acceptance'
require 'crx_packmgr_api_client'

describe 'crx package mgr api', license: false do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  it 'should purge package' do
    # Make sure it's not the right state to start
    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/200/)
    end

    cmd = 'curl -s "http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip'
    cmd += '&includeVersions=true" '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(1)
    end

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => purged,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          source      => \"/tmp/test-1.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(0)
    end

    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/404/)
    end
  end

  it 'should upload package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(0)
    end

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => present,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          source      => \"/tmp/test-1.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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

  it 'should remove existing package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(1)
    end

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => absent,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(0)
      expect(list.results).to eq([])
    end
  end

  it 'should support upload but not install package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(0)
    end
    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/404/)
    end

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => present,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          source      => \"/tmp/test-1.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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

    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/404/)
    end

  end

  it 'should install existing package' do

    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/404/)
    end

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => installed,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          source      => \"/tmp/test-1.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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
  end

  it 'should uninstall existing package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => present,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          source      => \"/tmp/test-1.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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
    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/404/)
    end
  end

  it 'should remove uploaded package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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

    site = <<-MANIFEST
      'node \"agent\" {

        aem::crx::package { \"author-test-pkg\" :
          ensure      => absent,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          type        => \"api\",
          username    => \"admin\"
        }

      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(0)
    end
  end

  it 'should install package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout, symbolize_names: true)
      list = CrxPackageManager::PackageList.new
      list.build_from_hash(jsonresult)

      expect(list.total).to eq(0)
    end

    site = <<-MANIFEST
      'node \"agent\" {

        aem::crx::package { \"author-test-pkg\" :
          ensure      => installed,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"1.0.0\",
          source      => \"/tmp/test-1.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }

      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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

  it 'should install new version of package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
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
      expect(result.stdout).to match(/404/)
    end

    site = <<-MANIFEST
      'node \"agent\" {

        aem::crx::package { \"author-test-pkg\" :
          ensure      => installed,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"2.0.0\",
          source      => \"/tmp/test-2.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }

      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

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
    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/404/)
    end
    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/200/)
    end
  end

  it 'should purge new version of package' do

    # Make sure it's not the right state to start
    cmd = 'curl -s http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-2.0.0.zip '
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
      expect(result.stdout).to match(/404/)
    end
    cmd = 'curl -s -o /dev/null -w "%{http_code}" http://localhost:4502/content/second-package-test.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to match(/200/)
    end

    site = <<-MANIFEST
      'node \"agent\" {
        aem::crx::package { \"author-test-pkg\" :
          ensure      => purged,
          home        => \"/opt/aem/author\",
          password    => \"admin\",
          pkg_group   => \"my_packages\",
          pkg_name    => \"test\",
          pkg_version => \"2.0.0\",
          source      => \"/tmp/test-2.0.0.zip\",
          type        => \"api\",
          username    => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    # Ruby isn't idempotent on all platforms. So we can't check for zero exit status.
    # on(
    #   default,
    #   puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    #   acceptable_exit_codes: [0]
    # )

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
      expect(result.stdout).to match(/404/)
    end
  end
end
