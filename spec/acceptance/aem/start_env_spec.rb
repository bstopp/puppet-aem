require 'spec_helper_acceptance'

describe 'start-env configs' do

  let(:facts) do
    {
      :environment => :root
    }
  end

  include_examples 'setup aem'

  it 'should update the type' do
    shell("grep TYPE=\\'author\\' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
  end

  it 'should update the port' do
    shell('grep PORT=4502 /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 0)
  end

  it 'should update the sample content' do
    shell("grep SAMPLE_CONTENT=\\'\\' /opt/aem/author/crx-quickstart/bin/start-env",
          :acceptable_exit_codes => 0)
  end

  it 'should update the context root' do
    shell('grep CONTEXT_ROOT /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 1)
  end
end
