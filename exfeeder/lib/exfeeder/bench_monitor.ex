defmodule Exfeeder.BenchMonitor do
  @moduledoc """
  Simple ghetto-hack some additional tracking here to quit test run after $ITER
  tweets, as defined by system environment variable.
  """

  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## GenServer callbacks
  def init(:ok) do
    #
    max_iters = case System.get_env("ITERS") do
      s when is_binary(s) -> String.to_integer(s)
      _ -> 0
    end
    if max_iters > 0 do
      Logger.info "Will auto-terminate after processing #{max_iters} tweets."
    end
    {:ok, %{iters: max_iters, ticks: 0}}
  end

  def handle_cast(:tick, state) do
    if state.ticks >= state.iters do
      Logger.info "Processed #{state.ticks} tweets, halting system..."
      System.halt
    end
    {:noreply, %{state | ticks: state.ticks + 1}}
  end

end
