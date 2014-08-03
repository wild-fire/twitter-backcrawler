#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require_relative '../lib/back_crawler.rb'
require_relative '../lib/twitter_exception_notifier.rb'

program :version, '0.0.1'
program :description, 'Script for fetching old tweets'

command :search do |c|
  c.syntax = 'Twitter Backcrawler search tweet-id keywords'
  c.summary = 'It returns tweets before the tweets id containing the desired keywords'
  c.description = ''
  c.option '--twitter_config_file path/to/config.yml', String, 'Path to twitter config file (default: config/twitter.yml)'
  c.action do |args, options|
    options.default :twitter_config_file  => 'config/twitter.yml'
    if args.length != 2
      puts "Please, provide first tweet id and keywords"
    else
      BackCrawler.search *args do |tweet|
        puts [
            tweet[:id],
            tweet[:timestamp],
            tweet[:time],
            tweet[:user][:screen_name],
            tweet[:user][:id],
            "\"#{tweet[:text].gsub('"', "'")}\""
          ].join ','
      end
    end
  end
end

