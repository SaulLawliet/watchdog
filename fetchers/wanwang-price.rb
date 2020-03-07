# productID: 具体域名的产品ID, 在这个页面可以找到(https://wanwang.aliyun.com/help/price.html)
require 'uri'
require 'json'
require 'open-uri'

productID = options.productID

# 12,36,60,120
data = [
  {
    "productID" => productID,
    "period" => 12,
    "amount" => 1,
    "action" => "renew"
  },
  {
    "productID" => productID,
    "period" => 36,
    "amount" => 1,
    "action" => "renew"
  },
  {
    "productID" => productID,
    "period" => 60,
    "amount" => 1,
    "action" => "renew"
  },
  {
    "productID" => productID,
    "period" => 120,
    "amount" => 1,
    "action" => "renew"
  },
]

url = URI::encode("https://netcn.console.aliyun.com/core/product/infostatic?data=#{JSON.generate(data)}")
json = JSON.parse(open(url).read)

data = []
json["model"].each do |model|
  data << {
    "money" => model["money"],
    "saveMoney" => model["saveMoney"],
    "period" => model["period"]
  }
end

puts JSON.pretty_generate(data)
