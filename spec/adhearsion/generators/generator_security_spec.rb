# encoding: utf-8

require 'spec_helper'

describe 'Generator ERB security' do
  let(:source) { File.read(File.expand_path('../../../lib/adhearsion/generators/generator.rb', __dir__)) }

  it 'should not use ERB with an unrestricted binding' do
    # ERB.new(...).result(binding) exposes the full class context to template code.
    # Templates should use a restricted binding (e.g. an empty Binding via
    # TOPLEVEL_BINDING.dup or a dedicated context object) to limit what ERB
    # templates can access.
    lines = source.lines.each_with_index.select do |line, _idx|
      line =~ /\.result\s*\(\s*binding\s*\)/
    end
    expect(lines.map { |line, idx| "generator.rb:#{idx + 1}: #{line.strip}" }).to be_empty,
      "Found ERB evaluation with unrestricted binding:\n" +
      lines.map { |line, idx| "  generator.rb:#{idx + 1}: #{line.strip}" }.join("\n")
  end
end
