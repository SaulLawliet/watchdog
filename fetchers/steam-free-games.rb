# type: "html" 或 "json"
# proxy: 代理地址

# 依赖: tools/cloudflare-scrape.py
# pip3 install cfscrape

require 'nokogiri'
require 'json'

cmd = "python tools/cloudflare-scrape.py https://steamdb.info/upcoming/free/"
unless options.nil? || options.proxy.nil?
  cmd += " #{options.proxy}"
end
doc = Nokogiri::HTML(`#{cmd}`)

data = ""
if !options.nil? && !options.type.nil? && options.type == "json"
  data = []
end

doc.css("table")[0].css("tbody tr").each do |tr|
  next unless tr.css("td")[3].text.end_with?("Keep")

  if data.class == String
    data += tr.css("b")[0].text.strip + tr.css(".applogo a").to_s
  else
    data << {
      "name" => tr.css("b")[0].text.strip,
      "link" => tr.css(".applogo a")[0]["href"]
    }
  end
end

data.class == String ? "<html>#{data}</html>" : JSON.pretty_generate(data)
