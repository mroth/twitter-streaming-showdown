#!/bin/zsh -i

# setup ruby version
# assume we have rbenv installed so .ruby-version will be respected
(cd rbfeeder && bundle install)

# setup nodejs versions
(cd jsfeeder && npm install)
(cd jsfeeder-fork && npm install)

# setup golang version
go get -u github.com/darkhelmet/twitterstream
(cd gofeeder && go build)

# set elixir version
(cd exfeeder && mix do deps.get, deps.compile, compile)
