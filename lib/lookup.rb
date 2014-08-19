require 'yaml'
require 'twitter'

class Lookup

  @@remaining_calls = 0

  def self.log message
    puts "[Tweet Lookup] #{message}"
  end

  # Singleton method for getting twitter client according to the configuration in the YML file
  # WARNING: client must not be stored in a variable and it always must be used directly: WeekSegmenter.client.user(...)
  # Otherwise, the counter method for controlling the rate limit would be useless
  def self.client
    @@client ||= Twitter::REST::Client.new do |config|
      yml_config = YAML.load_file( File.expand_path('../config/twitter.yml', File.dirname(__FILE__)) )['twitter']
      config.consumer_key        = yml_config['consumer_key']
      config.consumer_secret     = yml_config['consumer_secret']
      config.access_token        = yml_config['access_token']
      config.access_token_secret = yml_config['access_token_secret']
    end
    # Since we can't control when the API is called we decrement the counter here, hoping that when the client is called only 1 API call is made
    @@remaining_calls -= 1
    @@client
  end

  # This method obtains the rate limit info for the users API
  def self.rate_limit_info
    rate_info = Lookup.client.get '/1.1/application/rate_limit_status.json?resources=statuses'
    rate_info.body[:resources][:statuses][:"/statuses/lookup"]
  end

  # This method uses the information returned by rate_limit_info to make the whole script sleep until we have enough rate limit again
  def self.sleep_until_rate_limit
    # Rate limit info calls also have a rate limit, so we use a counter to limit the amount of API calls made
    # When this counter is less than 5, we make the check
    if @@remaining_calls < 5
      # We get the rate limit info
      rate_info = rate_limit_info
      log rate_info.inspect
      # Since we are using a counter and not perform this check with every API call we must give some space or we can fall into the rate limit without noticing
      # Our space are 20 API calls. If we have less than 20 we stop
      if rate_info[:remaining] < 20
        # And now here we sleep until the reset time for the rate limit
        log "Now I'm going to sleep until I have enough rate (#{Time.at rate_info[:reset]} - #{Time.at(rate_info[:reset]) - Time.now} seconds)"
        sleep((Time.at(rate_info[:reset]) - Time.now).abs)
      else
        log "Remaining calls #{rate_info[:remaining]} until #{Time.at rate_info[:reset]}"
      end
      # We reset the counter now
      @@remaining_calls = [20, rate_info[:remaining]/2].min
    end
  end

  def self.lookup initial_tweet_id, last_tweet_id = nil

    never_end = last_tweet_id.nil?

    begin
      tweet_ids, next_tweet_id = ids_to_fetch(initial_tweet_id)
      log "Fetching from #{tweet_ids.first} to #{tweet_ids.last}"
      self.sleep_until_rate_limit
      tweets = self.client.statuses tweet_ids

      yield tweets if block_given?

      last_tweet_id = next_tweet_id + 1 if never_end
      initial_tweet_id = next_tweet_id

    end while last_tweet_id > next_tweet_id

  end

  # Tweet's IDs are not always sequential (apparently only in the beginning). They jump in steps (usually 10) ending in the same digit
  # until you fall into another interval and then they end in another digit
  @@jumps = {
    16708021 => { step: 10 },
    33204252 => { step: 10 },
    763061061 => { step: 10 }
  }

  # This method gets an initial tweet_id and returns 100 tweets ids according with the jumps already recorded
  def self.ids_to_fetch tweet_id
    tweet_ids = []

    # We get the info of our current jump interval
    current_id_jump = @@jumps.keys.select{|i| i <= tweet_id }.max
    current_jump_step = @@jumps[current_id_jump][:step]

    # We check that this tweet id fits in the step for this interval
    # Otherwise we decrement this tweet id until it fits, using the modulo operator
    modulo = (tweet_id - current_id_jump) % current_jump_step
    # If it's a correct tweet id then modulo will be 0
    tweet_id -= modulo

    # We get the minimum tweet id next to our tweet_id
    next_id_jump = @@jumps.keys.select{|i| i > tweet_id }.min

    while tweet_ids.count < 101
      # If we enter into the next interval then we reset the tweet_id, current interval info and next interval info
      if next_id_jump && tweet_id >= next_id_jump
        tweet_id = next_id_jump
        current_id_jump = next_id_jump
        current_jump_step = @@jumps[current_id_jump][:step]
      end

      tweet_ids << tweet_id
      tweet_id += current_jump_step
    end

    [tweet_ids.first(100), tweet_ids.last]

  end


end
