defmodule Smex.Messaging.Publisher do
  defstruct destination: nil, prefetch: 1, fanout: false, fanout_persistence: true, fanout_queue_suffix: nil

  def publish(publisher = %Smex.Messaging.Publisher{}, payload) do
    {:ok, conn} = AMQP.Connection.open(Smex.conn_string)
    {:ok, chan} = AMQP.Channel.open(conn)

    exchange_name = "smith.#{publisher.destination}"
    routing_key = exchange_name

    exchange = AMQP.Exchange.direct(chan, exchange_name, durable: true, auto_delete: false)

    if !publisher.fanout do
      AMQP.Queue.declare(chan, exchange_name, durable: true, auto_delete: false)
      AMQP.Queue.bind(chan, exchange_name, exchange_name, routing_key: routing_key)
    end

    type = Map.get(payload, :__struct__)

    AMQP.Basic.publish(chan, exchange_name, routing_key, type.encode(payload), type: Smex.ACL.acl_type_hash(type))
  end
end
