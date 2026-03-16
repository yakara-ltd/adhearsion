# encoding: utf-8

require 'spec_helper'

describe 'DTMFRecognizer BuiltinMatcherCache security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/translator/asterisk/component/dtmf_recognizer.rb', __dir__)) }

  it 'should enforce a maximum cache size to prevent memory exhaustion' do
    # The cache must have a size limit so that an attacker cannot exhaust
    # memory by sending input commands with many unique grammar URLs.
    expect(source).to match(/MAX_CACHE_SIZE/),
      "BuiltinMatcherCache has no MAX_CACHE_SIZE constant — the cache is unbounded and vulnerable to memory exhaustion DoS"
  end

  it 'should evict entries when the cache exceeds the maximum size' do
    expect(source).to match(/\.size\s*>=?\s*MAX_CACHE_SIZE|\.length\s*>=?\s*MAX_CACHE_SIZE|delete|shift/),
      "BuiltinMatcherCache does not appear to evict old entries when full"
  end
end
