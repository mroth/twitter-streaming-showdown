#!/bin/zsh -i

# setup ruby version
# assume we have rbenv installed so .ruby-version will be respected
(cd rbfeeder && bundle install)

# setup nodejs version
(cd jsfeeder && npm install)

# setup golang version
go get -u github.com/darkhelmet/twitterstream
(cd gofeeder && go build)
