import scrapy


class BritBoxSpider(scrapy.Spider):
    name = "shows"
    start_urls = [
        'https://www.britbox.com/us/movie/A_Christmas_Carol_15128',
        'https://www.britbox.com/us/show/Till_Death_Us_Do_Part_15810',
        'https://www.britbox.com/us/season/Vera_S8_15720',
        'https://www.britbox.com/us/show/Superhomes_9006',
        'https://www.britbox.com/us/show/New_Blood_9275'
    ]

    def parse(self, response):
        for show in response.css('div.program-item'):
            yield {
                'URL': show.css('a.program-item__block::attr(href)').extract(),
                'Title': show.css('h3.program-item__program-title::text').extract(),
                'Subtitle': show.css('p.program-item__program-subtitle::text').extract(),
                'Duration': show.css('span.programme-metadata__duration::text').extract(),
                'Year': show.css('span.programme-metadata__year::text').extract(),
                'Rating': show.css('span.programme-metadata__classification::text').extract(),
                'Description': show.css('p.program-item__program-description::text').extract()
            }
