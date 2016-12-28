# coding: utf-8
require "open-uri"
require "nokogiri"
require "pony"

TMP = "tmp"
RULES = "rules"

Dir.mkdir(TMP) unless File::directory?(TMP)

$rules = {}
def rule(id, name, url, css, before_send)
  if $rules.key?(id.to_sym)
    puts " - !!! Duplicate id: [#{id}]"
  else
    $rules[id.to_sym] = {
      :name => name,
      :url => url,
      :css => css,
      :before_send => before_send,
      :observers => []
    }
    puts " - [#{id}](#{name})"
  end
end

def subscribe(email, rule_id_list)
  puts " - for [#{email}]"
  rule_id_list.each do |rule_id|
    if $rules.key?(rule_id.to_sym)
      $rules[rule_id.to_sym][:observers] << email
      puts "    - add [#{rule_id}]."
    else
      puts "    - wrong [#{rule_id}].   (Legal rules: #{$rules.keys})"
    end
  end
end

puts "Load rules..."
load(File.open("rules.rb"))
puts "Load rules success."
puts ""

puts "Load subscriptions..."
load(File.open("emails.rb"))
puts "Load subscriptions success."
exit

$rules.each do |k, v|
  next if v[:observers].empty?

  file_name = File.join(TMP, k.to_s)
  old = File.read(file_name) if File.exist?(file_name)

  new = Nokogiri::HTML(open(v[:url]).read).css(v[:css])
  if new.to_s != old
    File.open(file_name, "w") do |file|
      file.print new.to_s
    end

    v[:before_send].call(new) unless v[:before_send].nil?

    v[:observers].each do |to|
      Pony.mail(:to => to,
                :subject => "[订阅]#{v[:name]}",
                :html_body => "<html>#{new}</html>",
                :from => 'noreply@example.com', # you might change
                :via => :sendmail               # you might change
               )
    end
  end
end
