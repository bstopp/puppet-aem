require 'spec_helper_acceptance'

describe 'updated start-env configs' do

  let(:facts) do
    {
      :environment => :root
    }
  end

  include_examples 'setup aem'
  include_examples 'update aem'

  it 'should update the type' do
    shell("grep TYPE=\\'publish\\' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
  end

  it 'should update the port' do
    shell('grep PORT=4503 /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 0)
  end

  it 'should update the runmodes' do
    shell("grep RUNMODES=\\'dev,client,server,mock\\' /opt/aem/author/crx-quickstart/bin/start-env",
          :acceptable_exit_codes => 0)
  end

  it 'should update the sample content' do
    shell("grep SAMPLE_CONTENT=\\'nosamplecontent\\' /opt/aem/author/crx-quickstart/bin/start-env",
          :acceptable_exit_codes => 0)
  end

  it 'should update the debug port' do
    shell("grep -- 'DEBUG_PORT=54321' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
  end

  it 'should update the context root' do
    shell("grep CONTEXT_ROOT=\\'aem-publish\\' /opt/aem/author/crx-quickstart/bin/start-env",
          :acceptable_exit_codes => 0)
  end

  it 'should update the jvm memory settings' do
    shell("grep -- \"JVM_MEM_OPTS='-Xmx2048m -XX:MaxPermSize=512M'\" /opt/aem/author/crx-quickstart/bin/start-env",
          :acceptable_exit_codes => 0)
  end

  it 'should update the jvm settings' do
    shell("grep -- JVM_OPTS=\\'-XX:+UseParNewGC\\' /opt/aem/author/crx-quickstart/bin/start-env",
          :acceptable_exit_codes => 0)
  end
end
