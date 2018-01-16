#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem_sling_resource'

describe Puppet::Type.type(:aem_sling_resource) do

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
    %i[
      force_passwords
      handle_missing
      home
      name
      path
      password
      password_properties
      protected_properties
      retries
      username
    ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:properties].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do

    describe 'ensure' do
      it 'should support present as a value for ensure' do
        expect { described_class.new(name: 'bar', ensure: :present, home: '/opt/aem') }.not_to raise_error
      end

      it 'should support absent as a value for ensure' do
        expect { described_class.new(name: 'bar', ensure: :absent, home: '/opt/aem') }.not_to raise_error
      end

      it 'should not support other values' do
        expect do
          described_class.new(name: 'bar', ensure: :there, home: '/opt/aem')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'name' do
      it 'should be required' do
        expect { described_class.new({}) }.to raise_error(Puppet::Error, 'Title or name must be provided')
      end

      it 'should accept a name' do
        inst = described_class.new(name: 'bar', home: '/opt/aem')
        expect(inst[:name]).to eq('bar')
      end
    end

    describe 'handle_missing' do

      it 'should support remove as a value for handle_missing' do
        expect do
          described_class.new(name: 'bar', ensure: :present, handle_missing: :remove, home: '/opt/aem')
        end.not_to raise_error
      end

      it 'should support ignore as a value for handle_missing' do
        expect do
          described_class.new(name: 'bar', ensure: :present, handle_missing: :ignore, home: '/opt/aem')
        end.not_to raise_error
      end

      it 'should not support other values' do
        expect do
          described_class.new(name: 'bar', ensure: :preset, handle_missing: :invalid, home: '/opt/aem')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'home' do

      it 'should require a value' do
        expect do
          described_class.new(name: 'bar', ensure: :absent)
        end.to raise_error(Puppet::Error, /Home must be specified/)
      end

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

    describe 'properties' do
      it 'should require value to be a hash' do
        expect do
          described_class.new(
            name: 'bar',
            ensure: :present,
            home: '/opt/aem',
            properties: %w[foo bar]
          )
        end.to raise_error(Puppet::Error, /must be a hash/)
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
        test = described_class.new(name: 'bar', ensure: :present, home: '/opt/aem', retries: '10')
        expect(test.parameter(:retries).value).to eq(10)
      end
    end

  end

  describe 'when testing sync of values' do
    describe 'properties' do
      describe 'insync' do
        describe 'handle hash with :handle_missing == remove' do

          it 'should handle same properties' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :remove,
              home: '/opt/aem',
              properties: { 'foo' => 'bar' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle different properties same key' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :remove,
              home: '/opt/aem',
              properties: { 'foo' => 'baz' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle different properties, different key' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :remove,
              home: '/opt/aem',
              properties: { 'bar' => 'foo' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle additional properties' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :remove,
              home: '/opt/aem',
              properties: { 'bar' => 'foo' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar', 'bar' => 'foo' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should ignore protected properties in is' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :remove,
              home: '/opt/aem',
              properties: {
                'bar' => 'foo',
                'baz' => {
                  'a' => {
                    'b' => 'c'
                  }
                }
              }
            )
            prop = existing.property(:properties)
            is = {
              'baz' => {
                'jcr:createdBy' => 'not admin',
                'a' => {
                  'b' => 'c',
                  'cq:lastModified'   => 'a person',
                  'cq:lastModifiedBy' => 'original value'
                }
              },
              'bar' => 'foo',
              'jcr:created' => 'original value'
            }

            expect(prop.insync?(is)).to be_truthy
          end

          context 'custom ignored properties' do
            it 'should ignore protected properties in is' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                handle_missing: :remove,
                home: '/opt/aem',
                ignored_properties: ['ignored', 'anotherignored'],
                properties: {
                  'jcr:created' => 'original value',
                  'bar' => 'foo',
                  'baz' => {
                    'jcr:createdBy' => 'not admin',
                    'a' => {
                      'b' => 'c',
                      'cq:lastModified'   => 'a person',
                      'cq:lastModifiedBy' => 'original value'
                    }
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'jcr:createdBy' => 'not admin',
                  'ignored'       => 'value',
                  'a' => {
                    'b' => 'c',
                    'cq:lastModified'   => 'a person',
                    'cq:lastModifiedBy' => 'original value',
                    'anotherignored'    => 'vale'
                  }
                },
                'bar' => 'foo',
                'jcr:created' => 'original value'
              }

              expect(prop.insync?(is)).to be_truthy
            end
          end

          it 'should ignore protected properties in should' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :remove,
              home: '/opt/aem',
              properties: {
                'bar' => 'foo',
                'jcr:created' => 'a value',
                'baz' => {
                  'jcr:createdBy' => 'admin',
                  'a' => {
                    'b' => 'c',
                    'cq:lastModified'   => 'a person',
                    'cq:lastModifiedBy' => 'original value'
                  }
                }
              }
            )
            prop = existing.property(:properties)
            is = {
              'baz' => {
                'a' => {
                  'b' => 'c'
                }
              },
              'bar' => 'foo'
            }

            expect(prop.insync?(is)).to be_truthy
          end

          describe 'force_passwords == false' do
            it 'should ignore password properties in should' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                handle_missing: :remove,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a person'
                    },
                    'onemorepassword' => 'original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'a' => {
                    'b' => 'c'
                  }
                },
                'bar' => 'foo'
              }

              expect(prop.insync?(is)).to be_truthy
            end

            it 'should ignore password properties in is' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                handle_missing: :remove,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c'
                    }
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'apassword' => 'a value',
                  'a' => {
                    'b' => 'c',
                    'anotherpassword' => 'a person'
                  }
                },
                'bar' => 'foo',
                'onemorepassword' => 'original value'
              }

              expect(prop.insync?(is)).to be_truthy
            end

          end

          describe 'force_passwords == true' do
            it 'should update password properties in should' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                force_passwords: true,
                handle_missing: :remove,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a person'
                    },
                    'onemorepassword' => 'original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'a' => {
                    'b' => 'c'
                  }
                },
                'bar' => 'foo'
              }

              expect(prop.insync?(is)).to be_falsey
            end

            it 'should update password properties' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                force_passwords: true,
                handle_missing: :remove,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a new value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a new person'
                    },
                    'onemorepassword' => 'not original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'apassword' => 'a value',
                  'a' => {
                    'b' => 'c',
                    'anotherpassword' => 'a person'
                  }
                },
                'bar' => 'foo',
                'onemorepassword' => 'original value'
              }

              expect(prop.insync?(is)).to be_falsey
            end

          end
        end

        describe 'handle hash with :handle_missing == ignore' do

          it 'should handle same resources' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'foo' => 'bar' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle different properties same key' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'foo' => 'baz' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle different properties different key' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle additional properties in should' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'foo' => 'bar' }
            )
            prop = existing.property(:properties)
            is = { 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle additional properties in is' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo' }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'foo' => 'bar' }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle nested hash properties in should' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'baz' => { 'a' => 'b' } }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle nested hash properties in should hash/not-hash' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'baz' => { 'a' => 'b' } }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'baz' => 'not hash' }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle nested, existing hash properties in is' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo' }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'baz' => { 'a' => 'b' } }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle nested matching hash properties' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'baz' => { 'a' => 'b' } }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'baz' => { 'a' => 'b' } }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle nested not-matching hash properties' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'baz' => { 'a' => 'c' } }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'baz' => { 'a' => 'b' } }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should handle depth nested matching hash properties' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'baz' => { 'a' => { 'b' => 'c' } } }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'baz' => { 'a' => { 'b' => 'c' } } }

            expect(prop.insync?(is)).to be_truthy
          end

          it 'should handle depth nested not-matching hash properties' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: { 'bar' => 'foo', 'baz' => { 'a' => { 'b' => 'c' } } }
            )
            prop = existing.property(:properties)
            is = { 'bar' => 'foo', 'baz' => { 'a' => { 'b' => 'd' } } }

            expect(prop.insync?(is)).to be_falsey
          end

          it 'should ignore protected properties in should' do
            existing = described_class.new(
              name: 'bar',
              ensure: :present,
              handle_missing: :ignore,
              home: '/opt/aem',
              properties: {
                'bar' => 'foo',
                'jcr:created' => 'a value',
                'baz' => {
                  'jcr:createdBy' => 'admin',
                  'a' => {
                    'b' => 'c',
                    'cq:lastModified'   => 'a person',
                    'cq:lastModifiedBy' => 'original value'
                  }
                }
              }
            )
            prop = existing.property(:properties)
            is = {
              'bar' => 'foo',
              'jcr:created' => 'original value',
              'baz' => {
                'jcr:createdBy' => 'not admin',
                'a' => {
                  'b' => 'c',
                  'jcr:primaryType' => 'oak:unstructured'
                }
              }
            }

            expect(prop.insync?(is)).to be_truthy
          end

          describe 'force_passwords == false' do
            it 'should ignore password properties in should' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                handle_missing: :ignore,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a person'
                    },
                    'onemorepassword' => 'original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'a' => {
                    'b' => 'c'
                  }
                },
                'bar' => 'foo'
              }

              expect(prop.insync?(is)).to be_truthy
            end

            it 'should ignore password properties in is' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                handle_missing: :ignore,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a new value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a new person'
                    },
                    'onemorepassword' => 'not original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'apassword' => 'a value',
                  'a' => {
                    'b' => 'c',
                    'anotherpassword' => 'a person'
                  }
                },
                'bar' => 'foo',
                'onemorepassword' => 'original value'
              }

              expect(prop.insync?(is)).to be_truthy
            end

          end

          describe 'force_passwords == true' do
            it 'should update password properties in should' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                force_passwords: true,
                handle_missing: :ignore,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a person'
                    },
                    'onemorepassword' => 'original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'a' => {
                    'b' => 'c'
                  }
                },
                'bar' => 'foo'
              }

              expect(prop.insync?(is)).to be_falsey
            end

            it 'should update password properties' do
              existing = described_class.new(
                name: 'bar',
                ensure: :present,
                force_passwords: true,
                handle_missing: :ignore,
                home: '/opt/aem',
                password_properties: ['apassword', 'anotherpassword', 'onemorepassword'],
                properties: {
                  'bar' => 'foo',
                  'apassword' => 'a new value',
                  'baz' => {
                    'jcr:createdBy' => 'admin',
                    'a' => {
                      'b' => 'c',
                      'anotherpassword' => 'a new person'
                    },
                    'onemorepassword' => 'not original value'
                  }
                }
              )
              prop = existing.property(:properties)
              is = {
                'baz' => {
                  'apassword' => 'a value',
                  'a' => {
                    'b' => 'c',
                    'anotherpassword' => 'a person'
                  }
                },
                'bar' => 'foo',
                'onemorepassword' => 'original value'
              }

              expect(prop.insync?(is)).to be_falsey
            end

          end
        end
      end
    end
  end

end
