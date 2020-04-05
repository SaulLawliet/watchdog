import cfscrape
import sys

proxies = {}
if len(sys.argv) > 1:
    url = sys.argv[1]
if len(sys.argv) > 2:
    proxy = sys.argv[2]
    proxies = {"http": proxy, "https": proxy}

scraper = cfscrape.create_scraper()
print(scraper.get(url, proxies=proxies).content)
