# encoding: utf-8

require 'spec_helper'

describe 'sensitive data log redaction' do
  let(:source) { File.read(File.expand_path('../../lib/adhearsion/call_controller/input/menu_builder.rb', __dir__)) }

  it 'should not log utterance or interpretation at INFO level' do
    # DTMF utterances may contain PINs, credit card numbers, or SSNs.
    # These should only appear at DEBUG level, never INFO or above.
    info_with_utterance = source.lines.select do |line|
      line =~ /\.info\b.*\b(utterance|interpretation)\b/
    end

    expect(info_with_utterance).to be_empty,
      "Sensitive user input (utterance/interpretation) logged at INFO level. " \
      "Use DEBUG level to avoid leaking PINs/credit cards in production logs:\n" +
      info_with_utterance.map(&:strip).join("\n")
  end
end
