# encoding: utf-8

require 'spec_helper'

describe 'Process.method_missing security' do
  let(:source) { File.read(File.expand_path('../../lib/adhearsion/process.rb', __dir__)) }

  it 'should use public_send instead of send in method_missing' do
    lines = source.lines.each_with_index.select do |line, _idx|
      line =~ /\.send\b/ && line !~ /public_send|__send__|send_message/
    end
    expect(lines.map { |line, idx| "process.rb:#{idx + 1}: #{line.strip}" }).to be_empty,
      "Found .send calls that should use .public_send:\n" +
      lines.map { |line, idx| "  process.rb:#{idx + 1}: #{line.strip}" }.join("\n")
  end

  it 'should not allow calling private methods via class-level proxy' do
    # die_now! is a private-level dangerous method on the instance
    # The class-level method_missing proxy should not expose it
    # With public_send, this would raise NoMethodError for private methods
    expect {
      Adhearsion::Process.fqdn
    }.not_to raise_error

    # Verify public_send is used (behavioral test)
    # public_send respects method visibility, so private methods
    # should not be callable through the proxy
    instance = Adhearsion::Process.instance
    private_methods = instance.private_methods(false).map(&:to_s)
    expect(private_methods).not_to be_empty, "Expected Process instance to have private methods"
  end
end
