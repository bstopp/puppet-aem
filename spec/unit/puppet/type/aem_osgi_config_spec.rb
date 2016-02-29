#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem_osgi_config'

describe Puppet::Type.type(:aem_osgi_config) do

  before do
    @provider_class = described_class.provide(:simple) { mk_resource_methods }
    @provider_class.stubs(:suitable?).returns true
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe 'namevar validation' do
    it 'should have :name as its namevar' do
      expect(described_class.key_attributes).to eq([:name])
    end
  end

  describe 'when validating attributes' do
    [:name, :handle_missing, :home, :username, :password, :pid].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:configuration].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do

    describe 'ensure' do
      it 'should support present as a value for ensure' do
        expect do
          described_class.new(:name => 'bar', :ensure => :present, :handle_missing => 'merge', :home => '/opt/aem')
        end.not_to raise_error
      end

      it 'should support absent as a value for ensure' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent, :handle_missing => 'merge', :home => '/opt/aem')
        end.not_to raise_error
      end

      it 'should not support other values' do
        expect do
          described_class.new(:name => 'bar', :ensure => :invalid, :handle_missing => 'merge', :home => '/opt/aem')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'name' do
      it 'should be required' do
        expect do
          described_class.new({})
        end.to raise_error(Puppet::Error, 'Title or name must be provided')
      end

      it 'should accept a name' do
        inst = described_class.new(:name => 'bar', :home => '/opt/aem')
        expect(inst[:name]).to eq('bar')
      end
    end

    describe 'handle_missing' do
      it 'should support merge as a value for handle_missing' do
        expect do
          described_class.new(:name => 'bar', :ensure => :present, :handle_missing => :merge, :home => '/opt/aem')
        end.not_to raise_error
      end

      it 'should support remove as a value for handle_missing' do
        expect do
          described_class.new(:name => 'bar', :ensure => :present, :handle_missing => :remove, :home => '/opt/aem')
        end.not_to raise_error
      end

      it 'should not support other values' do
        expect do
          described_class.new(:name => 'bar', :ensure => :preset, :handle_missing => :invalid, :home => '/opt/aem')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'home' do

      it 'should require a value' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent)
        end.to raise_error(Puppet::Error, /Home must be specified/)
      end

      context 'linux', :platform => :linux do

        it 'should require absolute paths' do
          expect do
            described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => 'not/absolute')
          end.to raise_error(Puppet::Error, /fully qualified/)
        end
      end

      context 'windows', :platform => :windows do

        it 'should require absolute paths' do
          expect do
            described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => 'not/absolute')
          end.to raise_error(Puppet::Error, /fully qualified/)
        end
      end
    end

    describe 'configuration' do
      it 'should require value to be a hash' do
        expect do
          described_class.new(
            :name => 'bar',
            :ensure => :present,
            :home => '/opt/aem',
            :configuration => %w('foo', 'bar')
          )
        end.to raise_error(Puppet::Error, /must be a hash/)
      end
    end
  end

  describe 'when testing sync of values' do
    describe 'configuration' do
      describe 'insync' do
        describe 'handle hash with :handle_missing == remove' do

          it 'should handle same configuration' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => '/opt/aem',
              :configuration => { 'foo' => 'bar' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle different configuration same key' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => '/opt/aem',
              :configuration => { 'foo' => 'baz' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle different configuration, different key' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => '/opt/aem',
              :configuration => { 'bar' => 'foo' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle additional configuration' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => '/opt/aem',
              :configuration => { 'bar' => 'foo' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar', 'bar' => 'foo' }

            expect(prop.insync?(is)).to be_falsey
          end

        end

        describe 'handle hash with :handle_missing == merge' do

          it 'should handle same resources' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => '/opt/aem',
              :handle_missing => :merge,
              :configuration => { 'foo' => 'bar' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle different configuration same key' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => '/opt/aem',
              :handle_missing => :merge,
              :configuration => { 'foo' => 'baz' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle different configuration different key' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :handle_missing => :merge,
              :home => '/opt/aem',
              :configuration => { 'bar' => 'foo' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle additional configuration in should' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :handle_missing => :merge,
              :home => '/opt/aem',
              :configuration => { 'bar' => 'foo', 'foo' => 'bar' }
            )
            prop = existing.property(:configuration)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle additional configuration in is' do
            existing = described_class.new(
              :name => 'bar',
              :ensure => :present,
              :handle_missing => :merge,
              :home => '/opt/aem',
              :configuration => { 'bar' => 'foo' }
            )
            prop = existing.property(:configuration)
            is = { 'bar' => 'foo', 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_truthy
          end
        end
      end
    end
  end

end
