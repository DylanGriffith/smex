defmodule Smex.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    # TODO: Fix supervision tree so that a restart to AMQP causes a restart to
    # Smex.Messaging and a restart to Smex.Messaging triggers a restart to any
    # Smex.Messaging.Publisher. Probably need Smex.Messaging.Publisher.start*
    # to add it to supervision tree somehow. Or start_link could link itself
    # against the already running Smex.Messaging.
    children = [
      worker(Smex.ACL, []),
      worker(Smex.Messaging, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
