extern crate futures;
extern crate openssl_probe;
extern crate tokio_core;
extern crate tokio_timer;
extern crate twitter_stream;

use futures::{Future, Stream};
use tokio_core::reactor::Core;
use tokio_timer::Timer;
use twitter_stream::{Token, TwitterStreamBuilder};
use twitter_stream::message::StreamMessage;

use std::env;
use std::process;
use std::sync::atomic::{AtomicUsize, Ordering, ATOMIC_USIZE_INIT};
use std::time::Duration;

// there is almost certainly a better way to store this count in the world of futures,
// but whatever for now, just want to get the loop working...
static GLOBAL_TRACKED: AtomicUsize = ATOMIC_USIZE_INIT;
static GLOBAL_SKIPPED: AtomicUsize = ATOMIC_USIZE_INIT;

fn main() {
    // find openssl certs whereever they live, useful for docker multistage build
    openssl_probe::init_ssl_cert_env_vars();

    // load secrets and options from environment
    let consumer_key = env::var("CONSUMER_KEY").expect("CONSUMER_KEY");
    let consumer_secret = env::var("CONSUMER_SECRET").expect("CONSUMER_SECRET");
    let access_token = env::var("ACCESS_TOKEN").expect("ACCESS_TOKEN");
    let access_token_secret = env::var("ACCESS_TOKEN_SECRET").expect("ACCESS_TOKEN_SECRET");
    let token = Token::new(consumer_key, consumer_secret, access_token, access_token_secret);

    let terms = env::var("TERMS").unwrap_or("excelsior".to_string());
    let quit_iters: Option<usize> = match env::var("ITERS") {
            Ok(iters) => iters.parse::<usize>().ok(),
            Err(_)    => None,
    };


    // main decoding event loop
    let mut core = Core::new().unwrap();
    let mut iters: usize   = 0;
    let streamer = TwitterStreamBuilder::filter(&token)
        .handle(&core.handle())
        .track(Some(&terms))
        .timeout(None)
        .replies(true)
        .stall_warnings(true)
        .listen()
        .flatten_stream()
        .for_each(|json| {
            if let Ok(msg) = StreamMessage::from_str(&json) {
                match msg {
                    StreamMessage::Tweet(_tweet) => {
                        GLOBAL_TRACKED.fetch_add(1, Ordering::Relaxed);
                        if let Some(max) = quit_iters {
                            iters += 1; if iters >= max {
                                println!("Achieved iters: {}", iters);
                                process::exit(0);
                            }
                        }
                    },
                    StreamMessage::Limit(limit_msg) => {
                        let skipped = limit_msg.track as usize;
                        GLOBAL_SKIPPED.fetch_add(skipped, Ordering::Relaxed);
                    },
                    x => {
                        println!("Received other msg from stream: {:?}", x)
                    }
                }
            } else {
                // does this ever happen in reality? for now let's panic so we notice!
                // TODO: handle fatal error decoding a message gracefully
                panic!("Failure decoding a stream message!");
            }

            Ok(())
        });

    // status monitor
    let stats_refresh_rate = 10;
    let (mut tracked, mut tracked_last, mut skipped, mut skipped_last) = (0,0,0,0);
    let monitor = Timer::default().interval(Duration::from_secs(stats_refresh_rate))
        .for_each(move |_: ()| {
            tracked = GLOBAL_TRACKED.load(Ordering::Relaxed);
            skipped = GLOBAL_SKIPPED.load(Ordering::Relaxed);

            let period_tracked = tracked - tracked_last;
            let period_rate    = period_tracked / stats_refresh_rate as usize;
            let period_skipped = skipped - skipped_last;

            println!("Terms tracked: {} (\u{2191}{}, +{}/sec.), rate limited: {} (+{})",
                tracked, period_tracked, period_rate, skipped, period_skipped);

            tracked_last = tracked;
            skipped_last = skipped;

            Ok(())
        });


    println!("Setting up a stream to track terms: {}", terms);
    if let Some(qi) = quit_iters {
        println!("Will auto-terminate after processing {} tweets.", qi);
    }
    core.handle().spawn(monitor.map_err(|_| ()));
    core.run(streamer).unwrap();
}

