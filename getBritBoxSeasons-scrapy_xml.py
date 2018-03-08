import scrapy


class BritBoxSpider(scrapy.Spider):
    name = "seasons"
    # BROKEN - shows with only one season
    start_urls = [
            'https://www.britbox.com/us/show/A_Touch_of_Frost_10008',
            'https://www.britbox.com/us/show/New_Blood_9275',
            'https://www.britbox.com/us/show/Superhomes_9006',
            'https://www.britbox.com/us/show/Till_Death_Us_Do_Part_15810',
            'https://www.britbox.com/us/show/Vera_13500',
            ]

    def parse(self, response):
        # for season in response.css('a.brand-season-item'):
        title = response.css('h1.brand-hero-info__title::text').extract()

        for season in response.css('a.brand-season-item'):
            yield {
                    'URL': season.css('a.brand-season-item::attr(href)').extract(),
                    'Title': title,
                    'SeasonNumber': season.css('h2.program-item__program-title::text').re(r'Season (\d+)'),
                    'Year': season.css('p.season-metadata::text').extract(),
                    'NumEpisodes': season.css('p.season-metadata span::text')[2].re(r'(\d+)'),
                    }

            for href in response.css('a.brand-season-item::attr(href)'):
                yield response.follow(href, self.parseEpisode)


    def parseEpisode(self, response):
        for show in response.css('div.program-item'):
            yield {
                    'URL': show.css('a.program-item__block::attr(href)').extract(),
                    'Title': show.css('h3.program-item__program-title::text').extract(),
                    'Subtitle': show.css('p.program-item__program-subtitle::text').extract(),
                    'Duration': show.css('span.programme-metadata__duration::text').re(r'(\d+)'),
                    'Year': show.css('span.programme-metadata__year::text').extract(),
                    'Rating': show.css('span.programme-metadata__classification::text').extract(),
                    # 'Description': show.css('p.program-item__program-description::text').extract(),
                    }
