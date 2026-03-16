# encoding: utf-8

require 'spec_helper'

describe 'i18n rake task security' do
  let(:task_source) { File.read(File.expand_path('../../../lib/adhearsion/tasks/i18n.rb', __dir__)) }

  describe 'YAML deserialization safety' do
    it 'should not use unsafe YAML.load' do
      # YAML.load can deserialize arbitrary Ruby objects, enabling RCE.
      # Must use YAML.safe_load instead.
      unsafe_calls = task_source.scan(/YAML\.load\b(?!_file)/)
      expect(unsafe_calls).to be_empty,
        "Found #{unsafe_calls.length} unsafe YAML.load call(s) in i18n.rb. " \
        "Use YAML.safe_load instead to prevent arbitrary object deserialization."
    end

    it 'should use YAML.safe_load for parsing locale files' do
      safe_calls = task_source.scan(/YAML\.safe_load/)
      expect(safe_calls).not_to be_empty,
        "Expected YAML.safe_load to be used for parsing locale files."
    end
  end
end
