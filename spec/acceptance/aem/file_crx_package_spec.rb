# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'create crx package files' do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  it 'should contain test zip file' do
    cmd = 'test -f /opt/aem/author/crx-quickstart/install/test-1.0.0.zip '
    shell(cmd, acceptable_exit_codes: 0)
  end

end
