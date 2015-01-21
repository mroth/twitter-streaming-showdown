defmodule Exfeeder.Stats do
  defstruct [
    tracked: 0, tracked_last: 0,
    skipped: -1, skipped_last: -1
  ]
end

defmodule Exfeeder.Logger do
  use GenServer
  require Logger

  alias Exfeeder.Stats

  @log_rate 5 #log rate in seconds

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## GenServer callbacks
  def init(:ok) do
    :timer.send_interval(@log_rate*1000, :log)
    {:ok, %Stats{}}
  end

  def handle_cast(:increment, stats) do
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
