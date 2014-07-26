require 'open-uri'
require 'json'
require 'nokogiri'

class BackCrawler

  def self.search first_tweet_id,  keywords
    twitter_url = "https://twitter.com/i/search/timeline?q=#{URI::escape(keywords)}&f=realtime&src=typd&include_available_features=1&include_entities=1"
    cursor = "#{first_tweet_id}-#{first_tweet_id}1"
    doc = open("#{twitter_url}&scroll_cursor=TWEET-#{cursor}").read
    response = JSON.parse(doc)
    tweets =  Nokogiri::XML(response['items_html'])

    tweets.css('li > div.tweet').each do |tweet_div|
      tweet = {}
      tweet[:id] = tweet_div['data-tweet-id']
      tweet[:user] = {}
      tweet[:user][:screen_name] = tweet_div['data-screen-name']
      tweet[:user][:id] = tweet_div['data-user-id']
      tweet[:text] = tweet_div.css('.tweet-text').first.text
      tweet[:time] = Time.at(tweet_div.css('._timestamp').first['data-time'].to_i).to_datetime
      tweet[:timestamp] = tweet_div.css('._timestamp').first['data-time']
      yield tweet
    end
  end


end