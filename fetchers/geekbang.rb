require 'uri'
require 'net/http'
require 'json'
# require 'open-uri'

uri = URI('https://time.geekbang.org/serv/v3/explore/all')
headers = {
  'Content-Type' => 'application/json',
  'Referer' => 'https://time.geekbang.org/',
  'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36'
}
req = Net::HTTP::Post.new(uri, headers)
req.body = {page: 'pc_home'}.to_json
res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(req)
end

json = JSON.parse(res.body)

titles = []
json['data']['list'].each do |item|
    if item['block_title'] == '7天热销榜单'
        item['list'].each do |list|
            list['products'].each do |product|
                titles.append(product['title'])
            end
        end
    end
end

JSON.pretty_generate(titles)
