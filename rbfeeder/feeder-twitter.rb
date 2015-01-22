#!/usr/bin/env ruby
require 'twitter'

client = Twitter::Streaming::Client.new do |config|
  config.consumer_key       =  ENV['CONSUMER_KEY']
  config.consumer_secret    =  ENV['CONSUMER_SECRET']
  config.access_token        = ENV['ACCESS_TOKEN']
  config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
end

TERMS = ENV['TERMS'] || 'a,i'

puts "Setting up a stream to track terms '#{TERMS}'..."
@tracked,@skipped,@tracked_last,@skipped_last = 0,0,0,0


# output stats periodically
Thread.new do
  @stats_refresh_rate = 10

  loop do
    sleep @stats_refresh_rate
    period = @tracked-@tracked_last
    period_rate = period / @stats_refresh_rate

    puts "Terms tracked: #{@tracked} (\u2191#{period}" +
         ", +#{period_rate}/sec.), rate limited: #{@skipped}" +
         " (+#{@skipped - @skipped_last})"
    @tracked_last = @tracked
    @skipped_last = @skipped
  end
end


client.filter(track: TERMS) do |msg|
  case msg
  when Twitter::Tweet
    @tracked += 1
  when Twitter::Streaming::DeletedTweet
    puts "SAW A DELETED TWEET"
  when Twitter::Streaming::StallWarning
    puts "STALL FALLBEHIND WARNING - NOT KEEPING UP WITH STREAM", warning
  end
end
