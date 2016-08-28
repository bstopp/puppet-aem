require 'spec_helper_acceptance'

describe 'create license file', license: false do

  let(:facts) do
    {
      environment: :root
    }
  end

  let(:license) do
    ENV['AEM_LICENSE'] || 'fake-key-for-testing'
  end

  it 'should create file with no errors' do
    site = <<-MANIFEST
      'node \"agent\" {
        File { backup => false, owner => \"aem\", group => \"aem\" }

        group { \"aem\" : ensure => \"present\" }

        user { \"aem\" : ensure => \"present\", gid =>  \"aem\" }

        file { \"/opt/aem\" : ensure => directory }
        file { \"/opt/aem/author\" : ensure => directory }

        Aem::License {
          customer    => \"Vagrant Test\",
          license_key => \"#{license}\",
          version     => \"6.1.0\",
        }

        aem::license { \"author\" :
          group   => \"vagrant\",
          user    => \"vagrant\",
          home    => \"/opt/aem/author\",
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
    shell('grep "license.customer.name=Vagrant Test" /opt/aem/author/license.properties',
          acceptable_exit_codes: 0)
  end

  it 'should contain licnese_key' do
    shell("grep -- \"license.downloadID=#{license}\" /opt/aem/author/license.properties",
          acceptable_exit_codes: 0)
  end

  it 'should contain version' do
    shell('grep "license.product.version=6.1.0" /opt/aem/author/license.properties',
          acceptable_exit_codes: 0)
  end
end
