package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/darkhelmet/twitterstream"
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

	terms = getEnvOrDefault("TERMS", "a,i")

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

func downloader() {

	client := twitterstream.NewClient(consumerKey, consumerSecret, accessToken, accessSecret)
	log.Println("Tracking terms: " + terms)
	for {
		conn, err := client.Track(terms)
		if err != nil {
			log.Printf("tracking failed: %s", err)
			wait = wait << 1
			log.Printf("waiting for %d seconds before reconnect", min(wait, maxWait))
			time.Sleep(time.Duration(min(wait, maxWait)) * time.Second)
			continue
		} else {
			wait = 1
		}
		decodeTweets(conn)
	}
}

func decodeTweets(conn *twitterstream.Connection) {
	for {
		if _, err := conn.Next(); err == nil {
			tracked++
		} else {
			log.Printf("decoding tweet failed: %s", err)
			conn.Close()
			return
		}
	}
}

func logger() {
	for {
		time.Sleep(time.Duration(logRate) * time.Second)

		period := tracked - trackedLast
		periodRate := period / logRate

		fmt.Printf("Terms tracked: %v (\u2191%v, +%v/sec.)\n", tracked, period, periodRate)

		trackedLast = tracked
	}
}

func main() {
	go logger()
	downloader()
}
