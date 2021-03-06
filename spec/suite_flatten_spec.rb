# coding: utf-8
require_relative 'spec_helper'

describe JSON::LD do
  describe "test suite" do
    require_relative 'suite_helper'
    m = Fixtures::SuiteTest::Manifest.open("#{Fixtures::SuiteTest::SUITE}flatten-manifest.jsonld")
    describe m.name do
      m.entries.each do |t|
        specify "#{t.property('@id')}: #{t.name} unordered#{' (negative test)' unless t.positiveTest?}" do
          t.options[:ordered] = false
          if %w(#t0005).include?(t.property('@id'))
            expect{t.run self}.to write("Terms beginning with '@' are reserved for future use").to(:error)
          else
            expect {t.run self}.not_to write.to(:error)
          end
        end

        specify "#{t.property('@id')}: #{t.name} ordered#{' (negative test)' unless t.positiveTest?}" do
          t.options[:ordered] = true
          if %w(#t0005).include?(t.property('@id'))
            expect{t.run self}.to write("Terms beginning with '@' are reserved for future use").to(:error)
          else
            expect {t.run self}.not_to write.to(:error)
          end
        end
      end
    end
  end
end unless ENV['CI']