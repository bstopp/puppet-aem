require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::agent::replication', :type => :defines do

  let(:default_params) do
    {
      :ensure         => 'present',
      :home           => '/opt/aem',
      :name           => 'agentname',
      :password       => 'password',
      :resource_type  => 'cq/replication/components/agent',
      :runmode        => 'author',
      :serialize_type => 'durbo',
      :template       => '/libs/cq/replication/templates/agent',
      :username       => 'username'
    }
  end

  let(:title) do
    'Agent Title'
  end

  describe 'parameter validation' do
    context 'batch enabled' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:batch_enabled => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:batch_enabled => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:batch_enabled => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'batch max wait' do
      context 'is specified' do
        let(:params) { default_params.merge(:batch_max_wait => 60) }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:batch_max_wait => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'batch trigger size' do
      context 'is specified' do
        let(:params) { default_params.merge(:batch_trigger_size => 10) }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:batch_trigger_size => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'ensure' do
      context 'present' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'absent' do
        let(:params) { default_params.merge(:ensure => 'absent') }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:ensure => 'invalid') }
        it { is_expected.to raise_error(/not supported for ensure/) }
      end
    end

    context 'enabled' do
      context 'true' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:enabled => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:enabled => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'http headers' do
      context 'not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'an array' do
        let(:params) { default_params.merge(:protocol_http_headers => ['header1', 'header2']) }
        it { is_expected.to compile }
      end

      context 'not an array' do
        let(:params) { default_params.merge(:protocol_http_headers => 'not an array') }
        it { is_expected.to raise_error(/not an array/) }
      end
    end

    context 'home' do
      context 'specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

      context 'not absolute' do
        let(:params) do
          default_params.merge(:home => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end
    end

    context 'log level' do
      context 'debug' do
        let(:params) { default_params.merge(:log_level => 'debug') }
        it { is_expected.to compile }
      end

      context 'info' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'error' do
        let(:params) { default_params.merge(:log_level => 'error') }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:log_level => 'invalid') }
        it { is_expected.to raise_error(/not supported for log_level/) }
      end
    end

    context 'name' do
      context 'is not valid' do
        let(:params) { default_params.merge(:name => 'has a space') }
        it { is_expected.to raise_error(/only letters and numbers/) }
      end
    end

    context 'password' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:password)
          tmp
        end
        it { is_expected.to raise_error(/'password' must be specified/) }
      end
    end

    context 'protocol close connection' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:protocol_close_conn => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:protocol_close_conn => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:protocol_close_conn => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'protocol connection timeout' do
      context 'is specified' do
        let(:params) { default_params.merge(:protocol_conn_timeout => 10_000) }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:protocol_conn_timeout => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'protocol socket timeout' do
      context 'is specified' do
        let(:params) { default_params.merge(:protocol_sock_timeout => 10_000) }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:protocol_sock_timeout => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'proxy port' do
      context 'is specified' do
        let(:params) { default_params.merge(:proxy_port => 1002) }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:proxy_port => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'resource type' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:resource_type)
          tmp
        end
        it { is_expected.to raise_error(/'resource_type' must be specified/) }
      end
    end

    context 'retry delay' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:retry_delay)
          tmp
        end
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:retry_delay => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'reverse replication' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:reverse => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:reverse => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:reverse => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'runmode' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:runmode)
          tmp
        end
        it { is_expected.to raise_error(/'runmode' must be specified/) }
      end
    end


    context 'serialize type' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:serialize_type)
          tmp
        end
        it { is_expected.to raise_error(/'serialize_type' must be specified/) }
      end
    end

    context 'template' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:template)
          tmp
        end
        it { is_expected.to raise_error(/'template' must be specified/) }
      end
    end

    context 'timeout' do
      context 'is specified' do
        let(:params) { default_params.merge(:timeout => 60) }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not an integer' do
        let(:params) { default_params.merge(:timeout => 'not a number') }
        it { is_expected.to raise_error(/first argument to be an Integer/) }
      end
    end

    context 'transport allow expired certs' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trans_allow_exp_cert => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trans_allow_exp_cert => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trans_allow_exp_cert => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trans ssl' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'default' do
        let(:params) { default_params.merge(:trans_ssl => 'default') }
        it { is_expected.to compile }
      end

      context 'relaxed' do
        let(:params) { default_params.merge(:trans_ssl => 'relaxed') }
        it { is_expected.to compile }
      end

      context 'clientauth' do
        let(:params) { default_params.merge(:trans_ssl => 'clientauth') }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trans_ssl => 'invalid') }
        it { is_expected.to raise_error(/not supported for trans_ssl/) }
      end
    end

    context 'trigger ignore default' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_ignore_def => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_ignore_def => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_ignore_def => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trigger no status update' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_no_status => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_no_status => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_no_status => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trigger no version' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_no_version => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_no_version => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_no_version => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trigger on distribute' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_on_dist => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_on_dist => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_on_dist => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trigger on modification' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_on_mod => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_on_mod => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_on_mod => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trigger on off time' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_onoff_time => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_onoff_time => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_onoff_time => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'trigger on receive' do
      context 'unspecified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'true' do
        let(:params) { default_params.merge(:trigger_on_receive => true) }
        it { is_expected.to compile }
      end

      context 'false' do
        let(:params) { default_params.merge(:trigger_on_receive => false) }
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) { default_params.merge(:trigger_on_receive => 'not boolean') }
        it { is_expected.to raise_error(/is not a boolean/) }
      end
    end

    context 'username' do
      context 'is specified' do
        let(:params) { default_params }
        it { is_expected.to compile }
      end

      context 'is not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:username)
          tmp
        end
        it { is_expected.to raise_error(/'username' must be specified/) }
      end
    end

  end
end
