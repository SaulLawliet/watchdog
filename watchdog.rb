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
puts ""

puts "Load users..."
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
puts ""


unless $load_success
  puts "FOUNT ERROR. Abort."
  exit
end


def modify_relative_link(scheme, host, attr)
  unless attr.value.match(/^\/\/[^\/]+/).nil?
    attr.value = "#{scheme}:#{attr.value}"
  end
  unless attr.value.match(/^\/[^\/]+/).nil?
    attr.value = "#{scheme}://#{host}#{attr.value}"
  end
end

def loop_element(scheme, host, node_set)
  node_set.children.each do |element|
    case element.name
    when "img"
      modify_relative_link(scheme, host, element.attributes["src"])
    when "a"
      modify_relative_link(scheme, host, element.attributes["href"])
    end
    loop_element(scheme, host, element) if element.is_a?(Nokogiri::XML::Element)
  end
end

$rules.each do |k, v|
  next if v[:observers].empty?

  file_name = File.join(TMP, k.to_s)

  old = File.read(file_name) if File.exist?(file_name)
  new = Nokogiri::HTML(open(v[:url]).read).css(v[:css_selectors])

  if new.to_s != old
    # save to tmp file
    File.open(file_name, "w") do |file|
      file.print new.to_s
    end

    # handle relative path
    uri = URI(v[:url])
    loop_element(uri.scheme, uri.host, new)

    # notify
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

