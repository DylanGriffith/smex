defmodule Smex do
  use Application

  def start(_type, _args) do
    Smex.Supervisor.start_link
  end

  def connect(conn_string) do
    {:ok, conn} = AMQP.Connection.open(conn_string)
    {:ok, %Smex.Messaging.Connection{amqp_connection: conn}}
  end

  def open(connection = %Smex.Messaging.Connection{}) do
    {:ok, chan} = AMQP.Channel.open(connection.amqp_connection)
    {:ok, %Smex.Messaging.Channel{amqp_channel: chan, smex_connection: connection}}
  end

  def subscribe(channel = %Smex.Messaging.Channel{}, opts = %Smex.Messaging.Subscriber{}) do
    Smex.Messaging.Subscriber.subscribe(channel, opts)
  end

  def subscribe(channel = %Smex.Messaging.Channel{}, opts) when is_list(opts) do
    subscribe(channel, Map.merge(%Smex.Messaging.Subscriber{}, Enum.into(opts, %{})))
  end

  @doc """
  Publish to a specific exchange.
  """
  def publish(channel = %Smex.Messaging.Channel{}, payload, publisher = %Smex.Messaging.Publisher{}) do
    Smex.Messaging.Publisher.publish(channel, publisher, payload)
  end

  @doc """
  Publish to a specific exchange.
  """
  def publish(channel = %Smex.Messaging.Channel{}, payload, opts) do
    publisher = Map.merge(%Smex.Messaging.Publisher{}, Enum.into(opts, %{}))
    Smex.Messaging.Publisher.publish(channel, publisher, payload)
  end

  @doc """
  Ack the message.
  """
  def ack(%Smex.Messaging.Channel{amqp_channel: channel}, %{delivery_tag: delivery_tag}) do
    AMQP.Basic.ack(channel, delivery_tag)
  end
end
