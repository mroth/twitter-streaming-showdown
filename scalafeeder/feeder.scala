import com.google.common.collect.Lists
import com.twitter.hbc.ClientBuilder
import com.twitter.hbc.core._
import com.twitter.hbc.core.endpoint.StatusesFilterEndpoint
import com.twitter.hbc.core.event.Event
import com.twitter.hbc.core.processor.StringDelimitedProcessor
import com.twitter.hbc.httpclient.auth.OAuth1
import java.util.concurrent._
import scala.collection.JavaConversions._

object Feeder {
  val msgQueue   = new LinkedBlockingQueue[String](100000)
  val eventQueue = new LinkedBlockingQueue[Event](1000)

  val hosebirdHosts = new HttpHosts(Constants.STREAM_HOST)
  val hosebirdEndpoint = new StatusesFilterEndpoint()

  val terms = System.getenv("TERMS").split(",").toList
  hosebirdEndpoint.trackTerms(terms)

  val hosebirdAuth = new OAuth1(
    System.getenv("CONSUMER_KEY"),
    System.getenv("CONSUMER_SECRET"),
    System.getenv("ACCESS_TOKEN"),
    System.getenv("ACCESS_TOKEN_SECRET")
  )
  // iterations for benchmark run
  val iters = sys.env.get("ITERS").getOrElse("0").toInt

  // PERIODIC MONITORING
  // not sure what idiomatic way to do this in scala should be, its probably not
  // by reading global variables like this though! a much better model would be
  // a full actor model like I have in the Elixir code, but need to find a
  // better Scala tutorial to do so...
  val statsRefreshRate = 10
  var (tracked,skipped,tracked_last,skipped_last) = (0,0,0,0)
  val report = new Runnable {
    def run() {
      val period = tracked - tracked_last
      val period_rate = period / statsRefreshRate
      println(
        s"Terms tracked: ${tracked} (\u2191${period}" +
        s", +${period_rate}/sec.), rate limited: ${skipped}" +
        s" (+${skipped - skipped_last})"
      )
      tracked_last = tracked
      skipped_last = skipped
    }
  }
  val ex = new ScheduledThreadPoolExecutor(1)
  val f = ex.scheduleAtFixedRate(report, statsRefreshRate, statsRefreshRate, TimeUnit.SECONDS)

  // MAIN EVENT LOOP
  def main(args: Array[String]) {
    val client = new ClientBuilder()
                      .name("streamer-test-1")
                      .gzipEnabled(true) // TODO: hi!
                      .hosts(hosebirdHosts)
                      .authentication(hosebirdAuth)
                      .endpoint(hosebirdEndpoint)
                      .processor(new StringDelimitedProcessor(msgQueue))
                      .eventMessageQueue(eventQueue)
                      .build()

    println(s"Setting up a stream to track ${terms}...")
    client.connect()

    println(s"Will auto-terminate after processing ${iters} tweets.")
    for(n <- 1 to iters) {
      val msg = msgQueue.take()
      tracked += 1
    }

    println("Done, stopping!")

    //why is it so hard to exit without an error?
    f.cancel(true)
    ex.shutdownNow()
    client.stop()

    sys.exit()
  }
}
