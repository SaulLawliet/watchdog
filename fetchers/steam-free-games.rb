# 依赖: tools/cloudflare-scrape.py
# proxy: 代理地址

require 'nokogiri'
require 'json'

cmd = "python tools/cloudflare-scrape.py https://steamdb.info/upcoming/free/"
unless options.nil? || options.proxy.nil?
  cmd += " #{options.proxy}"
end
doc = Nokogiri::HTML(`#{cmd}`)

data = []
lastLink = ""
doc.css(".text-left:nth-child(3) .applogo, .text-left:nth-child(3) .applogo +td").each do |td|
  if td["class"] == "applogo"
    a = td.css("a")[0]
    unless a.nil?
      lastLink = a["href"]
    end
    next
  end

  # 标题格式暂时发现以下两种:
  # Drawful 2 Limited Free Promotional Package - Mar 2020
  # Welcome Back To 2007 2 [Limited Free Promo]
  name = td.css("b")[0].text.split("Limited Free Promo")
  if name.length > 1
    data << {
      "name" => name[0].delete_suffix("[").strip,
      "link" => lastLink.split("?")[0]
    }
  end
end

JSON.pretty_generate(data)
