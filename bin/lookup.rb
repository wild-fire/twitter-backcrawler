#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'commander/import'
require 'twitter-text'
require_relative '../lib/lookup.rb'

program :version, '0.0.1'
program :description, 'Script for fetching tweets given an initial tweet id'

default_command :lookup

command :lookup do |c|
  c.syntax = 'lookup.rb lookup INITIAL_TWEET_ID [LAST_TWEET_ID] path/to/csv/file'
  c.summary = 'This command lookups and download tweets to a CSV starting from a Tweet ID'
  c.action do |args, options|
    if args.count < 2
      puts "Please, provide an initial tweet id and an output csv file."
    else
      initial_id = args.first.to_i
      last_id = args[1].to_i if args.count > 2
      csv_path = args.last

      Lookup.lookup initial_id, last_id do |tweets|
        CSV.open(csv_path, "a") do |csv|
          tweets.each do |tweet|
            # the tweet brings the entities information from the API, but the oldest tweets come without any url entity, even when there's some
            # This way we extract the urls and (sorry) join them into the urls field
            urls = Twitter::Extractor.extract_urls tweet.text
            csv << [
              tweet.id,
              tweet.user.id,
              tweet.user.screen_name,
              tweet.in_reply_to_status_id,
              tweet.in_reply_to_user_id,
              tweet.in_reply_to_screen_name,
              tweet.hashtags.map(&:text).join(','),
              tweet.user_mentions.map(&:id).join(','),
              tweet.user_mentions.map(&:screen_name).join(','),
              (tweet.uris.map(&:url) + urls).uniq.join(','),
              tweet.uris.map(&:expanded_url).join(','),
              tweet.media.map(&:uri).join(','),
              tweet.media.map(&:expanded_uri).join(','),
              tweet.text
            ]
          end
        end
      end
    end
  end
end

