defmodule Smex.Messaging do
  use GenServer

  # Public API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # TODO: We need to support publishing (and probably subscribing) to multiple
  # rabbitmq exchanges. So this singleton needs to go or we need to be able to
  # override and get our own Smex.Connection and use that with publish etc.
  def channel do
    GenServer.call(__MODULE__, :channel)
  end

  # GenServer implementation
  def init(_opts) do
    {:ok, connection} = AMQP.Connection.open(Smex.conn_string)
    Process.link(connection.pid)
    {:ok, channel} = AMQP.Channel.open(connection)
    Process.link(channel.pid)
    {:ok, {connection, channel}}
  end

  def handle_call(:channel, _from, state = {_connection = %AMQP.Connection{}, channel = %AMQP.Channel{}}) do
    {:reply, channel, state}
  end
end
