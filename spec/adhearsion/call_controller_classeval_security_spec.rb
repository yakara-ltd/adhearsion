# encoding: utf-8

require 'spec_helper'

describe 'CallController class_eval security' do
  let(:source) { File.read(File.expand_path('../../lib/adhearsion/call_controller.rb', __dir__)) }

  it 'should not use class_eval with string interpolation' do
    # class_eval with string interpolation (class_eval <<-STOP ... #{name} ...)
    # is fragile and could become a code injection vector if callback names
    # are ever derived from user input. Should use define_method instead.
    lines = source.lines.each_with_index.select do |line, _idx|
      line =~ /class_eval\s*<</ || line =~ /class_eval\s*["']/
    end
    expect(lines.map { |line, idx| "call_controller.rb:#{idx + 1}: #{line.strip}" }).to be_empty,
      "Found class_eval with string interpolation:\n" +
      lines.map { |line, idx| "  call_controller.rb:#{idx + 1}: #{line.strip}" }.join("\n")
  end
end
