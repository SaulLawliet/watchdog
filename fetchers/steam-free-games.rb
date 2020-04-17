# 依赖: tools/cloudflare-scrape.py
# pip3 install cfscrape
# proxy: 代理地址

require 'nokogiri'
require 'json'

cmd = "python3 tools/cloudflare-scrape.py https://steamdb.info/upcoming/free/"
unless options.nil? || options.proxy.nil?
  cmd += " #{options.proxy}"
end
doc = Nokogiri::HTML(`#{cmd}`)

data = []
doc.css("table")[0].css("tbody tr").each do |tr|
  if tr.css("td")[3].text.end_with?("Keep")
    data << {
      "name" => tr.css("b")[0].text.strip,
      "link" => tr.css(".applogo a")[0]["href"]
    }
  end
end

JSON.pretty_generate(data)
