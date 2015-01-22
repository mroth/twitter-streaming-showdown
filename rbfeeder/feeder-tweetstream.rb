#!/usr/bin/env ruby

require 'eventmachine'
require 'oj'
require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key       = ENV['CONSUMER_KEY']
  config.consumer_secret    = ENV['CONSUMER_SECRET']
  config.oauth_token        = ENV['ACCESS_TOKEN']
  config.oauth_token_secret = ENV['ACCESS_TOKEN_SECRET']
  config.auth_method = :oauth
end

TERMS = ENV['TERMS'] || 'a,i'

EM.run do
  puts "Setting up a stream to track terms '#{TERMS}'..."
  @tracked,@skipped,@tracked_last,@skipped_last = 0,0,0,0

  @client = TweetStream::Client.new

  # handle error/status conditions from stream
  @client.on_error do |message|
    puts "ERROR: #{message}"
  end
  @client.on_enhance_your_calm do
    puts "TWITTER SAYZ ENHANCE UR CALM"
  end
  @client.on_stall_warning do |warning|
    puts "STALL FALLBEHIND WARNING - NOT KEEPING UP WITH STREAM", warning
  end

  # keep track of number of any skipped tweets (not sent to us) due to rate
  # limiting from the Twitter streaming API
  @client.on_limit do |skip_count|
    @skipped = skip_count
  end

  # track those tweets!
  @client.track(TERMS) do |status|
    @tracked += 1
  end

  # output stats periodically
  @stats_refresh_rate = 10
  EM::PeriodicTimer.new(@stats_refresh_rate) do
    period = @tracked-@tracked_last
    period_rate = period / @stats_refresh_rate

    puts "Terms tracked: #{@tracked} (\u2191#{period}" +
         ", +#{period_rate}/sec.), rate limited: #{@skipped}" +
         " (+#{@skipped - @skipped_last})"
    @tracked_last = @tracked
    @skipped_last = @skipped
  end

end
