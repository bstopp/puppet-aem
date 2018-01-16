#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem_crx_package'

describe Puppet::Type.type(:aem_crx_package) do
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
    %i[name home password retries source timeout username].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    %i[group version].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do

    describe 'ensure' do
      it 'should support present as a value for ensure' do
        expect do
          described_class.new(name: 'bar', ensure: :present, home: '/opt/aem')
        end.not_to raise_error
      end

      it 'should support installed as a value for ensure' do
        expect do
          described_class.new(name: 'bar', ensure: :installed, home: '/opt/aem')
        end.not_to raise_error
      end

      it 'should support absent as a value for ensure' do
        expect do
          described_class.new(name: 'bar', ensure: :absent, home: '/opt/aem')
        end.not_to raise_error
      end

      it 'should support purged as a value for ensure' do
        expect do
          described_class.new(name: 'bar', ensure: :purged, home: '/opt/aem')
        end.not_to raise_error
      end

      it 'should not support other values' do
        expect do
          described_class.new(name: 'bar', ensure: :invalid, home: '/opt/aem')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
      context 'insync?' do
        let(:resource) { described_class.new(name: 'bar', ensure: :present, home: '/opt/aem') }
        let(:ensre) { resource.property(:ensure) }

        context 'ensure is present' do
          it 'should match to present' do
            expect(ensre.insync?(:present)).to be_truthy
          end
          %i[installed absent purged].each do |param|
            it "should not match #{param}" do
              expect(ensre.insync?(param)).to be_falsey
            end
          end
        end
        context 'ensure is installed' do
          before :each do
            resource[:ensure] = :installed
          end
          it 'should match to installed' do
            expect(ensre.insync?(:installed)).to be_truthy
          end
          %i[present absent purged].each do |param|
            it "should not match #{param}" do
              expect(ensre.insync?(param)).to be_falsey
            end
          end
        end
        context 'ensure is absent' do
          before :each do
            resource[:ensure] = :absent
          end
          %i[absent purged].each do |param|
            it "should match #{param}" do
              expect(ensre.insync?(param)).to be_truthy
            end
          end
          %i[present installed].each do |param|
            it "should not match #{param}" do
              expect(ensre.insync?(param)).to be_falsey
            end
          end
        end
        context 'ensure is purged' do
          before :each do
            resource[:ensure] = :purged
          end
          %i[absent purged].each do |param|
            it "should match #{param}" do
              expect(ensre.insync?(param)).to be_truthy
            end
          end
          %i[present installed].each do |param|
            it "should not match #{param}" do
              expect(ensre.insync?(param)).to be_falsey
            end
          end
        end
      end
    end

    describe 'home' do

      it 'should require a value' do
        expect do
          described_class.new(name: 'bar', ensure: :absent)
        end.to raise_error(Puppet::Error, /Home must be specified/)
      end

      context 'linux', platform: :linux do

        it 'should require absolute paths' do
          expect do
            described_class.new(
              name: 'bar',
              ensure: :present,
              home: 'not/absolute'
            )
          end.to raise_error(Puppet::Error, /fully qualified/)
        end
      end
      context 'windows', platform: :windows do

        it 'should require absolute paths' do
          expect do
            described_class.new(
              name: 'bar',
              ensure: :present,
              home: 'not/absolute'
            )
          end.to raise_error(Puppet::Error, /fully qualified/)
        end
      end
    end

    describe 'retries' do
      it 'should require it to be a number' do
        expect do
          described_class.new(name: 'bar', ensure: :present, home: '/opt/aem', retries: 'foo')
        end.to raise_error(/Parameter retries failed/)
      end

      it 'should have a default' do
        test = described_class.new(name: 'bar', ensure: :present, home: '/opt/aem')
        expect(test.parameter(:retries).value).to eq(10)
      end

      it 'should convert to a number' do
        test = described_class.new(name: 'bar', ensure: :present, home: '/opt/aem', retries: '60')
        expect(test.parameter(:timeout).value).to eq(60)
      end
    end

    describe 'timeout' do
      it 'should require it to be a number' do
        expect do
          described_class.new(name: 'bar', ensure: :present, home: '/opt/aem', timeout: 'foo')
        end.to raise_error(/Parameter timeout failed/)
      end

      it 'should have a default' do
        test = described_class.new(name: 'bar', ensure: :present, home: '/opt/aem')
        expect(test.parameter(:timeout).value).to eq(60)
      end

      it 'should convert to a number' do
        test = described_class.new(name: 'bar', ensure: :present, home: '/opt/aem', timeout: '60')
        expect(test.parameter(:timeout).value).to eq(60)
      end
    end
  end

end
