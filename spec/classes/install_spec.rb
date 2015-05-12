require 'spec_helper'

describe 'adobe_experience_manager' do
  let :facts do
    {
      :osfamily                 => 'RedHat',
      :operatingsystem          => 'CentOS',
      :operatingsystemrelease   => '7.0',
      :java_major_version       => '1.7',
    }
  end

  let :params do
    {
      :jar        => '/opt/aem/cq-author-4502.jar',
      :version    => '6.0',
    }
  end

  context 'java not installed' do
    let :facts do
      {
        :osfamily                 => 'RedHat',
        :operatingsystem          => 'CentOS',
        :operatingsystemrelease   => '7.0',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /Java is required/)
    end
  end

  context 'invalid aem home path' do
    let :params do
      {
        :aem_home   => 'not/a/fully/qualified/path',
        :jar        => '/opt/aem/cq-author-4502.jar',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /absolute path/)
    end
  end

  context 'Java/AEM combo not supported' do
    let :facts do
      {
        :osfamily                 => 'RedHat',
        :operatingsystem          => 'CentOS',
        :operatingsystemrelease   => '7.0',
        :java_major_version       => '1.8',
      }
    end
    let :params do
      {
        :jar       => '/opt/aem/cq-author-4502.jar',
        :version   => '6.0',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /version of Java is not supported/)
    end
  end

  context 'AEM 6.0/Java 1.7 Supported' do
    it {
      is_expected.to contain_class('adobe_experience_manager::install').with(
        :cabfile  => "installed.cab",
        :runmodes  => ['author'],
        :mongo    => false,
      )
    }
  end

  context 'default install.sh created' do
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with(
          {
            :path     => '/opt/aem/install.sh',
            :ensure   => 'file',
            :owner    => 'aem',
            :group    => 'aem',
            :mode     => '0700',
            :backup   => false,
          }
        ).with_content(
          /.*java\s+-jar\s+\/opt\/aem\/cq-author-4502.jar\s+-nobrowser\s+-b\s+\/opt\/aem\s+-r\s+author\s+>\s+\/dev\/null\s+2>&1\s+&.*/
        )
    }
  end

  context 'install.sh created nosample runmode' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :includesamples   => false,
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*-r\s+author,nosamplecontent\s+.*/
      )
    }
  end

  context 'install.sh created mongo' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :mongo            => true,
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*-r\s+author,crx3,crx3mongo\s+.*/
      )
    }
  end

    context 'install.sh created mongo url' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :mongo            => true,
      :mongo_uri        => 'mongodb://127.0.0.1:27017'
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*-Doak.mongo.uri=mongodb:\/\/127\.0\.0\.1:27017.*/
      )
    }
  end

  context 'install.sh created mongo nosample' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :mongo            => true,
      :includesamples   => false,
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*-r\s+author,crx3,crx3mongo,nosamplecontent\s+.*/
      )
    }
  end

  context 'install.sh created java opts' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :jvm_opts         => '-Xmx2048m',
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*java\s+-Xmx2048m.*/
      )
    }
  end

  context 'install.sh created port' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :port             => 4503,
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*-p 4503.*/
      )
    }
  end

  context 'install.sh created port' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
      :log_level        => 2,
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /.*-ll 2.*/
      )
    }
  end

  context 'monitor_install.sh created' do
    let :params do
    {
      :jar              => '/opt/aem/cq-author-4502.jar',
      :version          => '6.0',
    }
    end
    it {
      is_expected.to contain_file('/opt/aem/monitor_install.sh').with_content(
        /.*tail.*\s\/opt\/aem\/crx-quickstart\/logs\/error\.log.*\/opt\/aem\/installed\.cab.*/m
      )
    }
  end

end
