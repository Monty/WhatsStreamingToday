import scrapy


class BritBoxSpider(scrapy.Spider):
    name = "seasons"
    # Doesn't handle /us/programme, /us/movie/, or /us/show/ with only one season
    # Works for /us/show/ or /us/episode/ with > 1 seson
    start_urls = [
            'https://www.britbox.com/us/programmes',                             # Top level
            'https://www.britbox.com/us/movie/70_Glorious_Years_13550',          # Movie
            'https://www.britbox.com/us/movie/A_Christmas_Carol_15128',          # Movie
            'https://www.britbox.com/us/show/New_Blood_9275',                    # Show (1 season)
            'https://www.britbox.com/us/show/Till_Death_Us_Do_Part_15810',       # Show (1 season)
            'https://www.britbox.com/us/show/A_History_of_Ancient_Britain_6385', # Show (1+ seasons)
            'https://www.britbox.com/us/show/A_Bit_of_Fry_and_Laurie_6393',      # Show (1+ seasons)
            'https://www.britbox.com/us/show/The_Jury_9565',                     # Show (2 seasons)
            'https://www.britbox.com/us/season/Vera_S8_15720',                   # Season (2 seasons)
            'https://www.britbox.com/us/episode/Superhomes_S1_E1_9008',          # Episode (1 season)
            'https://www.britbox.com/us/episode/Cold_Blood_S2_E2_10298',         # Episode (2 seasons)
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
                    'Description': show.css('p.program-item__program-description::text').extract(),
                    }
