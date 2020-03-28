# proxy: 代理地址

require 'nokogiri'
require 'open-uri'
require 'json'

cmd = "curl -s 'https://steamdb.info/upcoming/free/' -H 'authority: steamdb.info' -H 'pragma: no-cache' -H 'cache-control: no-cache' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36' -H 'sec-fetch-dest: document' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'referer: https://steamdb.info/upcoming/' -H 'accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,zh-TW;q=0.6' -H 'cookie: __cfduid=d5184d150f49292659235dd142f10fcf81582973585; _ga=GA1.2.743832855.1582973597; cf_clearance=acaf2e3580b22f9926d4c689f0e6361a4421b561-1585376577-0-150; _gid=GA1.2.426680156.1585376581; _gat=1' --compressed"
unless options.proxy.nil?
  cmd = "https_proxy=#{options.proxy} " + cmd
end
doc = Nokogiri::HTML(`#{cmd}`)

data = []
lastLink = ""
doc.css(".text-left:nth-child(3) .applogo, .text-left:nth-child(3) .applogo +td").each do |td|
  if td["class"] == "applogo"
    lastLink = td.css("a")[0]["href"]
    next
  end

  name = td.text.strip.split(" Limited Free Promotional")
  if name.length > 1
    data << {
      "name" => name[0],
      "link" => lastLink.split("?")[0]
    }
  end
end

JSON.pretty_generate(data)
