require 'nokogiri'
require 'open-uri'
require 'json'

ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.116 Safari/537.36"
cookie = "cf_clearance=9edcbdf290fe4a4b26aff3ab5fadaacb619b043b-1585386602-0-150; __cfduid=db71608fdc4de0f28e386b9f875342a7b1585386602;"
doc = Nokogiri::HTML(open("https://steamdb.info/upcoming/free/", "User-Agent" => ua, "Cookie" => cookie))

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

