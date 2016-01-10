require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem::dispatcher::farm', :type => :define do

  let :pre_condition do
    '
    class { "apache": default_vhost => false, default_mods => false, vhost_enable_dir => "/etc/apache2/sites-enabled"}
    class { aem::dispatcher : module_file => "/tmp/module.so" }
    '
  end

  let :default_params do 
    {
      :docroot => '/path/to/docroot'
    }
  end

  let :title do
    'aem-site'
  end

  let :default_facts do
    {
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '7.1.1503',
      :operatingsystem        => 'CentOS',
      :concat_basedir         => '/dne',
      :id                     => 'root',
      :kernel                 => 'Linux',
      :path                   => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    }
  end

  describe 'default parameters' do
    let :facts do default_facts end
    let :params do default_params end

    it { is_expected.to compile }
    it do 
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
      ).with(
        :ensure => 'present'
      ).with_content(
        /\/aem-site {/
      ).without_content(
        /\/allowAuthorized/
      ).with_content(
        /\/allowedClients {\s*\/0 { \/type "allow" \/glob "\*" }\s*}/
      ).with_content(
        /\/clientheaders {\s*"\*"\s*}/
      ).with_content(
        /\/docroot \s*"\/path\/to\/docroot"\s*/
      ).without_content(
        /\/enableTTL/
      ).without_content(
        /gracePeriod/
      ).without_content(
        /\/headers/
      ).without_content(
        /failover/
      ).without_content(
        /health_check/
      ).without_content(
        /ignoreUrlParameters/
      ).with_content(
        /\/invalidate {\s*\/0 { \/type "allow" \/glob "\*" }/
      ).without_content(
        /\/invalidateHandler/
      ).with_content(
        /\/filter {\s*\/0 { \/type "allow" \/glob "\*" }/
      ).without_content(
        /numberOfRetries/
      ).with_content(
        /\/renders {\s*\/renderer0 {\s*\/hostname "localhost"\s*\/port "4503"\s*}/
      ).without_content(
        /retryDelay/
      ).with_content(
        /\/rules {\s*\/0 { \/type "deny" \/glob "\*" }/
      ).without_content(
        /serveStaleOnError/
      ).without_content(
        /sessionmanagement/
      ).without_content(
        /statfile/
      ).without_content(
        /statfileslevel/
      ).without_content(
        /statistics/
      ).without_content(
        /stickyConnections/
      ).without_content(
        /unavailablePenalty/
      ).without_content(
        /vanity_urls/
      ).with_content(
        /\/virtualhosts {\s*"\*"\s*}/
      )
    end
    it do
      is_expected.to contain_file_line(
        'include aem-site.any'
      ).with(
        'ensure' => 'present',
        'after'  => '/farms \{',
        'line'   => '  $include "dispatcher.aem-site.any"',
        'match'  => '  $include "dispatcher.aem-site.any"',
        'path'   => '/etc/httpd/conf.modules.d/dispatcher.farms.any'
      ).that_requires(
        'File[/etc/httpd/conf.modules.d/dispatcher.farms.any]'
      )
    end
  end

  describe 'specify parameters' do
    let :facts do default_facts end

    context 'allow_authorized' do
      let :params do
        default_params.merge(:allow_authorized  => 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
            /\/allowAuthorized "1"/
        )
      end
    end

    context 'allowed_clients' do
      let :params do
        default_params.merge(:allowed_clients => { 'glob' => '10.200.1.1', 'type' => 'allow' })
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/allowedClients {\s*\/0 { \/type "allow" \/glob "10.200.1.1" }\s*}/
        )
      end
    end

    context 'cache_headers' do
      let :params do
        default_params.merge(:cache_headers => [ 'New-Cache-Header', 'Another-Cache-Header' ])
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/headers {\s*"New-Cache-Header"\s*"Another-Cache-Header"\s*}/
        )
      end
    end

    context 'cache_rules' do
      let :params do
        default_params.merge(:cache_rules => [
            { 'glob' => '*', 'type' => 'deny' },
            { 'glob' => '*.html', 'type' => 'allow' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/rules {\s*\/0 { \/type "deny" \/glob "\*" }\s*\/1 { \/type "allow" \/glob "\*.html" }/
        )
      end
    end

    context 'cache_ttl' do
      let :params do
        default_params.merge(:cache_ttl  => 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/enableTTL "1"\s*/
        )
      end
    end

    context 'client_headers' do
      let :params do
        default_params.merge(:client_headers => [ 'New-Client-Header', 'Another-New-Header' ])
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/clientheaders {\s*"New-Client-Header"\s*"Another-New-Header"\s*}/
        )
      end
    end

    context 'failover' do
      let :params do
        default_params.merge(:failover  => 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/failover "1"\s*/
        )
      end
    end

    context 'filter' do
      context 'filter glob' do
        let :params do
          default_params.merge(:filters => { 'type' => 'deny', 'glob' => '/content*' })
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/filter {\s*\/0 { \/type "deny" \/glob "\/content\*" }/
          )
        end
      end
      context 'filter method/url/query/protocol' do
        context 'all request line values' do
          let :params do
            default_params.merge(
              :filters  => {
                'type'     => 'allow',
                'method'   => 'GET',
                'url'      => '/path/to/content',
                'query'    => 'param=*',
                'protocol' => 'https',
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
            ).with_content(
              /\/0 {\s*\/type\s*"allow"\s*\/method\s*"GET"\s*\/url\s*"\/path\/to\/content"\s*\/query\s*"param=\*"\s*\/protocol\s"https"\s*}/
            )
          end
        end

        context 'method only' do
          let :params do
            default_params.merge(
              :filters  => {
                'type'   => 'allow',
                'method' => 'GET',
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
            ).with_content(
              /\/0 {\s*\/type\s*"allow"\s*\/method\s*"GET"\s*}/
            )
          end
        end

        context 'url value' do
          let :params do
            default_params.merge(
              :filters  => {
                'type' => 'allow',
                'url'  => '/path/to/content',
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
            ).with_content(
              /\/0 {\s*\/type\s*"allow"\s*\/url\s*"\/path\/to\/content"\s*}/
            )
          end
        end

        context 'query' do
          let :params do
            default_params.merge(
              :filters  => {
                'type'     => 'allow',
                'query'    => 'param=*',
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
            ).with_content(
              /\/0 {\s*\/type\s*"allow"\s*\/query\s*"param=\*"\s*}/
            )
          end
        end

        context 'protocol' do
          let :params do
            default_params.merge(
              :filters  => {
                'type'     => 'allow',
                'protocol' => 'https',
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
            ).with_content(
              /\/0 {\s*\/type\s*"allow"\s*\/protocol\s"https"\s*}/
            )
          end
        end
      end
    end

    context 'grace_period' do
      let :params do
        default_params.merge(:grace_period  => 5)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/gracePeriod "5"\s*/
        )
      end
    end

    context 'health_check_url' do
      let :params do
        default_params.merge(:health_check_url  => '/health/check/url.html')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/health_check { \/url "\/health\/check\/url.html" }/
        )
      end
    end

    context 'ignore_parameters' do
      let :params do
        default_params.merge(:ignore_parameters => [
            { 'glob' => '*', 'type' => 'deny' },
            { 'glob' => 'param=*', 'type' => 'allow' }
          ]
      )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/ignoreUrlParams {\s*\/0 { \/type "deny" \/glob "\*" }\s*\/1 { \/type "allow" \/glob "param=\*" }\s*}/
        )
      end
    end

    context 'invalidate' do
      let :params do
        default_params.merge(:invalidate => [
            { 'glob' => '*', 'type' => 'deny' },
            { 'glob' => '*.html', 'type' => 'allow' }
          ]
      )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/invalidate {\s*\/0 { \/type "deny" \/glob "\*" }\s*\/1 { \/type "allow" \/glob "\*.html" }\s*}/
        )
      end
    end

    context 'invalidate_handler' do
      let :params do
        default_params.merge(:invalidate_handler  => '/path/to/script')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
            /\/invalidateHandler "\/path\/to\/script"/
        )
      end
    end

    context 'propagate_synd_post' do
      let :params do
        default_params.merge(:propagate_synd_post  => 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/propagateSyndPost "1"\s*/
        )
      end
    end

    context 'retries' do
      let :params do
        default_params.merge(:retries  => 5)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/numberOfRetries "5"/
        )
      end
    end

    context 'retry_delay' do
      let :params do
        default_params.merge(:retry_delay  => 5)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/retryDelay "5"/
        )
      end
    end

    context 'renders options' do
      context 'all params' do
        let :params do
          default_params.merge(
            :renders  => {
              'hostname'       => 'publish.hostname.com',
              'port'           => 8080,
              'timeout'        => 600,
              'receiveTimeout' => 300,
              'ipv4'           => 0,
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/renders {\s*\/renderer0 {\s*\/hostname\s*"publish.hostname.com"\s*\/port\s"8080"\s*\/timeout\s*"600"\s*\/receiveTimeout\s*"300"\s*\/ipv4\s"0"\s*}/
          )
        end
      end
      context 'timeout' do
        let :params do
          default_params.merge(
            :renders  => {
              'hostname' => 'publish.hostname.com',
              'port'     => 8080,
              'timeout'  => 600,
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/renders {\s*\/renderer0 {\s*\/hostname\s*"publish.hostname.com"\s*\/port\s"8080"\s*\/timeout\s*"600"\s*}/
          )
        end
      end
      context 'receiveTimeout' do
        let :params do
          default_params.merge(
            :renders  => {
              'hostname'       => 'publish.hostname.com',
              'port'           => 8080,
              'receiveTimeout' => 600,
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/renders {\s*\/renderer0 {\s*\/hostname\s*"publish.hostname.com"\s*\/port\s"8080"\s*\/receiveTimeout\s*"600"\s*}/
          )
        end
      end
      context 'ipv4' do
        let :params do
          default_params.merge(
            :renders  => {
              'hostname' => 'publish.hostname.com',
              'port'     => 8080,
              'ipv4'     => 0,
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/renders {\s*\/renderer0 {\s*\/hostname\s*"publish.hostname.com"\s*\/port\s"8080"\s*\/ipv4\s*"0"\s*}/
          )
        end
      end
      context 'multiple renderers' do
        let :params do
          default_params.merge(
            :renders  => [
              {
                'hostname' => 'publish.hostname.com',
                'port'     => 8080,
                'timeout'  => 600,
              },
              {
                'hostname' => 'another.hostname.com',
                'port'     => 8888,
                'timeout'  => 100,
              }
            ]
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/renderer0 {\s*\/hostname\s*"publish.hostname.com"\s*\/port\s"8080"\s*\/timeout\s*"600"\s*}/
          ).with_content(
            /\/renderer1 {\s*\/hostname\s*"another.hostname.com"\s*\/port\s"8888"\s*\/timeout\s*"100"\s*}/
          )
        end
      end
    end

    context 'serve_stale' do
      let :params do
        default_params.merge(:serve_stale  => 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/serveStaleOnError "1"\s*/
        )
      end
    end

    context 'session management options' do
      context 'directory only' do
        let :params do
          default_params.merge(
            :session_management  => {
              'directory' => '/path/to/cache'
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/sessionmanagement {\s*\/directory\s*"\/path\/to\/cache"\s*}/
          )
        end
      end
      context 'encode' do
        let :params do
          default_params.merge(
            :session_management  => {
              'directory' => '/path/to/cache',
              'encode'    => 'md5'
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/sessionmanagement {\s*\/directory\s*"\/path\/to\/cache"\s*\/encode\s"md5"\s*}/
          )
        end
      end
      context 'header' do
        let :params do 
          default_params.merge(
            :session_management  => {
              'directory' => '/path/to/cache',
              'header'    => 'HTTP:authorization'
            }
          )
        end
        it { is_expected.to compile }
        it do 
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/sessionmanagement {\s*\/directory\s*"\/path\/to\/cache"\s*\/header\s"HTTP:authorization"\s*}/
          )
        end
      end
      context 'timeout' do
        let :params do 
          default_params.merge(
            :session_management  => {
              'directory' => '/path/to/cache',
              'timeout'   => 1000
            }
          )
        end
        it { is_expected.to compile }
        it do 
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/sessionmanagement {\s*\/directory\s*"\/path\/to\/cache"\s*\/timeout\s"1000"\s*}/
          )
        end
      end
      context 'all params' do
        let :params do 
          default_params.merge(
            :session_management  => {
              'directory' => '/path/to/cache',
              'encode'    => 'md5',
              'header'    => 'HTTP:authorization',
              'timeout'   => 1000
            }
          )
        end
        it { is_expected.to compile }
        it do 
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/sessionmanagement {\s*\/directory\s*"\/path\/to\/cache"\s*\/encode\s"md5"\s*\/header\s"HTTP:authorization"\s*\/timeout\s"1000"\s*}/
          )
        end
      end
    end

    context 'stat_file' do
      let :params do
        default_params.merge(:stat_file => "/path/to/statfile")
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/statfile "\/path\/to\/statfile"/
        )
      end
    end

    context 'stat_files_level' do
      let :params do
        default_params.merge(:stat_files_level => 3)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/statfileslevel "3"/
        )
      end
    end

    context 'statistics' do
      let :params do
        default_params.merge(
          :statistics => [
            { 'glob' => '*.html', 'category' => 'html' },
            { 'glob' => '*', 'category' => 'others' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/statistics {\s*\/categories {\s*\/html { \/glob "\*.html" }\s*\/others { \/glob "\*" }\s*}\s*}/
        )
      end
    end

    context 'sticky_connections' do
      context 'single string' do
        let :params do
          default_params.merge(:sticky_connections => '/path/to/content')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/stickyConnectionsFor "\/path\/to\/content"/
          )
        end
      end
      context 'list of strings' do
        let :params do
          default_params.merge(:sticky_connections => ['/path/to/content', '/another/path/to/content'])
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
          ).with_content(
            /\/stickyConnections {\s* \/paths {\s*"\/path\/to\/content"\s*"\/another\/path\/to\/content"\s*}\s*}/
          )
        end
      end
    end

    context 'unavailable_penalty' do
      let :params do
        default_params.merge(:unavailable_penalty => 3)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/unavailablePenalty "3"/
        )
      end
    end

    context 'vanity_urls' do
      let :params do
        default_params.merge(
          :vanity_urls => {
            'file' => '/path/to/cache',
            'delay' => 600, 
          }
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/vanity_urls {\s*\/url "\/libs\/granite\/dispatcher\/content\/vanityUrls.html"\s*\/file "\/path\/to\/cache"\s*\/delay "600"\s*}/
        )
      end
    end

    context 'virtualhosts' do
      let :params do
        default_params.merge(:virtualhosts => [ 'www.avirtualhost.com', 'another.virtual.com' ])
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.aem-site.any'
        ).with_content(
          /\/virtualhosts {\s*"www.avirtualhost.com"\s*"another.virtual.com"\s*}/
        )
      end
    end
  end

end
