# Comparing performance of Twitter Streaming API consumption libraries.

This is a big part of what emojitrack-feeder does, so I want to compare the
overhead of various Twitter Streaming API clients, especially since I now have
versions of the EmojiData library for Ruby, NodeJS, and Elixir.

## Feature Comparison
(STILL FILLING THESE IN -- `?` means I need to research it!)

 Library          | GZip | Delimited | RateWarn | StallWarn | EmojiData
 ---------------- | ---- | --------- | -------- | --------- | ---------
 rb-tweetstream   | ?    | x         | √        | √         | √
 rb-twitter       | ?    | x (1)     | x (2)    | √         | √
 js-twit          | ?    | x (3)     | √        | √         | √
 js-nodetwitter   | ?    | x         | x        | x         | √
 go-twitterstream | ?    | ?         | ?        | ?         | x
 ex-twitter       | ?    | x         | ?        | √         | √
 java-hbc         | √    | √         | ?        | ?         | x


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
 - Memory (max memory usage): This number seems grossly inflated but the relative
   comparison should be useful.
 - MsgReceived (socket messages received): I believe this is a good
   approximation for incoming bandwidth consumption. This should be affected by
   gzip support.

### Thoughts
 - socket messages received is ~2x for rb-tweetstream, possibly indicating lack
   of gzip support? no idea why rb-twitter is so insanely high (~5.5x!)

### Full output
```
*** Running benchmark for Ruby - TweetStream gem (with Oj) ***
Setting up a stream to track 7 terms 'a,i,luv'...
Terms tracked: 10073 (↑10073, +1007/sec.), rate limited: 0 (+0)
Terms tracked: 20712 (↑10639, +1063/sec.), rate limited: 0 (+0)
Terms tracked: 31289 (↑10577, +1057/sec.), rate limited: 0 (+0)

RESULTS  7.07s user 0.86s system 22% cpu 35.019 total
-> user:                      7.07s
-> system:                    0.86s
-> cpu:                       22%
-> avg shared (code):         0 KB
-> avg unshared (data/stack): 0 KB
-> total (sum):               0 KB
-> max memory:                37036 MB
-> page faults from disk:     68
-> other page faults:         23508
-> socket msgs received:      117922
-> socket msgs sent:          7

*** Running benchmark for Ruby - Twitter gem ***
Setting up a stream to track 7 terms 'a,i,luv'...
Terms tracked: 9997 (↑9997, +999/sec.), rate limited: 0 (+0)
Terms tracked: 19940 (↑9942, +994/sec.), rate limited: 0 (+0)
Terms tracked: 30277 (↑10337, +1033/sec.), rate limited: 0 (+0)

RESULTS  6.26s user 1.14s system 21% cpu 35.024 total
-> user:                      6.26s
-> system:                    1.14s
-> cpu:                       21%
-> avg shared (code):         0 KB
-> avg unshared (data/stack): 0 KB
-> total (sum):               0 KB
-> max memory:                46260 MB
-> page faults from disk:     2
-> other page faults:         25943
-> socket msgs received:      358062
-> socket msgs sent:          4

*** Running benchmark for NodeJS - Twit module ***
twitter stream connected
Terms tracked: 9770 (↑9770, +977/sec.), rate limited: 0 (+0)
Terms tracked: 19915 (↑10145, +1014.5/sec.), rate limited: 0 (+0)
Terms tracked: 29547 (↑9632, +963.2/sec.), rate limited: 0 (+0)

RESULTS  9.80s user 0.59s system 29% cpu 35.008 total
-> user:                      9.80s
-> system:                    0.59s
-> cpu:                       29%
-> avg shared (code):         0 KB
-> avg unshared (data/stack): 0 KB
-> total (sum):               0 KB
-> max memory:                69520 MB
-> page faults from disk:     141
-> other page faults:         18309
-> socket msgs received:      51258
-> socket msgs sent:          10

*** Running benchmark for NodeJS - NodeTwitter module ***
Terms tracked: 9667 (↑9667, +966.7/sec.), rate limited: 0 (+0)
Terms tracked: 20445 (↑10778, +1077.8/sec.), rate limited: 0 (+0)
Terms tracked: 28923 (↑8478, +847.8/sec.), rate limited: 0 (+0)

RESULTS  4.65s user 0.70s system 15% cpu 35.009 total
-> user:                      4.65s
-> system:                    0.70s
-> cpu:                       15%
-> avg shared (code):         0 KB
-> avg unshared (data/stack): 0 KB
-> total (sum):               0 KB
-> max memory:                68232 MB
-> page faults from disk:     0
-> other page faults:         18600
-> socket msgs received:      67540
-> socket msgs sent:          10

*** Running benchmark for Go - TwitterStream ***
2015/01/21 16:08:26 Tracking terms: a,i,luv
Terms tracked: 9589 (↑9589, +958/sec.)
Terms tracked: 19693 (↑10104, +1010/sec.)
Terms tracked: 29682 (↑9989, +998/sec.)

RESULTS  9.05s user 1.84s system 31% cpu 35.003 total
-> user:                      9.05s
-> system:                    1.84s
-> cpu:                       31%
-> avg shared (code):         0 KB
-> avg unshared (data/stack): 0 KB
-> total (sum):               0 KB
-> max memory:                10292 MB
-> page faults from disk:     45
-> other page faults:         3332
-> socket msgs received:      64506
-> socket msgs sent:          12

*** Running benchmark for Elixir - ExTwitter ***
```
