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

  describe 'ordered hashes' do
    let(:facts) { default_facts }

    context 'allowed_clients' do
      let(:params) do
        default_params.merge(
          allowed_clients: [
            { 'rank' => 100, 'glob' => '10.200.1.1', 'type' => 'allow' },
            { 'glob' => '*', 'type' => 'deny' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/allowedClients {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "10.200.1.1" }\s*}|
        )
      end
    end

    context 'cache_rules' do
      let(:params) do
        default_params.merge(
          cache_rules: [
            { 'rank' => 200, 'glob' => '*.html', 'type' => 'allow' },
            { 'glob' => '*', 'type' => 'deny' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/rules {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "\*.html" }|
        )
      end
    end

    context 'auth_checker' do
      context 'filter rile ranking' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url'     => '/bin/permissioncheck',
              'filter'  => [
                { 'rank' => 100, 'type' => 'allow', 'glob' => '/content/secure/*.html' },
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
            %r|/filter {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "/content/secure/\*.html" }\s*}|
          )
        end
      end

      context 'headers rule ranking' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url'     => '/bin/permissioncheck',
              'filter'  => [
                { 'type' => 'deny', 'glob' => '*' }
              ],
              'headers' => [
                { 'rank' => 100, 'type' => 'allow', 'glob' => 'Set-Cookie:*' },
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
            %r|/headers {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "Set-Cookie:\*" }\s*}|
          )
        end
      end
    end

    context 'filter' do
      let(:params) do
        default_params.merge(
          filters: [
            { 'rank' => 10, 'type' => 'allow', 'glob' => '/content*' },
            { 'type' => 'deny', 'glob' => '*' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/filter {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "/content\*" }|
        )
      end
    end

    context 'ignore_parameters' do
      let(:params) do
        default_params.merge(
          ignore_parameters: [
            { 'rank' => 1, 'glob' => 'param=*', 'type' => 'allow' },
            { 'glob' => '*', 'type' => 'deny' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/ignoreUrlParams {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "param=\*" }\s*}|
        )
      end
    end

    context 'invalidate' do
      let(:params) do
        default_params.merge(
          invalidate: [
            { 'rank' => 1000, 'glob' => '*.html', 'type' => 'allow' },
            { 'glob' => '*', 'type' => 'deny' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/invalidate {\s*/000 { /type "deny" /glob "\*" }\s*/001 { /type "allow" /glob "\*.html" }\s*|
        )
      end
    end

    context 'statistics' do
      let(:params) do
        default_params.merge(
          statistics: [
            { 'rank' => 2, 'glob' => '*', 'category' => 'others' },
            { 'glob' => '*.html', 'category' => 'html' }
          ]
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_file(
          '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
        ).with_content(
          %r|/statistics {\s*/categories {\s*/html { /glob "\*.html" }\s*/others { /glob "\*" }\s*}\s*}|
        )
      end
    end
  end
end
