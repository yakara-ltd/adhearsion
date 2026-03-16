# encoding: utf-8

require 'spec_helper'

describe 'Output::Formatter URI scheme security' do
  let(:source) { File.read(File.expand_path('../../../../lib/adhearsion/call_controller/output/formatter.rb', __dir__)) }

  it 'should whitelist URI schemes in uri? method' do
    # The uri? method checks for any URI scheme, accepting file://,
    # data://, gopher://, etc. This could trigger SSRF when the media
    # server fetches the URL. Only http, https, and file schemes should
    # be accepted for audio playback.
    uri_method = source[/def uri\?.*?end/m]
    expect(uri_method).to match(/ALLOWED_URI_SCHEMES|scheme.*include|%w|https?/),
      "uri? accepts any URI scheme without whitelisting — vulnerable to SSRF via file://, data://, etc."
  end
end
