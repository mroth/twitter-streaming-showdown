defmodule Exfeeder.Stats do
  defstruct [
    tracked: 0, tracked_last: 0,
    skipped: 0, skipped_last: 0,
    bench_max: -1
  ]
end

defmodule Exfeeder.Logger do
  use GenServer
  require Logger

  alias Exfeeder.Stats

  @log_rate 10 #log rate in seconds

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## GenServer callbacks
  def init(:ok) do
    :timer.send_interval(@log_rate*1000, :log)
    # {:ok, %Stats{}} # previous return before ghetto-hack

    # ghetto-hack some additional tracking here to quit test run after N tweets.
    max_iters = case System.get_env("ITERS") do
      s when is_binary(s) -> String.to_integer(s)
      _ -> 0
    end
    if max_iters > 0 do
      Logger.info "Will auto-terminate after processing #{max_iters} tweets."
    end
    {:ok, %Stats{bench_max: max_iters}}
  end

  def handle_cast(:increment, stats) do
    if stats.tracked > stats.bench_max do
      # Application.stop(:exfeeder)
      System.halt
    end

    {:noreply, %{stats | tracked: stats.tracked + 1}}
  end

  def handle_cast(:skip, stats) do
    {:noreply, %{stats | skipped: stats.skipped + 1}}
  end

  def handle_info(:log, stats) do
    period      = stats.tracked - stats.tracked_last
    period_rate = period / @log_rate

    Logger.info "Terms tracked: #{stats.tracked} (\x{2191}#{period}" <>
                ", +#{period_rate}/sec.), rate limited: #{stats.skipped}" <>
                " (+#{stats.skipped - stats.skipped_last})"

    { :noreply,
      %{stats | tracked_last: stats.tracked,
                skipped_last: stats.skipped } }
  end

end
