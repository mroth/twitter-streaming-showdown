#!/usr/bin/env zsh -i

# defaults, can be overriden via .env
RUN_DURATION=35s
TERMS='a,i,luv'

TIMEFMT=$'\n'\
'RESULTS  %U user %S system %P cpu %*E total'$'\n'\
'-> user:                      %U'$'\n'\
'-> system:                    %S'$'\n'\
'-> cpu:                       %P'$'\n'\
'-> avg shared (code):         %X KB'$'\n'\
'-> avg unshared (data/stack): %D KB'$'\n'\
'-> total (sum):               %K KB'$'\n'\
'-> max memory:                %M MB'$'\n'\
'-> page faults from disk:     %F'$'\n'\
'-> other page faults:         %R'$'\n'\
'-> socket msgs received:      %r'$'\n'\
'-> socket msgs sent:          %s'$'\n'


dotenv_load ()  {
  if [[ -f $PWD/.env ]]; then
    source $PWD/.env
  else
    echo "Warning -- was unable to source .env file"
  fi
}

setup () {
  # load vars from .env
  dotenv_load

  # export twitter credentials (in case we overrode them from .env)
  export CONSUMER_KEY CONSUMER_SECRET
  export ACCESS_TOKEN ACCESS_TOKEN_SECRET

  # export preferences to subcmds
  export TERMS
}

bench () {
  echo "*** Running benchmark for $3 ***"
  (cd $1 && eval "time gtimeout $RUN_DURATION $2")
}

# bench top
setup
bench "rbfeeder" "bundle exec ruby feeder-tweetstream.rb" "Ruby - TweetStream gem (with Oj)"
bench "rbfeeder" "bundle exec ruby feeder-twitter.rb"     "Ruby - Twitter gem"
bench "jsfeeder" "coffee feeder-twit.coffee"              "NodeJS - Twit module"
bench "jsfeeder" "coffee feeder-twitter.coffee"           "NodeJS - NodeTwitter module"
bench "gofeeder" "./gofeeder"                             "Go - TwitterStream"
bench "exfeeder" "./exfeeder"                             "Elixir - ExTwitter"
