require 'spec_helper_acceptance'
require 'crx_packmgr_api_client'

describe 'crx package mgr api', license: false do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  it 'should remove existing package' do

    site = <<-MANIFEST
      'node \"agent\" {

        aem::crx::package { \"author-test-pkg\" :
          ensure         => absent,
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          pkg_group      => \"my_packages\",
          pkg_name       => \"test\",
          pkg_version    => \"1.0.0\",
          type           => \"api\",
          username       => \"admin\",
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
      puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    on(
      default,
      puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0]
    )

    cmd = 'curl http://localhost:4502/crx/packmgr/list.jsp?path=/etc/packages/my_packages/test-1.0.0.zip '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout)
      list = CrxPackageManager::PackageList.new
      data = list.build_from_hash(jsonresult)
      expect(data.total).to eq(0)
      expect(data.results).to be_nil
    end
  end
end
