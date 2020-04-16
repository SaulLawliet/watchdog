# mid: up主ID

require 'open-uri'
require 'json'

relation_stat = JSON.parse(open("https://api.bilibili.com/x/relation/stat?vmid=#{options.mid}").read)
space_upstat = JSON.parse(open("https://api.bilibili.com/x/space/upstat?mid=#{options.mid}").read)

data = relation_stat["data"]
data.delete("following")
# 由于播放量和阅读量是日更, 所以不关心
# data["archive-view"] = space_upstat["data"]["archive"]["view"]
# data["article-view"] = space_upstat["data"]["article"]["view"]
data["likes"] = space_upstat["data"]["likes"]

JSON.pretty_generate(data)
