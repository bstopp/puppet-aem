require 'spec_helper'

# Tests for parameters defaults and validation
describe 'aem::dispatcher::farm', type: :define do

  let(:pre_condition) do
    '
    class { "apache": default_vhost => false, default_mods => false, vhost_enable_dir => "/etc/apache2/sites-enabled"}
    class { aem::dispatcher : module_file => "/tmp/module.so" }
    '
  end

  let(:default_params) do
    {
      docroot: '/path/to/docroot'
    }
  end

  let(:title) do
    'aem-site'
  end

  let(:default_facts) do
    {
      osfamily: 'RedHat',
      operatingsystemrelease: '7.1.1503',
      operatingsystem: 'CentOS',
      concat_basedir: '/dne',
      id: 'root',
      kernel: 'Linux',
      path: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    }
  end

  describe 'default parameters' do
    let(:facts) { default_facts }
    let(:params) { default_params }

    it { is_expected.to compile }
    it do
      is_expected.to contain_file(
        '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
      ).with(
        ensure: 'present'
      ).with_content(
        %r|/aem-site {|
      ).without_content(
        /allowAuthorized/
      ).with_content(
        %r|/allowedClients {\s*/0 { /type "allow" /glob "\*" }\s*}|
      ).with_content(
        %r|/clientheaders {\s*"\*"\s*}|
      ).with_content(
        %r|/docroot \s*"/path/to/docroot"\s*|
      ).without_content(
        /enableTTL/
      ).without_content(
        /gracePeriod/
      ).without_content(
        /auth_checker/
      ).without_content(
        %r|/headers|
      ).without_content(
        /failover/
      ).without_content(
        /health_check/
      ).without_content(
        /ignoreUrlParameters/
      ).with_content(
        %r|/invalidate {\s*/0 \{ /type "allow" /glob "\*" }|
      ).without_content(
        /invalidateHandler/
      ).with_content(
        %r|/filter {\s*/0 { /type "allow" /glob "\*" }|
      ).without_content(
        /numberOfRetries/
      ).with_content(
        %r|/renders {\s*/renderer0 {\s*/hostname "localhost"\s*/port "4503"\s*}|
      ).without_content(
        /retryDelay/
      ).with_content(
        %r|/rules {\s*/0 { /type "deny" /glob "\*" }|
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
        %r|/virtualhosts {\s*"\*"\s*}|
      )
    end
  end

  describe 'specify parameters' do
    let(:facts) { default_facts }

    context 'allow_authorized' do
      let(:params) do
        default_params.merge(allow_authorized: 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/allowAuthorized "1"|
        )
      end
    end

    context 'allowed_clients' do
      let(:params) do
        default_params.merge(allowed_clients: { 'glob' => '10.200.1.1', 'type' => 'allow' })
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/allowedClients {\s*/0 { /type "allow" /glob "10.200.1.1" }\s*}|
        )
      end
    end

    context 'cache_headers' do
      let(:params) do
        default_params.merge(cache_headers: ['New-Cache-Header', 'Another-Cache-Header'])
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/headers {\s*"New-Cache-Header"\s*"Another-Cache-Header"\s*}|
        )
      end
    end

    context 'cache_rules' do
      let(:params) do
        default_params.merge(
          cache_rules: [
            { 'glob' => '*', 'type' => 'deny' },
            { 'glob' => '*.html', 'type' => 'allow' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/rules {\s*/0 { /type "deny" /glob "\*" }\s*/1 { /type "allow" /glob "\*.html" }|
        )
      end
    end

    context 'cache_ttl' do
      let(:params) do
        default_params.merge(cache_ttl: 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/enableTTL "1"\s*|
        )
      end
    end

    context 'auth_checker' do
      let(:params) do
        default_params.merge(
          auth_checker: {
            'url'     => '/bin/permissioncheck',
            'filter'  => [
              { 'type' => 'deny', 'glob' => '*' }
            ],
            'headers' => [
              { 'type' => 'deny', 'glob' => '*' }
            ]
          }
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|
            /auth_checker\s{\s*
              /url\s"/bin/permissioncheck"\s*
              /filter\s{\s*
                /0\s{\s/type\s"deny"\s/glob\s"\*"\s}\s*
              }\s*
              /headers\s{\s*
                /0\s{\s/type\s"deny"\s/glob\s"\*"\s}\s*
              }\s*
            }
          |x
        )
      end
    end

    context 'client_headers' do
      let(:params) do
        default_params.merge(client_headers: ['New-Client-Header', 'Another-New-Header'])
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/clientheaders {\s*"New-Client-Header"\s*"Another-New-Header"\s*}|
        )
      end
    end

    context 'failover' do
      let(:params) do
        default_params.merge(failover: 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/failover "1"\s*|
        )
      end
    end

    context 'filter' do
      context 'filter glob' do
        let(:params) do
          default_params.merge(filters: { 'type' => 'deny', 'glob' => '/content*' })
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/filter {\s*/0 { /type "deny" /glob "/content\*" }|
          )
        end
      end
      context 'filter method/url/query/protocol' do
        context 'all request line values' do
          let(:params) do
            default_params.merge(
              filters: {
                'type'      => 'allow',
                'method'    => 'GET',
                'url'       => '/path/to/content',
                'query'     => 'param=*',
                'protocol'  => 'https',
                'path'      => '/different/path/to/content',
                'selectors' => '((sys|doc)view|query|[0-9-]+)',
                'extension' => '(css|gif|ico|js|png|swf|jpe?g)',
                'suffix'    => '/suffix/path'
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
            ).with_content(
              %r|
                /0\s{\s*
                  /type\s"allow"\s*
                  /method\s"GET"\s*
                  /url\s"/path/to/content"\s*
                  /query\s"param=\*"\s*
                  /protocol\s"https"\s*
                  /path\s"/different/path/to/content"\s*
                  /selectors\s'\(\(sys\|doc\)view\|query\|\[0-9-\]\+\)'\s*
                  /extension\s'\(css\|gif\|ico\|js\|png\|swf\|jpe\?g\)'\s*
                  /suffix\s\'/suffix/path\'\s*
                }
              |x
            )
          end
        end

        context 'method only' do
          let(:params) do
            default_params.merge(
              filters: {
                'type'   => 'allow',
                'method' => 'GET'
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
            ).with_content(
              %r|/0 {\s*/type\s*"allow"\s*/method\s*"GET"\s*}|
            )
          end
        end

        context 'url value' do
          let(:params) do
            default_params.merge(
              filters: {
                'type' => 'allow',
                'url'  => '/path/to/content'
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
            ).with_content(
              %r|/0 {\s*/type\s*"allow"\s*/url\s*"/path/to/content"\s*}|
            )
          end
        end

        context 'query' do
          let(:params) do
            default_params.merge(
              filters: {
                'type'     => 'allow',
                'query'    => 'param=*'
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
            ).with_content(
              %r|/0 {\s*/type\s*"allow"\s*/query\s*"param=\*"\s*}|
            )
          end
        end

        context 'protocol' do
          let(:params) do
            default_params.merge(
              filters: {
                'type'     => 'allow',
                'protocol' => 'https'
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
            ).with_content(
              %r|/0 {\s*/type\s*"allow"\s*/protocol\s"https"\s*}|
            )
          end
        end
      end
    end

    context 'grace_period' do
      let(:params) do
        default_params.merge(grace_period: 5)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/gracePeriod "5"\s*|
        )
      end
    end

    context 'health_check_url' do
      let(:params) do
        default_params.merge(health_check_url: '/health/check/url.html')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/health_check { /url "/health/check/url.html" }|
        )
      end
    end

    context 'ignore_parameters' do
      let(:params) do
        default_params.merge(
          ignore_parameters: [
            { 'glob' => '*', 'type' => 'deny' },
            { 'glob' => 'param=*', 'type' => 'allow' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/ignoreUrlParams {\s*/0 { /type "deny" /glob "\*" }\s*/1 { /type "allow" /glob "param=\*" }\s*}|
        )
      end
    end

    context 'invalidate' do
      let(:params) do
        default_params.merge(
          invalidate: [
            { 'glob' => '*', 'type' => 'deny' },
            { 'glob' => '*.html', 'type' => 'allow' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/invalidate {\s*/0 { /type "deny" /glob "\*" }\s*/1 { /type "allow" /glob "\*.html" }\s*}|
        )
      end
    end

    context 'invalidate_handler' do
      let(:params) do
        default_params.merge(
          invalidate: :undef,
          invalidate_handler: '/path/to/script'
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/invalidateHandler "/path/to/script"|
        ).without_content(
          %r|/invalidate |
        )
      end
    end

    context 'priority' do
      context 'priotity 1' do
        let(:params) do
          default_params.merge(priority: 1)
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.01-aem-site.inc.any'
          )
        end
      end
      context 'priotity 10' do
        let(:params) do
          default_params.merge(priority: 10)
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.10-aem-site.inc.any'
          )
        end
      end
    end

    context 'propagate_synd_post' do
      let(:params) do
        default_params.merge(propagate_synd_post: 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/propagateSyndPost "1"\s*|
        )
      end
    end

    context 'retries' do
      let(:params) do
        default_params.merge(retries: 5)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/numberOfRetries "5"|
        )
      end
    end

    context 'retry_delay' do
      let(:params) do
        default_params.merge(retry_delay: 5)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/retryDelay "5"|
        )
      end
    end

    context 'renders options' do
      context 'all params' do
        let(:params) do
          default_params.merge(
            renders: {
              'hostname'       => 'publish.hostname.com',
              'port'           => 8080,
              'timeout'        => 600,
              'receiveTimeout' => 300,
              'ipv4'           => 0,
              'secure'         => 0

            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|
              /renders\s{\s*
                /renderer0\s{\s*
                  /hostname\s*"publish.hostname.com"\s*
                  /port\s"8080"\s*
                  /timeout\s*"600"\s*
                  /receiveTimeout\s*"300"\s*
                  /ipv4\s"0"\s*
                  /secure\s"0"\s*
                }\s*
              }
            |x
          )
        end
      end
      context 'timeout' do
        let(:params) do
          default_params.merge(
            renders: {
              'hostname' => 'publish.hostname.com',
              'port'     => 8080,
              'timeout'  => 600
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/renders {\s*/renderer0 {\s*/hostname\s*"publish.hostname.com"\s*/port\s"8080"\s*/timeout\s*"600"\s*}|
          )
        end
      end
      context 'receiveTimeout' do
        let(:params) do
          default_params.merge(
            renders: {
              'hostname'       => 'publish.hostname.com',
              'port'           => 8080,
              'receiveTimeout' => 600
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|
              /renders\s{\s*
                /renderer0\s{\s*
                  /hostname\s*"publish.hostname.com"\s*
                  /port\s"8080"\s*
                  /receiveTimeout\s*"600"\s*
                }\s*
              }
            |x
          )
        end
      end
      context 'ipv4' do
        let(:params) do
          default_params.merge(
            renders: {
              'hostname' => 'publish.hostname.com',
              'port'     => 8080,
              'ipv4'     => 0
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/renders {\s*/renderer0 {\s*/hostname\s*"publish.hostname.com"\s*/port\s"8080"\s*/ipv4\s*"0"\s*}|
          )
        end
      end
      context 'secure' do
        let(:params) do
          default_params.merge(
            renders: {
              'hostname' => 'publish.hostname.com',
              'port'     => 8080,
              'secure'   => 0
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/renders {\s*/renderer0 {\s*/hostname\s*"publish.hostname.com"\s*/port\s"8080"\s*/secure\s*"0"\s*}|
          )
        end
      end
      context 'multiple renderers' do
        let(:params) do
          default_params.merge(
            renders: [
              {
                'hostname' => 'publish.hostname.com',
                'port'     => 8080,
                'timeout'  => 600
              },
              {
                'hostname' => 'another.hostname.com',
                'port'     => 8888,
                'timeout'  => 100
              }
            ]
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/renderer0 {\s*/hostname\s*"publish.hostname.com"\s*/port\s"8080"\s*/timeout\s*"600"\s*}|
          ).with_content(
            %r|/renderer1 {\s*/hostname\s*"another.hostname.com"\s*/port\s"8888"\s*/timeout\s*"100"\s*}|
          )
        end
      end
    end

    context 'serve_stale' do
      let(:params) do
        default_params.merge(serve_stale: 1)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/serveStaleOnError "1"\s*|
        )
      end
    end

    context 'session management options' do

      context 'directory only' do
        let(:params) do
          default_params.merge(
            session_management: {
              'directory' => '/path/to/cache'
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/sessionmanagement {\s*/directory\s*"/path/to/cache"\s*}|
          )
        end
      end

      context 'encode' do
        let(:params) do
          default_params.merge(
            session_management: {
              'directory' => '/path/to/cache',
              'encode'    => 'md5'
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/sessionmanagement {\s*/directory\s*"/path/to/cache"\s*/encode\s"md5"\s*}|
          )
        end
      end

      context 'header' do
        let(:params) do
          default_params.merge(
            session_management: {
              'directory' => '/path/to/cache',
              'header'    => 'HTTP:authorization'
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/sessionmanagement {\s*/directory\s*"/path/to/cache"\s*/header\s"HTTP:authorization"\s*}|
          )
        end
      end

      context 'timeout' do
        let(:params) do
          default_params.merge(
            session_management: {
              'directory' => '/path/to/cache',
              'timeout'   => 1000
            }
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/sessionmanagement {\s*/directory\s*"/path/to/cache"\s*/timeout\s"1000"\s*}|
          )
        end
      end

      context 'all params' do
        let(:params) do
          default_params.merge(
            session_management: {
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
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|
              /sessionmanagement\s{\s*
                /directory\s*"/path/to/cache"\s*
                /encode\s"md5"\s*
                /header\s"HTTP:authorization"\s*
                /timeout\s"1000"\s*
              }
            |x
          )
        end
      end
    end

    context 'stat_file' do
      let(:params) do
        default_params.merge(stat_file: '/path/to/statfile')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|
            /statfile\s"/path/to/statfile"
          |x
        )
      end
    end

    context 'stat_files_level' do
      let(:params) do
        default_params.merge(stat_files_level: 3)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/statfileslevel "3"|
        )
      end
    end

    context 'statistics' do
      let(:params) do
        default_params.merge(
          statistics: [
            { 'glob' => '*.html', 'category' => 'html' },
            { 'glob' => '*', 'category' => 'others' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|
            /statistics\s{\s*
              /categories\s{\s*
                /html\s{\s/glob\s"\*.html"\s}\s*
                /others\s{\s/glob\s"\*"\s}\s*
              }\s*
            }
          |x
        )
      end
    end

    context 'sticky_connections' do
      context 'single string' do
        let(:params) do
          default_params.merge(sticky_connections: '/path/to/content')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|/stickyConnectionsFor "/path/to/content"|
          )
        end
      end
      context 'list of strings' do
        let(:params) do
          default_params.merge(sticky_connections: ['/path/to/content', '/another/path/to/content'])
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with_content(
            %r|
              /stickyConnections\s{\s*\s
                /paths\s{\s*
                  "/path/to/content"\s*
                  "/another/path/to/content"\s*
                }\s*
              }
            |x
          )
        end
      end
    end

    context 'unavailable_penalty' do
      let(:params) do
        default_params.merge(unavailable_penalty: 3)
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/unavailablePenalty "3"|
        )
      end
    end

    context 'vanity_urls' do
      let(:params) do
        default_params.merge(
          vanity_urls: {
            'file' => '/path/to/cache',
            'delay' => 600
          }
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|
            /vanity_urls\s{\s*
              /url\s"/libs/granite/dispatcher/content/vanityUrls.html"\s*
              /file\s"/path/to/cache"\s*
              /delay\s"600"\s*
            }
          |x
        )
      end
    end

    context 'virtualhosts' do
      let(:params) do
        default_params.merge(virtualhosts: %w[www.avirtualhost.com another.virtual.com])
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|
            /virtualhosts\s{\s*"www.avirtualhost.com"\s*"another.virtual.com"\s*}
          |x
        )
      end
    end
  end

end
