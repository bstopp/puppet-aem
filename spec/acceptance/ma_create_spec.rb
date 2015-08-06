require 'spec_ma_helper_acceptance'

describe 'AEM Module Master/Agent' do

  let(:agent) { only_host_with_role(hosts, 'agent') }
  let(:master) { only_host_with_role(hosts, 'master') }

  site = <<-MANIFEST
    node "centos-70-x64-agent" {
      file { "/opt/aem" :
        ensure  => "directory",
        owner   => "vagrant",
        group   => "vagrant",
      }

      package { "java" : }

      aem { "aem" :
        ensure          => present,
        source          => "/tmp/aem-quickstart.jar",
        user            => "vagrant",
        group           => "vagrant",
        jvm_mem_opts    => "-Xmx2048m",
        sample_content  => false,
        require         => File["/opt/aem"],
      }
    }
  MANIFEST

  describe 'master and agent' do
    it 'should work without errors' do
      on master, "echo '#{site}' > /etc/puppetlabs/code/environments/production/manifests/site.pp"
    end
  end
end