# code: 编号, 如: "050025"
# principal: 本金
# share: 份额

require 'uri'
require 'json'
require 'open-uri'

code = options.code
principal = options.principal
share = options.share

user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36"
url = "https://danjuanfunds.com/djapi/fund/nav/history/#{code}?page=1&size=5"
json = JSON.parse(URI.open(url, "User-Agent" => user_agent).read)
first = json["data"]["items"].first

now = first['nav'].to_f * share

data = {
  "code" => code,
  "principal" => principal.to_f.round(2),
  first['date'] => "#{now.round(2)} (#{(now - principal).round(2)} / #{((now - principal)/principal * 100).round(2)}%)",
}

JSON.pretty_generate(data)
