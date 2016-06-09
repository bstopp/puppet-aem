require 'spec_helper_acceptance'

describe 'dispatcher acceptance' do

  let(:facts) do
    {
      :environment => :root
    }
  end

  case fact('osfamily')
  when 'RedHat'
    service_name = 'httpd'
    log_root = '/var/log/httpd'
    mod_root = '/etc/httpd/modules'
    apache_root = '/etc/httpd'
    conf_dir = '/etc/httpd/conf.modules.d'
  when 'Debian'
    service_name = 'apache2'
    log_root = '/var/log/apache2'
    mod_root = '/usr/lib/apache2/modules'
    apache_root = '/etc/apache2'
    conf_dir = '/etc/apache2/mods-enabled'
  end

  describe 'aem::dispatcher' do
    context 'setup' do
      it 'should work with no errors' do
        site = <<-MANIFEST
          'node \"agent\" {
            File { backup => false }

            class { \"apache\" : }
            class { \"aem::dispatcher\" :
              module_file => \"/tmp/dispatcher-apache-module.so\",
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

        apply_manifest_on(master, pp, :catch_failures => true)

        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')
        # Clear the logs to setup test cases.
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0]
        )
      end
      it 'should be running with no errors' do
        shell(
          "grep -- 'Communique/4.1.11 configured -- resuming normal operations' #{log_root}/error*",
          :acceptable_exit_codes => 0
        )

        found = false
        shell("find #{log_root}/ -name \"dispatcher.log\" -type f") do |result|
          found = %r|^#{log_root}/dispatcher.log| =~ result.stdout
        end
        if found
          shell("cat #{log_root}/dispatcher.log") do |result|
            expect(result.stdout).to match(//)
          end
        end
      end
    end

    context 'dispatcher modules' do
      it 'should have copied the dispatcher module file' do
        shell("find #{mod_root}/ -name \"dispatcher-apache-module.so\" -type f") do |result|
          expect(result.stdout).to match(%r|^#{mod_root}/dispatcher-apache-module.so|)
        end
      end

      it 'should be owned by specified user/group' do
        shell("stat -c \"%U:%G\" #{mod_root}/dispatcher-apache-module.so") do |result|
          expect(result.stdout).to match('root:root')
        end
      end

      it 'should have created module file' do
        shell("find #{mod_root}/ -name \"mod_dispatcher.so\"") do |result|
          expect(result.stdout).to match(%r|^#{mod_root}/mod_dispatcher.so|)
        end
      end

      it 'module file should be a symbolic link' do
        shell("stat -c \"%F\" #{mod_root}/mod_dispatcher.so") do |result|
          expect(result.stdout).to match('symbolic link')
        end
      end
    end

    context 'dispatcher conf' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.conf\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.conf|)
        end
      end
      it 'should specify the Dispatcher Config' do
        shell(
          "grep -- 'DispatcherConfig.*#{conf_dir}/dispatcher.farms.any' #{conf_dir}/dispatcher.conf",
          :acceptable_exit_codes => 0
        )
      end
      it 'should specify the Dispatcher Log' do
        shell(
          "grep -- 'DispatcherLog.*#{log_root}/dispatcher.log' #{conf_dir}/dispatcher.conf",
          :acceptable_exit_codes => 0
        )
      end
      it 'should specify the Dispatcher Log Level' do
        shell("grep -- 'DispatcherLogLevel.*warn' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Server Header' do
        shell("grep -- 'DispatcherNoServerHeader.*off' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Decline Root' do
        shell("grep -- 'DispatcherDeclineRoot.*off' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Processed URL' do
        shell("grep -- 'DispatcherUseProcessedURL.*off' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Pass Error' do
        shell("grep -- 'DispatcherPassError.*0' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
    end

    context 'dispatcher farms any' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.farms.any\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.farms.any|)
        end
      end
    end
  end

  describe 'dispatcher farm' do
    context 'setup' do
      it 'should work with no errors' do
        site = <<-MANIFEST
          'node \"agent\" {
            File { backup => false }

            class { \"apache\" : }
            class { \"aem::dispatcher\" :
              module_file => \"/tmp/dispatcher-apache-module.so\",
            }
            aem::dispatcher::farm { \"site\" :
              docroot             => \"/var/www\",
              allow_authorized    => 0,
              allowed_clients     => [ { \"type\" => \"deny\", \"glob\" => \"*\" }, { \"type\" => \"allow\", \"glob\" => \"127.0.0.1\" } ],
              cache_headers       => [ \"A-Cache-Header\", \"Another-Cache-Header\" ],
              cache_rules         => [ { \"glob\" => \"*\", \"type\" => \"deny\" }, { \"glob\" => \"*.html\", \"type\" => \"allow\" } ],
              cache_ttl           => "1",
              client_headers      => [ \"A-Client-Header\", \"Another-Client-Header\" ],
              failover            => "1",
              filters             => [ { \"rank\" => 300, \"type\" => \"deny\", \"glob\" => \"*\" }, { \"rank\" => 310, \"type\" => \"allow\", \"glob\" => \"*.html\" }],
              grace_period        => "1",
              health_check_url    => "/path/to/healthcheck",
              ignore_parameters   => [ { \"glob\" => \"*\", \"type\" => \"deny\" }, { \"glob\" => \"param=*\", \"type\" => \"allow\" } ],
              invalidate          => [ { \"glob\" => \"*\", \"type\" => \"deny\" }, { \"glob\" => \"*.html\", \"type\" => \"allow\" } ],
              propagate_synd_post => "1",
              retries             => "5",
              retry_delay         => "30",
              renders             => { \"hostname\" => \"publish.hostname.com\", \"port\" => 8080, \"timeout\" => 600, \"receiveTimeout\" => 300, \"ipv4\" => 0 },
              serve_stale         => "1",
              session_management  => { \"directory\" => \"/path/to/cache\", \"encode\" => \"md5\", \"header\" => \"HTTP:authorization\", \"timeout\" => 1000 },
              stat_file           => "/path/to/statfile",
              stat_files_level    => "3",
              statistics          => [ { \"glob\" => \"*.html\", \"category\" => \"html\" }, { \"glob\" => \"*\", \"category\" => \"others\" } ],
              sticky_connections  => \"/path/to/content\",
              unavailable_penalty => \"2\",
              vanity_urls         => { \"file\" => \"/path/to/cache\", \"delay\" => 600, },
              virtualhosts        => [ \"www.avirtualhost.com\", \"another.virtual.com\" ],
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

        apply_manifest_on(master, pp, :catch_failures => true)

        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')
        on(default, puppet("resource service #{service_name} ensure=stopped"))
        shell("rm #{log_root}/*", :accept_all_exit_codes => true)
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )
      end

      it 'should be running with no errors' do
        shell(
          "grep -- 'Communique/4.1.11 configured -- resuming normal operations' #{log_root}/error*",
          :acceptable_exit_codes => 0
        )
        found = false
        shell("find #{log_root}/ -name \"dispatcher.log\" -type f") do |result|
          found = %r|^#{log_root}/dispatcher.log| =~ result.stdout
        end
        if found
          shell("cat #{log_root}/dispatcher.log") do |result|
            expect(result.stdout).to match(//)
          end
        end
      end
    end

    context 'dispatcher farm conf' do
      it 'should include the site file' do
        shell(
          "grep -- '$include \"dispatcher.site.any\"' #{conf_dir}/dispatcher.farms.any",
          :acceptable_exit_codes => 0
        )
      end
    end

    context 'dispatcher site any' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.site.any\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.site.any|)
        end
      end
      it 'should use name for root node' do
        shell("grep -- '/site' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include allowAuthorized' do
        shell("grep -- '/allowAuthorized \"0\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include allowedClients' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/allowedClients {\s*\\/0 { \\/type \"deny\" \\/glob \"\\*\" }\\s*"
        cmd += "\\/1 { \\/type \"allow\" \\/glob \"127.0.0.1\" }/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/allowedClients|)
        end
      end
      it 'should include cache_headers' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/headers {\\s*\"A-Cache-Header\"\\s*\"Another-Cache-Header\"\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/headers|)
        end
      end
      it 'should include cache_rules' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/rules {\s*\\/0 { \\/type \"deny\" \\/glob \"\\*\" }\\s*"
        cmd += "\\/1 { \\/type \"allow\" \\/glob \"\\*.html\" }/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/rules|)
        end
      end
      it 'should include cache_ttl' do
        shell("tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | sed -n '/\\/enableTTL \"1\"/ p'") do |result|
          expect(result.stdout).to match(%r|/enableTTL|)
        end
      end
      it 'should include client_headers' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/clientheaders {\\s*\"A-Client-Header\"\\s*\"Another-Client-Header\"\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/clientheaders|)
        end
      end
      it 'should include the docroot' do
        shell("grep -- '/docroot \"/var/www\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include failover' do
        shell("grep -- '/failover \"1\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include filters' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/filter {\\s*\\/0 { \\/type \"deny\" \\/glob \"\\*\" }\\s*"
        cmd += "\\/1 { \\/type \"allow\" \\/glob \"\\*.html\" }/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/filter|)
        end
      end
      it 'should include grace_period' do
        shell("grep -- '/gracePeriod \"1\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include health_check_url' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/health_check { \\/url \"\\/path\\/to\\/healthcheck\" }/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/health_check|)
        end
      end
      it 'should include ignore_parameters' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/ignoreUrlParams {\\s*\\/0 { \\/type \"deny\" \\/glob \"\\*\" }\s*"
        cmd += "\\/1 { \\/type \"allow\" \\/glob \"param=\\*\" }/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/ignoreUrlParams|)
        end
      end
      it 'should include invalidate' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/invalidate {\\s*\\/0 { \\/type \"deny\" \\/glob \"\\*\" }\\s*"
        cmd += "\\/1 { \\/type \"allow\" \\/glob \"\\*.html\" }\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/invalidate|)
        end
      end
      it 'should include propagate_synd_post' do
        shell("grep -- '/propagateSyndPost \"1\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include retries' do
        shell("grep -- '/numberOfRetries \"5\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include retry_delay' do
        shell("grep -- '/retryDelay \"30\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include renderers' do
        cmd = "tr -d \"\\n\\r\" < #{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/renders {\\s*\\/renderer0 {\\s*\\/hostname\\s*\"publish.hostname.com\"\\s*"
        cmd += "\\/port\\s\"8080\"\\s*\\/timeout\\s*\"600\"\\s*\\/receiveTimeout\\s*\"300\"\\s*\\/ipv4\\s\"0\"\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/renders|)
        end
      end
      it 'should include serve_stale' do
        shell("grep -- '/serveStaleOnError \"1\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include session_management' do
        cmd = 'tr -d "\n\r" < '
        cmd += "#{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/sessionmanagement {\\s*\\/directory\\s*\"\\/path\\/to\\/cache\"\\s*"
        cmd += "\\/encode\\s\"md5\"\\s*\\/header\\s\"HTTP:authorization\"\\s*\\/timeout\\s\"1000\"\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/sessionmanagement|)
        end
      end
      it 'should include statfile' do
        shell("grep -- '/statfile \"/path/to/statfile\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include stat_files_level' do
        shell("grep -- '/statfileslevel \"3\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include statistics' do
        cmd = 'tr -d "\n\r" < '
        cmd += "#{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/statistics {\\s*\\/categories {\\s*\\/html "
        cmd += "{ \\/glob \"\\*.html\" }\\s*\\/others { \\/glob \"\\*\" }\\s*}\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/statistics|)
        end
      end
      it 'should include sticky_connections' do
        shell(
          "grep -- '/stickyConnectionsFor \"/path/to/content\"' #{conf_dir}/dispatcher.site.any",
          :acceptable_exit_codes => 0
        )
      end
      it 'should include unavailable_penalty' do
        shell("grep -- '/unavailablePenalty \"2\"' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include vanity_urls' do
        cmd = 'tr -d "\n\r" < '
        cmd += "#{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/vanity_urls {\\s*\\/url "
        cmd += '"\\/libs\\/granite\\/dispatcher\\/content\\/vanityUrls.html"\\s*\\/file '
        cmd += "\"\\/path\\/to\\/cache\"\s*\\/delay \"600\"\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/vanity_urls|)
        end
      end
      it 'should include virtualhosts' do
        cmd = 'tr -d "\n\r" < '
        cmd += "#{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/virtualhosts {\\s*\"www.avirtualhost.com\"\\s*\"another.virtual.com\"\\s*}/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/virtualhosts|)
        end
      end
    end
  end

  describe 'update conf' do

    let(:facts) do
      {
        :environment => :root
      }
    end

    context 'setup' do
      it 'should work with no errors' do
        site = <<-MANIFEST
          'node \"agent\" {
            File { backup => false }

            class { \"apache\" : }
            class { \"aem::dispatcher\" :
              decline_root      => 1,
              dispatcher_name   => \"named instance\",
              log_file          => \"\${::apache::logroot}/my-dispatcher.log\",
              log_level         => 3,
              module_file       => \"/tmp/dispatcher-apache-module.so\",
              no_server_header  => \"on\",
              use_processed_url => 1,
              pass_error        => \"400-404,500",
            }
            aem::dispatcher::farm { \"anothersite\" :
              docroot => \"/var/www\",
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

        apply_manifest_on(master, pp, :catch_failures => true)

        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')
        on(default, puppet("resource service #{service_name} ensure=stopped"))
        shell("rm #{log_root}/*", :accept_all_exit_codes => true)
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )
      end

      it 'should be running with no errors' do
        shell(
          "grep -- 'Communique/4.1.11 configured -- resuming normal operations' #{log_root}/error*",
          :acceptable_exit_codes => 0
        )
        found = false
        shell("find #{log_root}/ -name \"dispatcher.log\" -type f") do |result|
          found = %r|^#{log_root}/dispatcher.log| =~ result.stdout
        end
        if found
          shell("cat #{log_root}/dispatcher.log") do |result|
            expect(result.stdout).to match(//)
          end
        end
      end
    end

    context 'dispatcher conf' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.conf\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.conf|)
        end
      end

      it 'should specify the Dispatcher Config' do
        shell(
          "grep -- 'DispatcherConfig.*#{conf_dir}/dispatcher.farms.any' #{conf_dir}/dispatcher.conf",
          :acceptable_exit_codes => 0
        )
      end
      it 'should specify the Dispatcher Log' do
        shell(
          "grep -- 'DispatcherLog.*#{log_root}/my-dispatcher.log' #{conf_dir}/dispatcher.conf",
          :acceptable_exit_codes => 0
        )
      end
      it 'should specify the Dispatcher Log Level' do
        shell("grep -- 'DispatcherLogLevel.*3' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Server Header' do
        shell("grep -- 'DispatcherNoServerHeader.*on' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Decline Root' do
        shell("grep -- 'DispatcherDeclineRoot.*1' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Processed URL' do
        shell("grep -- 'DispatcherUseProcessedURL.*1' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end
      it 'should specify the Dispatcher Pass Error' do
        shell("grep -- 'DispatcherPassError.*400-404,500' #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 0)
      end

    end

    context 'dispatcher farms any' do
      it 'should exist' do
        shell("find #{conf_dir}/ -name \"dispatcher.farms.any\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.farms.any|)
        end
      end

      it 'should update the site file' do
        shell(
          "grep -- 'include.*dispatcher.anothersite.any' #{conf_dir}/dispatcher.farms.any",
          :acceptable_exit_codes => 0
        )
      end

      it 'should have the name' do
        shell("grep -- 'named instance' #{conf_dir}/dispatcher.farms.any", :acceptable_exit_codes => 0)
      end
    end

  end

  describe 'update conf' do

    let(:facts) do
      {
        :environment => :root
      }
    end

    context 'multiple sites' do
      it 'should work with no errors' do
        site = <<-MANIFEST
          'node \"agent\" {
            File { backup => false }

            class { \"apache\" : }
            class { \"aem::dispatcher\" :
              module_file => \"/tmp/dispatcher-apache-module.so\",
            }
            aem::dispatcher::farm { \"site\" :
              docroot            => \"/var/www\",
              invalidate_handler => \"/path/to/handler\",
              sticky_connections => [\"/path/to/content\", \"/another/path/to/content\"],
            }
            aem::dispatcher::farm { \"anothersite\" :
              docroot => \"/var/www\",
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

        apply_manifest_on(master, pp, :catch_failures => true)

        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')
        on(default, puppet("resource service #{service_name} ensure=stopped"))
        shell("rm #{log_root}/*", :accept_all_exit_codes => true)
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )
      end

      it 'should be running with no errors' do
        shell(
          "grep -- 'Communique/4.1.11 configured -- resuming normal operations' #{log_root}/error*",
          :acceptable_exit_codes => 0
        )

        found = false
        shell("find #{log_root}/ -name \"dispatcher.log\" -type f") do |result|
          found = %r|^#{log_root}/dispatcher.log| =~ result.stdout
        end
        if found
          shell("cat #{log_root}/dispatcher.log") do |result|
            expect(result.stdout).to match(//)
          end
        end
      end
    end

    context 'dispatcher farms any' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.farms.any\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.farms.any|)
        end
      end
      it 'should include the site file' do
        shell("grep -- 'include.*dispatcher.site.any' #{conf_dir}/dispatcher.farms.any", :acceptable_exit_codes => 0)
      end
      it 'should include the second site file' do
        shell(
          "grep -- 'include.*dispatcher.anothersite.any' #{conf_dir}/dispatcher.farms.any",
          :acceptable_exit_codes => 0
        )
      end
    end
    context 'dispatcher any - site' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.site.any\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.site.any|)
        end
      end
      it 'should use name for root node' do
        shell("grep -- '/site' #{conf_dir}/dispatcher.site.any", :acceptable_exit_codes => 0)
      end
      it 'should include invalidate_handler' do
        cmd = 'tr -d "\n\r" < '
        cmd += "#{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/invalidateHandler \"\\/path\\/to\\/handler\"/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/invalidateHandler|)
        end
      end
      it 'should include stickyConnections' do
        cmd = 'tr -d "\n\r" < '
        cmd += "#{conf_dir}/dispatcher.site.any | "
        cmd += "sed -n '/\\/stickyConnections {\\s*\\/paths "
        cmd += "{\\s*\"\\/path\\/to\\/content\"\\s*\"\\/another\\/path\\/to\\/content\"/ p'"
        shell(cmd) do |result|
          expect(result.stdout).to match(%r|/stickyConnections|)
        end
      end
    end
    context 'dispatcher any - anothersite' do
      it 'should exist' do
        shell("find #{apache_root}/ -name \"dispatcher.anothersite.any\"") do |result|
          expect(result.stdout).to match(%r|^#{conf_dir}/dispatcher.anothersite.any|)
        end
      end
      it 'should use name for root node' do
        shell("grep -- '/anothersite' #{conf_dir}/dispatcher.anothersite.any", :acceptable_exit_codes => 0)
      end
    end
  end

  describe 'destroy' do

    it 'should work with no errors' do

      site = <<-MANIFEST
        'node \"agent\" {
          File { backup => false }

          class { \"apache\" : }
          class { \"aem::dispatcher\" :
            ensure      => \"absent\",
            module_file => \"/tmp/dispatcher-apache-module.so\",
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

      apply_manifest_on(master, pp, :catch_failures => true)
      restart_puppetserver
      fqdn = on(master, 'facter fqdn').stdout.strip
      fqdn = fqdn.chop if fqdn.end_with?('.')
      on(default, puppet("resource service #{service_name} ensure=stopped"))
      shell("rm #{log_root}/*", :accept_all_exit_codes => true)
      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        :acceptable_exit_codes => [0, 2]
      )
    end

    it 'should have removed sym link' do
      shell("ls #{mod_root}/mod_dispatcher.so", :acceptable_exit_codes => 2)
    end

    it 'should have removed module file' do
      shell("ls #{mod_root}/dispatcher-apache-module.so", :acceptable_exit_codes => 2)
    end

    it 'should have removed dispatcher.conf' do
      shell("ls #{conf_dir}/dispatcher.conf", :acceptable_exit_codes => 2)
    end

  end

end
