# coding: utf-8
require "open-uri"
require "nokogiri"
require "pony"
require "yaml"

TMP = "tmp"
RULES = "rules"

Dir.mkdir(TMP) unless File::directory?(TMP)

$load_success = true
$rules = {}

puts "Load rules..."
Dir.glob("#{RULES}/*.yaml").each do |file|
  id = file[RULES.size+1 ... file.size-5].to_sym # 5 means ".yaml".size
  data =  YAML.load_file(file)
  error = false
  ["name", "url", "css_selectors"].each do |key|
    if data[key].nil? || data[key].empty?
      $load_success = false
      error = true
      puts "  - [#{id}] FAILURE. '#{key}' not config."
    end
  end
  unless error
    $rules[id] = data.inject({}){|memo, (k,v)| memo[k.to_sym] = v; memo}.merge({:observers => []})
    puts "  - [#{id}] success."
  end
end

puts "\nLoad users..."
data = YAML.load_file("users.yaml")
if data.is_a?(Array)
  data.each do |user|
    email = user["email"]
    puts "  - for user: #{email}"
    user["following"].each do |rule_id|
      if $rules.key?(rule_id.to_sym)
        $rules[rule_id.to_sym][:observers] << email
        puts "    - [#{rule_id}] success."
      else
        $load_success = false
        puts "    - [#{rule_id}] FAILURE. (Legal rules: #{$rules.keys})"
      end
    end
  end
else
  puts "  - FAILURE. no users."
  $load_success = false
end


unless $load_success
  puts "\nFOUNT ERROR. Abort."
  exit
end


def modify_relative_link(scheme, host, attr)
  if attr.value[0] == '/'
    if attr.value[1] == '/'
      attr.value = "#{scheme}:#{attr.value}"
    else
      attr.value = "#{scheme}://#{host}#{attr.value}"
    end
  end
end

def loop_element(scheme, host, element)
  itself = element.itself
  case itself.name
  when "img"
    modify_relative_link(scheme, host, itself.attributes["src"])
  when "a"
    modify_relative_link(scheme, host, itself.attributes["href"])
  end

  element.children.each do |child|
    loop_element(scheme, host, child) if element.is_a?(Nokogiri::XML::Element)
  end
end

puts "\nCheck for updates..."
$rules.each do |k, v|
  print "  - check [#{k}]."
  if v[:observers].empty?
    puts " SKIP <no followers>."
    next
  end

  file_name = File.join(TMP, k.to_s)

  old = File.read(file_name) if File.exist?(file_name)
  new = Nokogiri::HTML(open(v[:url]).read).css(v[:css_selectors])

  if new.to_s == old
    puts " SKIP <no updates>."
    next
  end

  puts " FOUND."
  # save to tmp file
  File.open(file_name, "w") do |file|
    file.print new.to_s
  end

  # handle relative path
  uri = URI(v[:url])
  new.each {|element| loop_element(uri.scheme, uri.host, element)}

  # notify
  v[:observers].each do |to|
    puts "    - send mail to <#{to}>"
    Pony.mail(:to => to,
              :subject => "[订阅]#{v[:name]}",
              :html_body => "<html>#{new}</html>",
              :from => 'noreply@example.com', # you might change
              :via => :sendmail               # you might change
             )
  end
end
