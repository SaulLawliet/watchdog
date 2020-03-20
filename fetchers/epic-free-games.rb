require 'net/http'
require 'uri'
require 'json'

uri = URI.parse("https://graphql.epicgames.com/graphql")
header = {'Content-Type': 'application/json;charset=UTF-8'}

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = '{"query":"\\n          query promotionsQuery($namespace: String\u0021, $country: String\u0021, $locale: String\u0021) {\\n            Catalog {\\n              catalogOffers(namespace: $namespace, locale: $locale, params: {category: \\"freegames\\", country: $country, sortBy: \\"effectiveDate\\", sortDir: \\"asc\\"}) {\\n                elements {\\n                  title\\n                  description\\n                  id\\n                  namespace\\n                  categories {\\n                    path\\n                  }\\n                  linkedOfferNs\\n                  linkedOfferId\\n                  keyImages {\\n                    type\\n                    url\\n                  }\\n                  productSlug\\n                  promotions {\\n                    promotionalOffers {\\n                      promotionalOffers {\\n                        startDate\\n                        endDate\\n                        discountSetting {\\n                          discountType\\n                          discountPercentage\\n                        }\\n                      }\\n                    }\\n                    upcomingPromotionalOffers {\\n                      promotionalOffers {\\n                        startDate\\n                        endDate\\n                        discountSetting {\\n                          discountType\\n                          discountPercentage\\n                        }\\n                      }\\n                    }\\n                  }\\n                }\\n              }\\n            }\\n          }\\n        ","variables":{"namespace":"epic","country":"US","locale":"en-US"}}'

response = http.request(request)

json = JSON.parse(response.body)

data = []
json["data"]["Catalog"]["catalogOffers"]["elements"].each do |element|
  product = {
    "title" => element["title"],
    "url" => "https://www.epicgames.com/store/product/" + element["productSlug"]
  }

  promotions = element["promotions"]
  unless promotions.nil?
    unless promotions["promotionalOffers"].empty?
      promotionalOffer = promotions["promotionalOffers"][0]["promotionalOffers"][0]
    end
    unless promotions["upcomingPromotionalOffers"].empty?
      promotionalOffer = promotions["upcomingPromotionalOffers"][0]["promotionalOffers"][0]
    end
  end

  unless promotionalOffer.nil?
    product["startDate"] = promotionalOffer["startDate"]
    product["endDate"] = promotionalOffer["endDate"]
  end

  data << product
end

JSON.pretty_generate(data)
