# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'systemctl service configs' do


  it 'should create systemctl service file' do
    shell('test -f /lib/systemd/system/aem-author.service', acceptable_exit_codes: 0)
  end

  it 'should specify the timeout' do
    shell("grep TimeoutStopSec=4min /lib/systemd/system/aem-author.service", acceptable_exit_codes: 0)
  end

  it 'should specify the kill signal' do
    shell("grep KillSignal=SIGCONT /lib/systemd/system/aem-author.service", acceptable_exit_codes: 0)
  end

  it 'should specify the private tmp' do
    shell("grep PrivateTmp=true /lib/systemd/system/aem-author.service", acceptable_exit_codes: 0)
  end
end
