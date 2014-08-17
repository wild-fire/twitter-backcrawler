#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require_relative '../lib/lookup.rb'

program :version, '0.0.1'
program :description, 'Script for fetching tweets given an initial tweet id'

default_command :lookup

command :lookup do |c|
  c.syntax = 'lookup.rb lookup INITIAL_TWEET_ID [LAST_TWEET_ID]'
  c.summary = 'This command lookups and download tweets to a CSV starting from a Tweet ID'
  c.action do |args, options|
    if args.empty?
      puts "Please, provide an initial tweet id."
    else
      Lookup.lookup *args.map(&:to_i) do |tweets|
        tweets.each do |t|
          puts t.text
        end
      end
    end
  end
end

