defmodule TherapyServer.Application do
  use Application

  def start(_type, _args) do
    children = [
      {TherapyServer, 1234}
    ]

    opts = [strategy: :one_for_one, name: TherapyServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

