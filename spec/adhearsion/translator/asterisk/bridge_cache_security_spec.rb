# encoding: utf-8

require 'spec_helper'

describe 'Translator::Asterisk bridge cache security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk.rb', __dir__)) }

  it 'should enforce a maximum bridge cache size to prevent memory exhaustion' do
    expect(source).to match(/MAX_BRIDGE_CACHE_SIZE/),
      "The @bridges hash has no size limit — orphaned BridgeEnter events can exhaust memory"
  end
end
