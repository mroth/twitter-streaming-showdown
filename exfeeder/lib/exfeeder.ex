defmodule Exfeeder do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Exfeeder.Feeder, []),
      worker(Exfeeder.Logger, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exfeeder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def main(_args) do
    :timer.sleep(:infinity)
  end

end
