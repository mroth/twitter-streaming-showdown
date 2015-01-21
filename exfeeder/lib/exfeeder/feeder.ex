defmodule Exfeeder.Feeder do
  use GenServer
  require Logger

  @doc """
  Starts the feeder.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## GenServer callbacks
  def init(:ok) do

    pid = spawn(fn ->
      ExTwitter.configure(
         consumer_key:        System.get_env("CONSUMER_KEY"),
         consumer_secret:     System.get_env("CONSUMER_SECRET"),
         access_token:        System.get_env("ACCESS_TOKEN"),
         access_token_secret: System.get_env("ACCESS_TOKEN_SECRET")
      )

      terms  = System.get_env("TERMS")
      Logger.info "Tracking terms: #{terms}"

      stream = ExTwitter.stream_filter(track: terms, receive_messages: true)
      for message <- stream do
        case message do
          _tweet = %ExTwitter.Model.Tweet{} ->
            GenServer.cast(Exfeeder.Logger, :increment)

          deleted_tweet = %ExTwitter.Model.DeletedTweet{} ->
            Logger.info "deleted tweet = #{deleted_tweet.status["id"]}"

          limit = %ExTwitter.Model.Limit{} ->
            Logger.warn "limit = #{limit.track}"

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
