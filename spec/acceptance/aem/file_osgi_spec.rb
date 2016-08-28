require 'spec_helper_acceptance'

describe 'create osgi config files' do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

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

  it 'should contain osgi config file ReferrerFilter' do
    cmd = 'test -f /opt/aem/author/crx-quickstart/install/org.apache.sling.security.impl.ReferrerFilter.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

  it 'should contain the empty allow config' do
    cmd = 'grep "allow.empty=B\"true\"" '
    cmd += '/opt/aem/author/crx-quickstart/install/org.apache.sling.security.impl.ReferrerFilter.config'
    shell(cmd, acceptable_exit_codes: 0)
  end

  it 'should contain the allow hosts config' do
    cmd = 'grep "allow.hosts=\[\"author.localhost.localmachine\"\]" '
    cmd += '/opt/aem/author/crx-quickstart/install/org.apache.sling.security.impl.ReferrerFilter.config'
    shell(cmd, acceptable_exit_codes: 0)
  end
end
