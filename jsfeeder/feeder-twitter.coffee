EmojiData = require('emoji-data')
Twitter   = require('twitter')


twit = new Twitter(
  consumer_key:         process.env.CONSUMER_KEY
  consumer_secret:      process.env.CONSUMER_SECRET
  access_token_key:     process.env.ACCESS_TOKEN
  access_token_secret:  process.env.ACCESS_TOKEN_SECRET
)


TERMS = process.env.TERMS || 'a,i'
ITERS = if process.env.ITERS then parseInt(process.env.ITERS) else 0

console.log "Setting up a stream to track terms '#{TERMS}'..."
console.log "Will auto-terminate after processing #{ITERS} tweets." if ITERS>0

[tracked,skipped,tracked_last,skipped_last] = [0,0,0,0]

twit.stream 'statuses/filter', {track: TERMS, stall_warnings: 'true'}, (stream) ->
  stream.on 'data', (data) ->
    tracked += 1
    process.exit() if (tracked > ITERS && ITERS > 0)

  stream.on 'connect', (msg) ->
    console.log "twitter stream connected"
  stream.on 'disconnect', (msg) ->
    console.log "twitter stream disconnected"
  stream.on 'reconnect', (msg) ->
    console.log "twitter stream reconnected"
  stream.on 'warning', (msg) ->
    console.log "got warning!"
  stream.on 'limit', (msg) ->
    console.log "got limited!"



STATS_REFRESH_RATE=10
logStats = ->
  tracked_period      = tracked-tracked_last
  tracked_period_rate = tracked_period / STATS_REFRESH_RATE
  console.log(
    "Terms tracked: #{tracked} (\u2191#{tracked_period}" +
    ", +#{tracked_period_rate}/sec.), rate limited: #{skipped}" +
    " (+#{skipped-skipped_last})"
  )
  tracked_last = tracked
  skipped_last = skipped

setInterval logStats, STATS_REFRESH_RATE*1000
