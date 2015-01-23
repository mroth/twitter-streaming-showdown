defmodule Exfeeder.Feeder do
  use GenServer
  require Logger

  @doc """
  Starts the feeder.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## GenServer callbacks
  def init(:ok) do

    terms = System.get_env("TERMS")
    Logger.info "Setting up a stream to track terms: #{terms}"

    pid = spawn(fn ->

      stream = ExTwitter.stream_filter(track: terms, receive_messages: true)
      for message <- stream do
        case message do
          _tweet = %ExTwitter.Model.Tweet{} ->
            GenServer.cast(Exfeeder.Logger, :increment)
            GenServer.cast(Exfeeder.BenchMonitor, :tick)

          deleted_tweet = %ExTwitter.Model.DeletedTweet{} ->
            Logger.info "deleted tweet = #{deleted_tweet.status['id']}"

          limit = %ExTwitter.Model.Limit{} ->
            Logger.warn "limit = #{limit.track}"
            # TODO: send me to the logger once we know how to decode

          stall_warning = %ExTwitter.Model.StallWarning{} ->
            Logger.warn "stall warning = #{stall_warning.code}"

          _ ->
            Logger.error "*** UNKNOWN MESSAGE!!!! check me out for PR ***"
            IO.inspect message
        end
      end

    end)

    {:ok, pid}
  end

end
