# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'create osgi config files' do

  it 'should contain osgi config file SegmentNodeStoreService' do
    cmd = 'test -f /opt/aem/author/crx-quickstart/install/'
    cmd += 'org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

  it 'should contain the tarmk file config' do
    cmd = 'grep "tarmk.size=L\"512\"" '
    cmd += '/opt/aem/author/crx-quickstart/install/'
    cmd += 'org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

  it 'should contain the pauseCompatction config' do
    cmd = 'grep "pauseCompaction=B\"true\"" '
    cmd += '/opt/aem/author/crx-quickstart/install/'
    cmd += 'org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

  it 'should contain osgi config file WCMRequestFilter' do
    cmd = 'test -f /opt/aem/author/crx-quickstart/install/com.day.cq.wcm.core.WCMRequestFilter.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

  it 'should contain the empty allow config' do
    cmd = 'grep "wcmfilter.mode=\"preview\"" '
    cmd += '/opt/aem/author/crx-quickstart/install/com.day.cq.wcm.core.WCMRequestFilter.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

end
