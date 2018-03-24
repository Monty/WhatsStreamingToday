import scrapy
import sys
import inspect
import logging


class BritBoxSpider(scrapy.Spider):
    name = "shows"
    #  Doesn't handle /us/programme, or /us/show/ with only one season
    #  Works for /us/show/ with > 1 season
    # yapf: disable
    start_urls = [
        'https://www.britbox.com/us/movie/70_Glorious_Years_13550',           # Movie
        'https://www.britbox.com/us/movie/A_Christmas_Carol_15128',           # Movie
        'https://www.britbox.com/us/show/A_Bit_of_Fry_and_Laurie_6393',       # Show (+1 seasons)
        'https://www.britbox.com/us/show/A_History_of_Ancient_Britain_6385',  # Show (1+ seasons)
        'https://www.britbox.com/us/show/New_Blood_9275',                     # Show (1 season)
        'https://www.britbox.com/us/show/The_Jury_9565',                      # Show (2 seasons)
        'https://www.britbox.com/us/show/Till_Death_Us_Do_Part_15810',        # Show (1 season)
        'https://www.britbox.com/us/show/Vera_13500'                          # Show (2 seasons)
    ]
    # yapf: enable

    def parse(self, response):
        for page in self.start_urls:
            if ("/movie/" in page) or ("/episode/" in page):
                yield scrapy.Request(page, callback=self.parse1Episode)
            elif "/show/" in page:
                seasons = response.css(
                    'div.program-item__title-wrapper p.program-item__program-subtitle::text'
                ).extract_first()
                shortURL = "/" + response.url.split('/', 3)[3]
                if seasons is not None:
                    if "Season " in seasons:
                        # logging.info("Found Season in " + seasons + " on " + shortURL)
                        yield scrapy.Request(page, callback=self.parseAllSeasons)
                    else:
                        # logging.info("No Season in " + seasons + " on " + shortURL)
                        yield scrapy.Request(page, callback=self.parseAllEpisodes)
            elif "/season/" in page:
                yield scrapy.Request(page, callback=self.parseAllEpisodes)

    def parseAllEpisodes(self, response):
        shortURL = "/" + response.url.split('/', 3)[3]
        for show in response.css('div.program-item'):
            logging.info("Parsing " + shortURL + " in parseAllEpisodes")
            yield {
                'URL': show.css('a.program-item__block::attr(href)').extract(),
                'Title': show.css('h3.program-item__program-title::text').extract(),
                'Subtitle': show.css('p.program-item__program-subtitle::text').extract(),
                'Duration': show.css('span.programme-metadata__duration::text').re(r'(\d+)'),
                'Year': show.css('span.programme-metadata__year::text').extract(),
                'Rating': show.css('span.programme-metadata__classification::text').extract(),
                # 'Description': "-desc-",
                'Description': show.css('p.program-item__program-description::text').extract(),
                'shortURL': shortURL,
                'function': sys._getframe().f_code.co_name,
            }

    def parse1Episode(self, response):
        shortURL = "/" + response.url.split('/', 3)[3]
        URLs = (response.css('div.program-item a.program-item__block::attr(href)').extract())
        for i, item in enumerate(URLs):
            if (item == shortURL):
                URL = URLs[i]
                Title = response.css('div.program-item h3.program-item__program-title::text')[
                    i].extract()
                if (len(
                        response.css('div.program-item p.program-item__program-subtitle::text')
                        .extract()) == 0):
                    Subtitle = ''
                else:
                    Subtitle = response.css('div.program-item p.program-item__program-subtitle::text')[
                        i].extract()
                Duration = response.css('div.program-item span.programme-metadata__duration::text')[
                    i].re(r'(\d+)')
                Year = response.css('div.program-item span.programme-metadata__year::text')[
                    i].extract()
                Rating = response.css(
                    'div.program-item span.programme-metadata__classification::text')[i].extract()
                logging.info("Parsing " + shortURL + " in parse1Episode")
                yield {
                    'URL':
                        URL,
                    'Title':
                        Title,
                    'Subtitle':
                        Subtitle,
                    'Duration':
                        Duration,
                    'Year':
                        Year,
                    'Rating':
                        Rating,
                    # 'Description': "-desc-",
                    'Description':
                        response.css('div.program-item p.program-item__program-description::text')[i]
                        .extract(),
                    'shortURL':
                        shortURL,
                    'function':
                        sys._getframe().f_code.co_name,
                }

    def parseAllSeasons(self, response):
        shortURL = "/" + response.url.split('/', 3)[3]
        title = response.css('h1.brand-hero-info__title::text').extract()

        for season in response.css('a.brand-season-item'):
            description = response.css('p.brand-hero-info__description::text').extract()
            url = response.css('a.brand-season-item::attr(href)').extract()
            logging.info("Parsing " + shortURL + " in parseAllSeasons")
            logging.info("URL = " + str(url) + "DESCR = " + str(description))
            yield {
                'URL':
                    season.css('a.brand-season-item::attr(href)').extract(),
                'Title':
                    title,
                'SeasonNumber':
                    season.css('h2.program-item__program-title::text').re(r'Season (\d+)'),
                'Year':
                    season.css('p.season-metadata::text').extract(),
                'NumEpisodes':
                    season.css('p.season-metadata span::text')[2].re(r'(\d+)'),
                # 'Description': "-desc-",
                'Description':
                    description,
                # 'Description':
                #     season.css('p.brand-hero-info__description::text').extract(),
                'shortURL':
                    shortURL,
                'function':
                    sys._getframe().f_code.co_name,
            }

            for href in response.css('a.brand-season-item::attr(href)'):
                yield response.follow(href, self.parseAllEpisodes)
