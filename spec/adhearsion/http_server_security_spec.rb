# encoding: utf-8

require 'spec_helper'
require 'loquacious'

describe 'HTTP server default bind address' do
  it 'should default to 127.0.0.1, not 0.0.0.0' do
    config = Adhearsion::Configuration.new
    expect(config.core.http.host).to eq("127.0.0.1"),
      "HTTP server defaults to '#{config.core.http.host}' which exposes the " \
      "server on all interfaces. Should default to '127.0.0.1' for security."
  end
end
