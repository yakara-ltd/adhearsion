# encoding: utf-8

Then /^the file "([^"]*)" should contain each of these content parts:$/ do |file, content_parts|
  parts = content_parts.split("\n")
  parts.each do |p|
    expect(read(file).join("\n")).to include(p)
  end
end

Then /^the file "([^"]*)" should not contain each of these content parts:$/ do |file, content_parts|
  parts = content_parts.split("\n")
  parts.each do |p|
    expect(read(file).join("\n")).not_to include(p)
  end
end
