import scrapy


class BritBoxSpider(scrapy.Spider):
    name = "seasons"
    start_urls = [
        'https://www.britbox.com/us/season/A_Touch_of_Frost_10008',
        'https://www.britbox.com/us/show/Vera_13500'
    ]

    def parse(self, response):
        for season in response.css('a.brand-season-item'):
            yield {
                'URL': season.css('a.brand-season-item::attr(href)').extract(),
                'Title': season.css('h2.program-item__program-title::text').extract(),
                'Year': season.css('p.season-metadata::text').extract(),
                'NumSeasons': season.css('p.season-metadata span::text')[2].extract(),
            }
