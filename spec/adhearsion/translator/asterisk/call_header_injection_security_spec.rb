# encoding: utf-8

require 'spec_helper'

describe 'Translator::Asterisk::Call SIP header injection security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk/call.rb', __dir__)) }

  describe 'variable_for_headers' do
    it 'should sanitize header names and values to prevent injection' do
      # The variable_for_headers method must not allow raw interpolation
      # of header name/value into the SIPADDHEADER variable string.
      # Quotes, newlines, and other special characters must be stripped
      # or escaped to prevent SIP header injection.
      #
      # The vulnerable pattern is: "\"#{name}: #{value}\""
      # which allows injection via quotes or newlines in name/value.
      lines = source.lines.each_with_index.select do |line, _idx|
        line =~ /SIPADDHEADER.*#\{name\}.*#\{value\}/
      end

      vulnerable_lines = lines.select do |line, _idx|
        # If the line uses raw interpolation without sanitize/gsub/delete
        line !~ /sanitize|gsub|delete|tr|encode|reject|replace|clean/
      end

      expect(vulnerable_lines.map { |line, idx| "call.rb:#{idx + 1}: #{line.strip}" }).to be_empty,
        "Found unsanitized header interpolation in variable_for_headers:\n" +
        vulnerable_lines.map { |line, idx| "  call.rb:#{idx + 1}: #{line.strip}" }.join("\n")
    end
  end
end
