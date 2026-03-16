# encoding: utf-8

require 'spec_helper'

describe 'Translator::Asterisk::Call AGI timeout security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk/call.rb', __dir__)) }

  it 'should define an AGI command timeout constant' do
    # response.value without a timeout blocks the thread indefinitely
    # if Asterisk never sends a response. This can be exploited for DoS.
    expect(source).to match(/AGI_TIMEOUT/),
      "No AGI_TIMEOUT constant defined — execute_agi_command can block indefinitely"
  end

  it 'should pass a timeout to response.value in execute_agi_command' do
    # The response.value call must include a timeout argument
    agi_method = source[/def execute_agi_command.*?^        end/m]
    expect(agi_method).to match(/response\.value\s*\(/),
      "response.value called without timeout argument in execute_agi_command"
  end
end
