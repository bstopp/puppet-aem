#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem'

describe Puppet::Type.type(:aem) do

  let(:source) { '/opt/aem/cq-author-4502.jar' }

  before :example, :windows => true do
    stub_const('File::ALT_SEPARATOR', '\\')
  end

  before :example, :need_aem => :true do
    File.stubs(:exists?).with(:source).returns(:true)
    @aem = Puppet::Type.type(:aem).new(
      {
        :name => 'author',
        :ensure => :present,
        :source => :source,
        :version => '6.1'
        
    })
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:aem).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  context 'name tests' do

    it 'should accept a name', :need_aem => true do
      expect(@aem[:name]).to eq('author')
    end

    it 'name should be lowercase', :need_aem => true do
      @aem[:name] = 'PUBLISH'
      expect(@aem[:name]).to eq('publish')
    end

  end # End name context

  context 'source' do

    it 'should require source if ensure present' do
      expect {
        Puppet::Type.type(:aem).new({:name => 'author',  :ensure => :present })
      }.to raise_error(Puppet::Error, /Source jar is required/)
    end

    it 'should require source to exist' do
      src = '/opt/aem/does/not/exist.jar'
      expect {
        File.stubs(:exists?).with(src).returns(:false)
        Puppet::Type.type(:aem).new({
            :name     => 'author',
            :ensure   => :present,
            :source   => src,
          })
        }.to raise_error(Puppet::Error)
    end

  end

  context 'version' do

    it 'should require version if ensure is present' do
      expect {
        File.stubs(:exists?).with(:file).returns(:true)
        Puppet::Type.type(:aem).new({:name => 'author', :ensure => :present, :source => :source})
      }.to raise_error(Puppet::Error, /Version is required/)
    end

    it 'should accept a version', :need_aem => true do
      expect(@aem[:version]).to eq('6.1')
    end

    it 'should accept a version major/minor/bug', :need_aem => true do
      @aem[:version] = '5.6.1'
      expect(@aem[:version]).to eq('5.6.1')
    end

    it 'should error if no minor value', :need_aem => true do
      expect{ @aem[:version] = '6' }.to raise_error(Puppet::Error)
    end

    it 'should not require bug version', :need_aem => true do
      @aem[:version] = '6.1'
      expect(@aem[:version]).to eq('6.1')
    end

    it 'should error if more than bug version', :need_aem => true do
      expect{ @aem[:version] = '5.6.1.0' }.to raise_error(Puppet::Error)
    end
  end #End version context

  context 'home parameter' do

    it 'should have default value', :need_aem => true do
      expect(@aem[:home]).to eq('/opt/aem')
    end

    it 'should accept linux absolute paths', :need_aem => true do
      @aem[:home] = '/opt/aem/author'
      expect(@aem[:home]).to eq('/opt/aem/author')
    end

    it 'should require an absolute path', :need_aem => true do
      expect { @aem[:home] = 'not valid' }.to raise_error(Puppet::Error)
    end


    it 'should have default value', :need_aem => true, :windows => true do
      expect(@aem[:home]).to eq('C:/aem')
    end

    it 'should accept windows absolute paths', :need_aem => true, :windows => true do
      @aem[:home] = 'C:/opt/aem/author'
      expect(@aem[:home]).to eq('C:/opt/aem/author')
    end
  end # End home context

end