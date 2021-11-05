require 'open-uri'
require 'json'

json = JSON.parse(URI.open("https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?locale=en-US&country=US&allowCountries=US,CN").read)

data = []
json["data"]["Catalog"]["searchStore"]["elements"].each do |element|
  promotions = element["promotions"]
  unless promotions.nil?
    (promotions["promotionalOffers"] + promotions["upcomingPromotionalOffers"]).each do |promotions|
      promotionalOffer = promotions["promotionalOffers"][0]
      if promotionalOffer["discountSetting"]["discountPercentage"] == 0
        data << {
          "title" => element["title"],
          "url" => "https://www.epicgames.com/store/product/#{element["productSlug"]}",
          "startDate" => promotionalOffer["startDate"],
          "endDate" =>  promotionalOffer["endDate"]
        }
      end
    end
  end
end

JSON.pretty_generate(data)
