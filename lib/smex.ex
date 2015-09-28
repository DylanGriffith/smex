defmodule Smex do
  use Application

  def start(_type, _args) do
    Smex.Supervisor.start_link
  end

  @doc """
  Publish to a specific exchange.
  """
  def publish(destination, payload, opts \\ []) do
    opts = opts |> Keyword.put(:destination, destination)|> Enum.into %{}
    publisher = Map.merge(%Smex.Messaging.Publisher{}, opts)
    Smex.Messaging.Publisher.publish(publisher, payload)
  end

  @doc """
  Ack the message.
  """
  def ack(channel, tag) do
    AMQP.Basic.ack(channel, tag)
  end

  @doc """
  Connection string for rabbitmq.
  """
  def conn_string do
    Application.get_env(:smex, Smex)[:conn_string] || "amqp://guest:guest@localhost"
  end
end
