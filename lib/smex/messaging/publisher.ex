defmodule Smex.Messaging.Publisher do
  defstruct exchange_name: nil, prefetch: 1, fanout: false, fanout_persistence: true, fanout_queue_suffix: nil

  def publish(publisher = %Smex.Messaging.Publisher{}, payload) do
    {:ok, conn} = AMQP.Connection.open(Smex.conn_string)
    {:ok, chan} = AMQP.Channel.open(conn)
    exchange = AMQP.Exchange.direct(chan, publisher.exchange_name, durable: true, auto_delete: false)

    routing_key = publisher.exchange_name

    if !publisher.fanout do
      AMQP.Queue.declare(chan, publisher.exchange_name, durable: true, auto_delete: false)
      AMQP.Queue.bind(chan, publisher.exchange_name, publisher.exchange_name, routing_key: routing_key)
    end

    type = Map.get(payload, :__struct__)
    AMQP.Basic.publish(chan, publisher.exchange_name, routing_key, type.encode(payload))
  end
end
