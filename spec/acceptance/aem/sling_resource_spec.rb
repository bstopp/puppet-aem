require 'spec_helper_acceptance'

describe 'sling resource', license: false do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  context 'create' do
    it 'should work with no errors' do

      site = <<-MANIFEST
        'node \"agent\" {

          \$props = {
            \"jcr:primaryType\" => \"nt:unstructured\",
            \"title\" => \"title string\",
            \"text\"  => \"text string\",
            \"child\" => {
              \"jcr:primaryType\" => \"nt:unstructured\",
              \"property\" => \"value\",
              \"grandchild\" => {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"child attrib\" => \"another value\",
                \"array\" => [\"this\", \"is\", \"an\", \"array\"]
              }
            }
          }

          aem_sling_resource { \"test node\" :
            ensure         => present,
            path           => \"/content/testnode\",
            properties     => \$props,
            handle_missing => \"remove\",
            home           => \"/opt/aem/author\",
            password       => \"admin\",
            username       => \"admin\",
          }

        }'
      MANIFEST

      pp = <<-MANIFEST
        file {
          '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
            ensure => file,
            content => #{site}
        }
      MANIFEST

      apply_manifest_on(master, pp, catch_failures: true)
      restart_puppetserver
      fqdn = on(master, 'facter fqdn').stdout.strip
      fqdn = fqdn.chop if fqdn.end_with?('.')

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0, 2]
      )

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0]
      )
      cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout)

        expect(jsonresult['title']).to eq('title string')
        expect(jsonresult['text']).to eq('text string')
        expect(jsonresult['child']['property']).to eq('value')
        expect(jsonresult['child']['grandchild']['child attrib']).to eq('another value')
        expect(jsonresult['child']['grandchild']['array']).to eq(['this', 'is', 'an', 'array'])
      end
    end
  end

  context 'update' do
    it 'handle_missing == ignore' do
      site = <<-MANIFEST
        'node \"agent\" {

          \$props = {
            \"jcr:primaryType\" => \"nt:unstructured\",
            \"jcr:title\" => \"title string\",
            \"newtext\"  => \"text string\",
            \"child\" => {
              \"anotherproperty\" => \"value\",
              \"grandchild2\" => {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"child attrib\" => \"another value\",
                \"array\" => [\"this\", \"is\", \"an\", \"array\"]
              }
            },
            \"child2\" => {
              \"jcr:primaryType\" => \"nt:unstructured\",
              \"property\" => \"value\",
              \"grandchild\" => {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"child attrib\" => \"another value\",
                \"array\" => [\"this\", \"is\", \"an\", \"array\"]
              }
            }
          }

          aem_sling_resource { \"test node\" :
            ensure         => present,
            path           => \"/content/testnode\",
            properties     => \$props,
            handle_missing => \"ignore\",
            home           => \"/opt/aem/author\",
            password       => \"admin\",
            username       => \"admin\",
          }

        }'
      MANIFEST

      pp = <<-MANIFEST
        file {
          '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
            ensure => file,
            content => #{site}
        }
      MANIFEST

      apply_manifest_on(master, pp, catch_failures: true)
      restart_puppetserver
      fqdn = on(master, 'facter fqdn').stdout.strip
      fqdn = fqdn.chop if fqdn.end_with?('.')

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0, 2]
      )

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0]
      )
      cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout)

        expect(jsonresult['title']).to eq('title string')
        expect(jsonresult['text']).to eq('text string')
        expect(jsonresult['child']['property']).to eq('value')
        expect(jsonresult['child']['grandchild']['child attrib']).to eq('another value')
        expect(jsonresult['child']['grandchild']['array']).to eq(['this', 'is', 'an', 'array'])

        expect(jsonresult['child']['anotherproperty']).to eq('value')
        expect(jsonresult['child']['grandchild2']['child attrib']).to eq('another value')
        expect(jsonresult['child']['grandchild2']['array']).to eq(['this', 'is', 'an', 'array'])

        expect(jsonresult['jcr:title']).to eq('title string')
        expect(jsonresult['newtext']).to eq('text string')
        expect(jsonresult['child2']['property']).to eq('value')
        expect(jsonresult['child2']['grandchild']['child attrib']).to eq('another value')
        expect(jsonresult['child2']['grandchild']['array']).to eq(['this', 'is', 'an', 'array'])
      end
    end

    it 'handle_missing == remove' do
      site = <<-MANIFEST
        'node \"agent\" {

          \$props = {
            \"jcr:primaryType\" => \"nt:unstructured\",
            \"jcr:title\" => \"title string\",
            \"newtext\"  => \"text string\",
            \"child\" => {
              \"anotherproperty\" => \"new value\",
              \"grandchild2\" => {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"child attrib\" => \"changed value\",
                \"array\" => [\"this\", \"is\", \"a\", \"longer\", \"array\"]
              }
            },
            \"child2\" => {
              \"jcr:primaryType\" => \"nt:unstructured\",
              \"property\" => \"value\",
              \"grandchild\" => {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"child attrib\" => \"another value\"
              }
            }
          }

          aem_sling_resource { \"test node\" :
            ensure         => present,
            path           => \"/content/testnode\",
            properties     => \$props,
            handle_missing => \"remove\",
            home           => \"/opt/aem/author\",
            password       => \"admin\",
            username       => \"admin\",
          }

        }'
      MANIFEST

      pp = <<-MANIFEST
        file {
          '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
            ensure => file,
            content => #{site}
        }
      MANIFEST

      apply_manifest_on(master, pp, catch_failures: true)
      restart_puppetserver
      fqdn = on(master, 'facter fqdn').stdout.strip
      fqdn = fqdn.chop if fqdn.end_with?('.')

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0, 2]
      )

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0]
      )
      cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout)

        expect(jsonresult['title']).to be_nil
        expect(jsonresult['text']).to be_nil
        expect(jsonresult['child']['property']).to be_nil
        expect(jsonresult['child']['grandchild']).to be_nil

        expect(jsonresult['child']['anotherproperty']).to eq('new value')
        expect(jsonresult['child']['grandchild2']['child attrib']).to eq('changed value')
        expect(jsonresult['child']['grandchild2']['array']).to eq(['this', 'is', 'a', 'longer', 'array'])

        expect(jsonresult['jcr:title']).to eq('title string')
        expect(jsonresult['newtext']).to eq('text string')
        expect(jsonresult['child2']['property']).to eq('value')
        expect(jsonresult['child2']['grandchild']['child attrib']).to eq('another value')
        expect(jsonresult['child2']['grandchild']['array']).to be_nil
      end
    end
  end

  context 'destroy' do

    it 'should work with no errors' do
      site = <<-MANIFEST
        'node \"agent\" {

          aem_sling_resource { \"test node\" :
            ensure         => absent,
            path           => \"/content/testnode\",
            home           => \"/opt/aem/author\",
            password       => \"admin\",
            username       => \"admin\",
          }

        }'
      MANIFEST

      pp = <<-MANIFEST
        file {
          '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
            ensure => file,
            content => #{site}
        }
      MANIFEST

      apply_manifest_on(master, pp, catch_failures: true)
      restart_puppetserver
      fqdn = on(master, 'facter fqdn').stdout.strip
      fqdn = fqdn.chop if fqdn.end_with?('.')

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0, 2]
      )

      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        acceptable_exit_codes: [0]
      )
      cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        expect(result.stdout).to match(/404/)
      end
    end
  end
end
