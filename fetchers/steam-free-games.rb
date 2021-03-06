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
    # 去掉图片的时间戳
    img = tr.css("img")[0]
    img["src"] = img["src"].split("?")[0]
    data += tr.css(".applogo a").to_s + tr.css("b")[0].to_s + "<br>"
  else
    data << {
      "name" => tr.css("b")[0].text.strip,
      "link" => tr.css(".applogo a")[0]["href"]
    }
  end
end

data.class == String ? "<html>#{data}</html>" : JSON.pretty_generate(data)
