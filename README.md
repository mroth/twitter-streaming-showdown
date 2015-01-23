# Comparing performance of Twitter Streaming API consumption libraries.
Streaming data from Twitter is a a big part of what emojitrack-feeder does, so I
want to compare the overhead of various Twitter Streaming API clients,
especially since I now have versions of the EmojiData library for Ruby, NodeJS,
and Elixir.

My hopes is I will learn something about good options for future potential
platform migrations for emojitrack-feeder, but also shed some light on areas of
potential improvements in all the libraries, since I would love to see the
overall ecosystem improve here.

Compared:

 - TweetStream (Ruby gem)
 - Twitter (Ruby gem)
 - node-twitter (NodeJS module)
 - Twit (NodeJS module)
 - TwitterStream (Go package)
 - ExTwitter (Elixir module)
 - Hosebird (Java module, official from Twitter)

NOTE: This is still in progress! Please don't consider this "published" just
yet.

## Feature Comparison

 Library          | GZip | Delimited | RateWarn | StallWarn | EmojiData
 ---------------- | ---- | --------- | -------- | --------- | ---------
 rb-tweetstream   | x    | x         | √        | √         | √
 rb-twitter       | x    | x (1)     | x (2)    | √         | √
 js-twit          | ?    | x (3)     | √        | √         | √
 js-nodetwitter   | ?    | x         | x        | x         | √
 go-twitterstream | ?    | x         | x        | x         | x
 ex-twitter       | ?    | x         | √        | √         | √
 java-hbc         | √    | √         | √        | √         | x


Definitions:
 - GZip: gzipped stream reading support. Potential to drastically reduce
   bandwidth requirements for high throughput streams.
 - Delimited: support for `delimited: length` stream parsing. Can increase
   stream buffer parsing efficiency.
 - RateWarn*: parses LIMIT status messages from the Streaming API so you can
   know when tweets were withheld due to a limit of some kind.
 - StallWarn*: parses Stall Warnings from the Streaming API.
 - EmojiData*: does my EmojiData library exist for this platform yet?

Categories with an asterisk are _required_ to be a real candidate for future
versions of emojitrack-feeder. (The others are nice to have that could
contribute to performance.)

Notes:
 1. Inquired about via issue in sferik/twitter#631.
 2. Requested via issue in sferik/twitter#649.
 3. PR adding this in ttezel/twit#150.

## Benchmarks
My test programs connect to the Twitter Streaming API and do a filter keyword
track on the ten most common words in the English language (which should be
more than plenty to saturate results!) and then disconnect and quit once they
have processed 250,000 tweets.

I try to emulate periodic stats output of emojitrack-feeder while running.

It's worth noting my Twitter dev account has elevated partner access, so if you
are running these benchmarks on your own key you will probably get different
results.


### Summary
Results from a quad-core 4.0GHz Core i7 machine with 32GB of RAM on a 100Mbps
fiber internet connection.

 Library            | User   | Sys   | CPU | Memory | MsgReceived | BWApprox
 ------------------ | ------ | ----- | --- | -----: | ----------: | -------:
 rb-tweetstream     |  43.46 |  3.55 | 29% |  44144 |     465857  | ~0.94 GB
 rb-twitter (MRI)   |  40.26 |  6.67 | 28% |  56400 |    2730766  | ~0.94 GB
 rb-twitter (JRuby) |  60.91 |  4.87 | 39% | 349080 |     463234  | ~0.95 GB
 js-twit            |  72.63 |  3.96 | 47% |  93688 |     410594  | ~0.94 GB
 js-twit _(fork*)_  |  36.33 |  4.82 | 25% | 103712 |     536869  | ~0.94 GB
 js-nodetwitter     |  32.08 |  4.64 | 22% |  93224 |     534422  | ~0.95 GB
 go-twitterstream   |  57.86 |  8.64 | 40% |  10468 |     439641  | ~0.35 GB
 ex-twitter         | 119.23 | 16.42 | 83% |  49840 |     832032  | ~0.96 GB
 scala-hbc          |  87.69 |  7.54 | 56% | 538876 |    2654263  | ~0.35 GB

Decoding the output:
 - User (user clock time)
 - Sys (system clock time)
 - CPU (CPU percentage)
 - Memory (max memory usage in KB)
 - MsgReceived (socket messages received): I initially believed this was a good
   approximation for incoming bandwidth consumption. It is not at all. Need a
   better way to compare to show the affects of gzip support.
 - BWApprox (approximate bandwidth): I haven't figured out how to have the shell
   track this in a controlled way yet, so these numbers are very approximate
   based on me manually watching the process run in `nettop` for now.

### Notes
 - I can't seem to get bytes-received via `time`, and socket msgs received isn't
   actually helpful, so might need another way to profile bandwidth usage. From
   manually looking at nettop, clients without gzip support read about ~150MB
   during these tests, and those with it about ~45MB.

### Full benchmark output
Full output of the tests runs (with more stats) can be found in the
[RESULTS.txt](/RESULTS.txt) file.

## Conclusions/Thoughts (In Progress)

 - Robust tests and error handling is really important.  For example, if you
   were just looking at the number sin benchmarks, node-twitter might look good.
   Sure, it's fairly fast **but** it accomplishes this by doing almost nothing,
   its error handling appears to be "hard crash with a stack trace" on even
   routine events messages from the Streaming API, which obviously is not
   acceptable for production usage (it was unreliable enough to require
   re-running these benchmarks a few times before it made it through without
   crashing!).

 - As seen in my fork of twit, a little bit of performance tuning can go a long
   way.  I'd love to see more work done on all these libraries as I suspect they
   have a lot of headroom.

 - The bandwidth savings from gzip encoding are significant, and could be make
   or break for high throughput streams (in this case, it reduced incoming
   bandwidth requirements from 30MB/s to 10MB/s).

 - It's not clear to me why the VM based languages (JRuby/JVM, Elixir/BEAM,
   Scala/JVM) appear to have higher CPU usage, when the common belief is that
   they should be faster. Is there something going on here that my metrics end
   up measuring overhead improperly?  Help would be appreciated!
