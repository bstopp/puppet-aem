# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'destroy' do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  it 'should work with no errors' do

    site = <<-MANIFEST
      'node \"agent\" {
        File { backup => false, owner => \"aem\", group => \"aem\" }

        aem::instance { \"author\" : :ensure       => absent,
          manage_user  => false,
          manage_group => false,
          manage_home  => false,
          user         => \"vagrant\",
          group        => \"vagrant\",
          home         => \"/opt/aem/author\",
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp': :ensure => file,
          content => #{site}
      }
    MANIFEST

    on default, puppet('resource', 'service', 'aem-author', 'ensure=stopped')
    apply_manifest_on(master, pp, catch_failures: true)
    fqdn = on(master, 'facter fqdn').stdout.strip
    restart_puppetserver
    on(
      default,
      puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )
  end

  it 'should have removed instance repository' do
    shell('ls /opt/aem/author/crx-quickstart', acceptable_exit_codes: 2)
  end
end
