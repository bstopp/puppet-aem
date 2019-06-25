# frozen_string_literal: true

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

  describe 'parameter validation' do
    let(:facts) { default_facts }
    context 'ensure' do
      context 'absent' do
        let(:params) do
          default_params.merge(ensure: 'absent')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_file(
            '/etc/httpd/conf.modules.d/dispatcher.00-aem-site.inc.any'
          ).with('ensure' => 'absent')
        end
      end
      context 'invalid' do
        let(:params) do
          default_params.merge(ensure: 'invalid')
        end
        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'allow_authorized' do
      context 'should accept 0' do
        let(:params) do
          default_params.merge(allow_authorized: '0')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 1' do
        let(:params) do
          default_params.merge(allow_authorized: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any other positive value' do
        let(:params) do
          default_params.merge(allow_authorized: '2')
        end
        it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(allow_authorized: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'allowed_clients' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(allowed_clients: { 'glob' => '*', 'type' => 'allow' })
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            allowed_clients: [
              { 'glob' => '*', 'type' => 'deny' },
              { 'glob' => 'localhost', 'type' => 'allow' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(allowed_clients: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(allowed_clients: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should require a value' do
        let(:params) do
          default_params.merge(allowed_clients: nil)
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'cache_headers' do
      context 'should accept a single value' do
        let(:params) do
          default_params.merge(cache_headers: 'A-Cache-Header')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of values' do
        let(:params) do
          default_params.merge(cache_headers: ['A-Cache-Header', 'Another-Cache-Header'])
        end
        it { is_expected.to compile.with_all_deps }
      end
    end

    context 'cache_rules' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(cache_rules: { 'glob' => '*', 'type' => 'deny' })
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            cache_rules: [
              { 'glob' => '*', 'type' => 'deny' },
              { 'glob' => '*.html', 'type' => 'allow' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(cache_rules: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(cache_rules: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should require a value' do
        let(:params) do
          default_params.merge(cache_rules: nil)
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'auth_checker' do
      context 'should compile' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'filter' => [
                { 'type' => 'deny', 'glob' => '*' }
              ],
              'headers' => [
                { 'type' => 'deny', 'glob' => '*' }
              ]
            }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should require a url' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'filter' => [
                { 'type' => 'deny', 'glob' => '*' }
              ],
              'headers' => [
                { 'type' => 'deny', 'glob' => '*' }
              ]
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/.*url is not specified./) }
      end
      context 'should require a filter element' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'headers' => [
                { 'type' => 'deny', 'glob' => '*' }
              ]
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/.*filter are not specified./) }
      end
      context 'should require the filter element to be an array' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'filter' => { 'type' => 'deny', 'glob' => '*' },
              'headers' => [
                { 'type' => 'deny', 'glob' => '*' }
              ]
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/.*must be an array./) }
      end
      context 'should require the filter element to be an array of hashes' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'filter' => ['not a hash', 'another non hash'],
              'headers' => [
                { 'type' => 'deny', 'glob' => '*' }
              ]
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should require a headers element' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'filter' => [
                { 'type' => 'deny', 'glob' => '*' }
              ]
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/.*headers are not specified./) }
      end
      context 'should require the headers element to be an array' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'filter' => [
                { 'type' => 'deny', 'glob' => '*' }
              ],
              'headers' => { 'type' => 'deny', 'glob' => '*' }
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/.*must be an array./) }
      end
      context 'should require the headers element to be an array of hashes' do
        let(:params) do
          default_params.merge(
            auth_checker: {
              'url' => '/bin/permissioncheck',
              'filter' => [
                { 'type' => 'deny', 'glob' => '*' }
              ],
              'headers' => ['not a hash', 'another non hash']
            }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'cache_ttl' do
      context 'should accept 0' do
        let(:params) do
          default_params.merge(cache_ttl: '0')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 1' do
        let(:params) do
          default_params.merge(cache_ttl: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any other positive value' do
        let(:params) do
          default_params.merge(cache_ttl: '2')
        end
        it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(cache_ttl: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'client_headers' do
      context 'should accept a single value' do
        let(:params) do
          default_params.merge(client_headers: 'A-Client-Header')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of values' do
        let(:params) do
          default_params.merge(client_headers: ['A-Client-Header', 'Another-Client-Header'])
        end
        it { is_expected.to compile.with_all_deps }
      end
    end

    context 'docroot' do
      context 'should be required' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:docroot)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/an absolute path/) }
      end
      context 'should be an absolute path' do
        let(:params) do
          default_params.merge(docroot: 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/an absolute path/) }
      end
    end

    context 'failover' do
      context 'should accept 0' do
        let(:params) do
          default_params.merge(failover: '0')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 1' do
        let(:params) do
          default_params.merge(failover: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any other positive value' do
        let(:params) do
          default_params.merge(failover: '2')
        end
        it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(failover: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'filters' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(
            filters: { 'glob' => '* /content*', 'type' => 'allow' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            filters: [
              { 'glob' => '*', 'type' => 'deny' },
              { 'glob' => '* /content*', 'type' => 'allow' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(filters: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(filters: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should require a value' do
        let(:params) do
          default_params.merge(filters: nil)
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'grace_period' do
      context 'should not accept 0' do
        let(:params) do
          default_params.merge(grace_period: '0')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
      context 'should accept positive value' do
        let(:params) do
          default_params.merge(grace_period: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(grace_period: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'health_check_url' do
      context 'should accept a string' do
        let(:params) do
          default_params.merge(health_check_url: '/health/check/url.html')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept anything else' do
        let(:params) do
          default_params.merge(health_check_url: ['not', 'a', 'string'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a string/i) }
      end
    end

    context 'ignore_parameters' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(
            ignore_parameters: { 'glob' => 'param=*', 'type' => 'allow' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            ignore_parameters: [
              { 'glob' => '*', 'type' => 'deny' },
              { 'glob' => 'param=*', 'type' => 'allow' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(ignore_parameters: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(ignore_parameters: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should require a value' do
        let(:params) do
          default_params.merge(ignore_parameters: nil)
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'invalidate' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(
            invalidate: { 'glob' => '*.html', 'type' => 'allow' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end

      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(
            invalidate: { 'glob' => '*.html', 'type' => 'allow' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            invalidate: [
              { 'glob' => '*', 'type' => 'deny' },
              { 'glob' => '*.html', 'type' => 'allow' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(invalidate: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(invalidate: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should require a value' do
        let(:params) do
          default_params.merge(invalidate: nil)
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'invalidate_handler' do
      context 'should be an absolute path' do
        let(:params) do
          default_params.merge(
            invalidate: :undef,
            invalidate_handler: 'not/absolute/path'
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/an absolute path/) }
      end
    end

    context 'priority' do
      context 'should accept undef' do
        let(:params) do
          default_params.merge(priority: :undef)
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 0' do
        let(:params) do
          default_params.merge(priority: 0)
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 1' do
        let(:params) do
          default_params.merge(priority: 1)
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 99' do
        let(:params) do
          default_params.merge(priority: 99)
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept 100' do
        let(:params) do
          default_params.merge(priority: 100)
        end
        it { expect { is_expected.to compile }.to raise_error(/Expected 100 to be smaller or equal to 99, got 100/) }
      end
      context 'should not accept 101' do
        let(:params) do
          default_params.merge(priority: 101)
        end
        it { expect { is_expected.to compile }.to raise_error(/Expected 101 to be smaller or equal to 99, got 101/) }
      end
      context 'should not accept negative priorities' do
        let(:params) do
          default_params.merge(priority: -1)
        end
        it { expect { is_expected.to compile }.to raise_error(/Expected -1 to be greater or equal to 0, got -1/) }
      end
      context 'should not accept strings' do
        let(:params) do
          default_params.merge(priority: '0')
        end
        it { expect { is_expected.to compile }.to raise_error(/Priority should be a valid Integer/) }
      end
    end

    context 'propagate_synd_post' do
      context 'should accept 0' do
        let(:params) do
          default_params.merge(propagate_synd_post: '0')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 1' do
        let(:params) do
          default_params.merge(propagate_synd_post: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any other positive value' do
        let(:params) do
          default_params.merge(propagate_synd_post: '2')
        end
        it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(propagate_synd_post: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'renders' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(
            renders: { 'hostname' => 'publish.renderer.com', 'port' => '8080' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            renders: [
              { 'hostname' => 'publish.renderer.com', 'port' => '8080' },
              { 'hostname' => 'another.renderer.com', 'port' => '8080' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(renders: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(renders: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'retries' do
      context 'should not accept 0' do
        let(:params) do
          default_params.merge(retries: '0')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
      context 'should accept positive value' do
        let(:params) do
          default_params.merge(retries: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(retries: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'retry_delay' do
      context 'should not accept 0' do
        let(:params) do
          default_params.merge(retry_delay: '0')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
      context 'should accept positive value' do
        let(:params) do
          default_params.merge(retry_delay: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(retry_delay: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'serve_stale' do
      context 'should accept 0' do
        let(:params) do
          default_params.merge(serve_stale: '0')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept 1' do
        let(:params) do
          default_params.merge(serve_stale: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any other positive value' do
        let(:params) do
          default_params.merge(serve_stale: '2')
        end
        it { expect { is_expected.to compile }.to raise_error(/smaller or equal/) }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(serve_stale: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'session_management' do
      context 'should accept a hash' do
        let(:params) do
          default_params.merge(session_management: { 'directory' => '/directory/to/cache' })
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept a string' do
        let(:params) do
          default_params.merge(session_management: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should not accept an array' do
        let(:params) do
          default_params.merge(session_management: ['array', 'of', 'values'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'mutually exclusive with allow authorized' do
        let(:params) do
          default_params.merge(
            session_management: ['array', 'of', 'values'],
            allow_authorized: 1
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/mutually exclusive/i) }
      end
      context 'should require directory key' do
        let(:params) do
          default_params.merge(
            session_management: { 'not_directory' => 'a value' }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/directory is not specified/i) }
      end
      context 'should require directory key to be absolute path' do
        let(:params) do
          default_params.merge(
            session_management: { 'directory' => 'not/absolute/path' }
          )
        end
        it { expect { is_expected.to compile }.to raise_error(/not an absolute path/i) }
      end
      context 'should accept directory with absolute path' do
        let(:params) do
          default_params.merge(
            session_management: { 'directory' => '/an/absolute/path' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'encode' do
        context 'should accept md5' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'encode' => 'md5'
              }
            )
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should accept hex' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'encode' => 'hex'
              }
            )
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should not accept any other value' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'encode' => 'invalid'
              }
            )
          end
          it { expect { is_expected.to compile }.to raise_error(/not supported for session_management\['encode'\]/) }
        end
      end
      context 'header' do
        context 'should accept a value' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'header' => 'Any Value is OK'
              }
            )
          end
          it { is_expected.to compile.with_all_deps }
        end
      end
      context 'timeout' do
        context 'should accept any integer' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'timeout' => 500
              }
            )
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should not accept any negative value' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'timeout' => -1
              }
            )
          end
          it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
        end
        context 'should not accept anything else' do
          let(:params) do
            default_params.merge(
              session_management: {
                'directory' => '/path',
                'timeout' => 'not an integer'
              }
            )
          end
          it { expect { is_expected.to compile }.to raise_error(/first argument to be an Integer/) }
        end
      end
    end

    context 'stat_file' do
      context 'should be an absolute path' do
        let(:params) do
          default_params.merge(stat_file: 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/an absolute path/) }
      end
    end

    context 'stat_files_level' do
      context 'should accept 0' do
        let(:params) do
          default_params.merge(stat_files_level: 0)
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept positive' do
        let(:params) do
          default_params.merge(stat_files_level: 4)
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(stat_files_level: -1)
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
      context 'allows blank' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:stat_files_level)
          tmp
        end
        it { is_expected.to compile.with_all_deps }
      end
    end

    context 'statistics' do
      context 'should accept a single hash' do
        let(:params) do
          default_params.merge(
            statistics: { 'glob' => '*.html', 'category' => 'html' }
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of hashes' do
        let(:params) do
          default_params.merge(
            statistics: [
              { 'glob' => '*.html', 'category' => 'html' },
              { 'glob' => '*', 'category' => 'others' }
            ]
          )
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'require single value be a hash' do
        let(:params) do
          default_params.merge(statistics: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'require arrays contain a hash' do
        let(:params) do
          default_params.merge(statistics: ['not a hash', 'another non hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
    end

    context 'sticky_connections' do
      context 'should accept a single value' do
        let(:params) do
          default_params.merge(sticky_connections: '/path/to/content')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of values' do
        let(:params) do
          default_params.merge(sticky_connections: ['/content/path', '/content/dam/path'])
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should only be strings - single value' do
        let(:params) do
          default_params.merge(sticky_connections: { 'not' => 'string' })
        end
        it { expect { is_expected.to compile }.to raise_error(/not a string/i) }
      end
      context 'should only be strings - array value' do
        let(:params) do
          default_params.merge(sticky_connections: [{ 'not' => 'string' }, { 'another' => 'not string' }])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a string/i) }
      end
    end

    context 'unavailable_penalty' do
      context 'should not accept 0' do
        let(:params) do
          default_params.merge(unavailable_penalty: '0')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
      context 'should accept positive value' do
        let(:params) do
          default_params.merge(unavailable_penalty: '1')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept any negative value' do
        let(:params) do
          default_params.merge(unavailable_penalty: '-1')
        end
        it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
      end
    end

    context 'vanity urls' do
      context 'should accept a hash' do
        let(:params) do
          default_params.merge(vanity_urls: { 'file' => '/path/to/cache', 'delay' => 600 })
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should not accept a string' do
        let(:params) do
          default_params.merge(vanity_urls: 'not a hash')
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'should not accept an array' do
        let(:params) do
          default_params.merge(vanity_urls: ['array', 'of', 'values'])
        end
        it { expect { is_expected.to compile }.to raise_error(/not a hash/i) }
      end
      context 'file param' do
        context 'should be require' do
          let(:params) do
            default_params.merge(
              vanity_urls: { 'not_file' => 'a value' }
            )
          end
          it { expect { is_expected.to compile }.to raise_error(/cache file is not specified/i) }
        end
        context 'should be an absolute path' do
          let(:params) do
            default_params.merge(
              vanity_urls: { 'file' => 'not/absolute/path' }
            )
          end
          it { expect { is_expected.to compile }.to raise_error(/not an absolute path/i) }
        end
        context 'should accept an absolute path' do
          let(:params) do
            default_params.merge(
              vanity_urls: { 'file' => '/an/absolute/path', 'delay' => 1000 }
            )
          end
          it { is_expected.to compile.with_all_deps }
        end
      end
      context 'delay' do
        context 'should accept any integer' do
          let(:params) do
            default_params.merge(vanity_urls: { 'file' => '/path', 'delay' => 500 })
          end
          it { is_expected.to compile.with_all_deps }
        end
        context 'should not accept any negative value' do
          let(:params) do
            default_params.merge(vanity_urls: { 'file' => '/path', 'delay' => -1 })
          end
          it { expect { is_expected.to compile }.to raise_error(/greater or equal/) }
        end
      end
    end

    context 'virtualhosts' do
      context 'should accept a single value' do
        let(:params) do
          default_params.merge(virtualhosts: 'www.domainname.com')
        end
        it { is_expected.to compile.with_all_deps }
      end
      context 'should accept an array of values' do
        let(:params) do
          default_params.merge(virtualhosts: ['www.domainname1.com', 'www.domainname2.com'])
        end
        it { is_expected.to compile.with_all_deps }
      end
    end
  end

end
