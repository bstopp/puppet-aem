#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem'

describe Puppet::Type.type(:aem) do

  let(:source) { '/opt/aem/cq-author-4502.jar' }

  before do
    @provider_class = described_class.provide(:simple) { mk_resource_methods }
    @provider_class.stubs(:suitable?).returns true
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  before :each, :platform => :linux do
    expect(Puppet::Util::Platform).to receive(:windows?).and_return(false)
  end

  before :each, :platform => :windows do
    expect(Puppet::Util::Platform).to receive(:windows?).and_return(true)
  end

  before :example, :setup => :required do
    expect(Puppet::Util).to receive(:absolute_path?).and_return(true).at_most(1)
    expect(File).to receive(:directory?).and_return(true).at_most(1)

    expect(File).to receive(:file?).with(source).and_return(true).at_most(1)
  end

  describe 'namevar validation' do
    it 'should have :name as its namevar' do
      expect(described_class.key_attributes).to eq([:name])
    end
  end

  describe 'when validating attributes' do
    [:name, :source].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:version, :home, :user, :group, :port, :type, :user, :group].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do

    describe 'ensure', :setup => :required do
      it 'should support present as a value for ensure' do
        expect { described_class.new(:name => 'bar', :ensure => :present, :source => source) }.to_not raise_error
      end

      it 'should support absent as a value for ensure' do
        expect { described_class.new(:name => 'bar', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'bar', :ensure => :bar) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'name', :setup => :required do
      it 'should be required' do
        expect { described_class.new({}) }.to raise_error(Puppet::Error, 'Title or name must be provided')
      end

      it 'should accept a name' do
        inst = described_class.new(:name => 'bar')
        expect(inst[:name]).to eq('bar')
      end

      it 'should be munged to lowercase'  do
        inst = described_class.new(:name => 'BAR')
        expect(inst[:name]).to eq('bar')
      end
    end

    describe 'source', :setup => :required do
      it 'should require source to be specified' do
        expect { described_class.new(:name => 'bar', :ensure => :present) }.to raise_error(
        Puppet::Error, /Source jar is required/)
      end

      it 'should require source to exist' do
        expect(File).to receive(:file?).with('foo.jar').and_return(false)
        expect { described_class.new(:name => 'bar', :ensure => :present, :source => 'foo.jar') }.to raise_error(
        Puppet::Error, /AEM installer .* not found/)
      end

      it 'should work as expected when ensure is :present' do
        expect { described_class.new(:name => 'bar', :ensure => :present, :source => source) }.to_not raise_error
      end
    end

    describe 'version', :setup => :required do
      it 'should support valid major/minor format' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :version => 6.0) }.to_not raise_error
      end

      it 'should support valid major/minor/revision format' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :version => '6.0.0') }.to_not raise_error
      end

      it 'should require minor version' do
        expect { described_class.new(:name => 'bar', :version => 6) }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should not support beyond bug fix version' do
        expect { described_class.new(:name => 'bar', :version => '6.0.0.0') }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should munge to a string' do
        inst = described_class.new(:name => 'bar', :ensure => :absent, :version => 6.0)
        expect( inst[:version] ).to be_a(String)
      end
      
    end

    describe 'home' do
      context 'linux', :platform => :linux do
        it 'should have a default value', :setup => :required do
          inst = described_class.new(:name => 'bar', :ensure => :absent)
          expect( inst[:home] ).to eq('/opt/aem')
        end

        it 'should require absolute paths' do
          expect { described_class.new(:name => 'bar', :ensure => :present,
            :home => 'not/absolute', :source => source) }.to raise_error(Puppet::Error, /fully qualified/)
        end

        it 'should require path to exist' do
          expect { described_class.new(:name => 'bar', :ensure => :present,
            :home => '/does/not/exist', :source => source) }.to raise_error(Puppet::Error, /not found/)
        end
      end

      context 'windows', :platform => :windows do
        it 'should have a default value', :setup => :required do
          inst = described_class.new(:name => 'bar', :ensure => :absent)
          expect( inst[:home] ).to eq('C:/aem')
        end

        it 'should require absolute paths' do
          expect { described_class.new(:name => 'bar', :ensure => :present,
            :home => 'not/absolute', :source => source) }.to raise_error(Puppet::Error, /fully qualified/)
        end

        it 'should require path to exist' do
          expect { described_class.new(:name => 'bar', :ensure => :present,
            :home => 'C:/not/absolute', :source => source) }.to raise_error(Puppet::Error, /not found/)
        end
      end
    end

    describe 'port', :setup => :required do
      it 'should have a default value' do
        inst = described_class.new(:name => 'bar', :ensure => :absent)
        expect( inst[:port] ).to eq(4502)
      end

      it 'should always be a number' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :port => 'NaN')
        }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'type', :setup => :required do
      it 'should have a default value' do
        inst = described_class.new(:name => 'bar', :ensure => :absent)
        expect( inst[:type] ).to eq(:author)
      end

      it 'should support type author' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :type => :author)
        }.to_not raise_error
      end

      it 'should support type publish' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :type => :publish)
        }.to_not raise_error
      end

      it 'should not support type any other value' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :type => :anothertype)
        }.to raise_error(Puppet::Error, /Invalid value/)
      end

    end

  end

  describe 'autorequire' do
    #    it 'autorequires the user to run as' do
    #      fail("Implement test cases.")
    #    end
    #
    #    it 'autorequires the group to run as' do
    #      fail("Implement test cases.")
    #    end
    #
    #    it 'autorequires the source file' do
    #      fail("Implement test cases.")
    #    end
    #
    #    it 'autorequires the home directory' do
    #      fail("Implement test cases.")
    #    end

  end

end