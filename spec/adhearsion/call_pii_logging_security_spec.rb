# encoding: utf-8

require 'spec_helper'

describe 'Call PII logging security' do
  let(:source) { File.read(File.expand_path('../../lib/adhearsion/call.rb', __dir__)) }

  it 'should not log from/to fields at INFO level in end event handler' do
    # Caller/callee identifiers (phone numbers, SIP URIs, names) are PII.
    # Logging them at INFO level means they appear in production logs,
    # which may be stored insecurely or shared broadly.
    # The end event log line should use DEBUG for from/to details.
    info_lines_with_pii = source.lines.each_with_index.select do |line, _idx|
      line =~ /logger\.info.*\bfrom\b.*\bto\b/ || line =~ /logger\.info.*#\{from\}.*#\{to\}/
    end
    expect(info_lines_with_pii.map { |line, idx| "call.rb:#{idx + 1}: #{line.strip}" }).to be_empty,
      "Found PII (from/to) logged at INFO level:\n" +
      info_lines_with_pii.map { |line, idx| "  call.rb:#{idx + 1}: #{line.strip}" }.join("\n")
  end
end
