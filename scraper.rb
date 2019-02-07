#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def idify(a)
  name = a.xpath('./@class').text == 'new' ? a.text : a.attr('title').value
  name.tr(' ', '-').downcase
end

def scrape(url)
  noko = noko_for(url)

  constituency = ''
  noko.xpath('.//h2[contains(.,"Current members")]/following-sibling::table[1]//tr[td]').each do |tr|
    tds = tr.css('td')
    constituency = tds.shift if tds.count == 3

    next if tds[0].text.strip == 'Vacant'
    data = {
      id:            idify(tds[0].css('a')),
      name:          tds[0].text.tidy,
      wikipedia__en: tds[0].xpath('a[not(@class="new")]/@title').text.tidy,
      area:          constituency.text.tidy,
      party:         tds[1].text.tidy,
      term:          '2011',
      source:        url,
    }
    ScraperWiki.save_sqlite(%i(id term), data)
  end
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape('https://en.wikipedia.org/w/index.php?title=House_of_Keys&oldid=743685692')
