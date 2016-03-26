package main

import (
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"runtime/pprof"
	"strconv"
	"time"

	"github.com/ChimeraCoder/anaconda"
)

func getEnvOrDefault(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" && defaultValue != "" {
		return defaultValue
	}
	return value
}

var (
	consumerKey    = os.Getenv("CONSUMER_KEY")
	consumerSecret = os.Getenv("CONSUMER_SECRET")
	accessToken    = os.Getenv("ACCESS_TOKEN")
	accessSecret   = os.Getenv("ACCESS_TOKEN_SECRET")

	terms    = getEnvOrDefault("TERMS", "a,i")
	iters, _ = strconv.Atoi(getEnvOrDefault("ITERS", "0"))

	wait    = 1
	maxWait = 600

	tracked     = 0
	skipped     = 0
	trackedLast = 0
	skippedLast = 0

	logRate = 10 // in seconds
)

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func twitterApi() *anaconda.TwitterApi {
	anaconda.SetConsumerKey(consumerKey)
	anaconda.SetConsumerSecret(consumerSecret)
	api := anaconda.NewTwitterApi(accessToken, accessSecret)
	return api
}

func downloader() {
	api := twitterApi()

	fmt.Println("Setting up a stream to track terms: " + terms)
	if iters > 0 {
		fmt.Printf("Will auto-terminate after processing %d tweets.\n", iters)
	}

	v := url.Values{}
	v.Set("track", terms)
	v.Set("stall_warnings", "true")
	stream := api.PublicStreamFilter(v)

	for m := range stream.C {
		switch m.(type) {
		case anaconda.Tweet:
			tracked++
			if iters > 0 && tracked > iters {
				stream.Stop()
			}
			// t := m.(anaconda.Tweet)
			// fmt.Println(t.Id)
		case anaconda.StallWarning:
			fmt.Println("Got a stall warning! falling behind!")
		default:
			fmt.Println("got something else!")
		}
	}
}

func logger() {
	for {
		time.Sleep(time.Duration(logRate) * time.Second)

		period := tracked - trackedLast
		periodRate := period / logRate

		log.Printf("Terms tracked: %v (\u2191%v, +%v/sec.)\n", tracked, period, periodRate)

		trackedLast = tracked
	}
}

func main() {
	// http://blog.golang.org/profiling-go-programs
	var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")
	flag.Parse()
	if *cpuprofile != "" {
		f, err := os.Create(*cpuprofile)
		if err != nil {
			log.Fatal(err)
		}
		pprof.StartCPUProfile(f)
		defer pprof.StopCPUProfile()
	}

	go logger()
	downloader()
}
