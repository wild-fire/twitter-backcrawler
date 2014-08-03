require 'yaml'
require 'twitter'

class TwitterExceptionNotifier

  def self.config config_file

    yml_config = YAML.load_file(config_file)['twitter']

    @@twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key = yml_config['consumer_key']
      config.consumer_secret = yml_config['consumer_secret']
      config.access_token = yml_config['access_token']
      config.access_token_secret = yml_config['access_token_secret']      
    end

    @@destination_user = yml_config['destination_user'] || @@twitter_client.user.screen_name

  end

  def self.notify message
    @@twitter_client.create_direct_message(@@destination_user, message[0,140])
  end

end