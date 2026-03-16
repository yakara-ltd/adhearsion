# encoding: utf-8

require 'spec_helper'

describe 'Translator::Asterisk::Call send_message security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk/call.rb', __dir__)) }

  it 'should not use bare rescue which silently swallows all exceptions' do
    # A bare `rescue` (without specifying exception classes) swallows
    # everything including Celluloid::DeadActorError, SystemExit, etc.
    # This masks bugs and attack signals. The rescue should be specific.
    lines = source.lines.each_with_index.select do |line, _idx|
      line.strip == 'rescue'
    end
    expect(lines.map { |line, idx| "call.rb:#{idx + 1}: #{line.strip}" }).to be_empty,
      "Found bare rescue statements that silently swallow all exceptions:\n" +
      lines.map { |line, idx| "  call.rb:#{idx + 1}: #{line.strip}" }.join("\n")
  end
end
