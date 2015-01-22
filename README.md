# Comparing performance of Twitter Streaming API consumption libraries.

This is a big part of what emojitrack-feeder does, so I want to compare the
overhead of various Twitter Streaming API clients, especially since I now have
versions of the EmojiData library for Ruby, NodeJS, and Elixir.

## Feature Comparison
(STILL FILLING THESE IN -- `?` means I need to research it!)

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
 - GZip: gzipped stream reading support
 - Delimited: support for `delimited: length` stream parsing
 - RateWarn*: parses LIMIT status messages from the Streaming API so you can
   know when tweets were skipped due to a limit of some kind.
 - StallWarn*: parses Stall Warnings from the Streaming API.
 - EmojiData*: does an EmojiData library exist for this platform yet?

Categories with an asterisk are _required_ to be a real candidate for future
versions of emojitrack-feeder. (The others are nice to have that could
contribute to performance.)

Notes:
 1. Inquired about via issue in sferik/twitter#631.
 2. Requested via issue in sferik/twitter#649.
 3. PR adding this in ttezel/twit#150.

## Benchmarks

### Summary

 Library          | User  | Sys  | CPU | Memory | MsgReceived
 ---------------- | ----- | ---- | --- | -----: | ----------:
 rb-tweetstream   | 7.07  | 0.86 | 22% |  37036 |     117922
 rb-twitter       | 6.26  | 1.14 | 21% |  46260 |     358062
 js-twit          | 9.80  | 0.59 | 29% |  69520 |      51258
 js-nodetwitter   | 4.65  | 0.70 | 15% |  68232 |      67540
 go-twitterstream | 9.05  | 1.84 | 31% |  10292 |      64506
 ex-twitter       |
 java-hbc         |

Decoding the output:
 - User (user clock time)
 - Sys (system clock time)
 - CPU (CPU percentage)
 - Memory (max memory usage)
 - MsgReceived (socket messages received): I initially believed this was a good
   approximation for incoming bandwidth consumption. It is not at all. Need a
   better way to compare to show the affects of gzip support.

### Thoughts
 - I can't seem to get bytes-received via `time`, and socket msgs received isn't
   actually helpful, so might need another way to profile bandwidth usage. From
   manually looking at nettop, clients without gzip support read about ~150MB
   during these tests, and those with it about ~45MB.

### Full benchmark output
Full output of the tests runs (with more stats) can be found in the
[RESULTS.txt](/RESULTS.txt) file.
