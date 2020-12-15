defmodule Ral.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4004")

    children = [
      # Starts a worker by calling: Ral.Worker.start_link(arg)
      # {Ral.Worker, arg}
      Ral.ETS,
      #{Ral.Server, [port]}
      {Task.Supervisor, name: Ral.Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Ral.Server.accept(port) end}, restart: :permanent)
      # {Task.Supervisor, name: Ral.TaskSupervisor},
      # Supervisor.child_spec({Task, fn -> Ral.Server.accept(port) end}, restart: :permanent)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ral.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
