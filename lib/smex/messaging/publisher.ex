defmodule Smex.Messaging.Publisher do
  defstruct destination: nil, prefetch: 1, fanout: false, fanout_persistence: true, fanout_queue_suffix: nil

  def publish(publisher = %Smex.Messaging.Publisher{}, payload) do
    channel = Smex.Messaging.channel

    exchange_name = "smith.#{publisher.destination}"
    routing_key = exchange_name

    if publisher.fanout do
      AMQP.Exchange.fanout(channel, exchange_name, durable: true, auto_delete: false)
    else
      AMQP.Exchange.direct(channel, exchange_name, durable: true, auto_delete: false)
    end

    if !publisher.fanout do
      AMQP.Queue.declare(channel, exchange_name, durable: true, auto_delete: false)
      AMQP.Queue.bind(channel, exchange_name, exchange_name, routing_key: routing_key)
    end

    type = Map.get(payload, :__struct__)

    opts = [type: Smex.ACL.acl_type_hash(type), content_type: "application/octet-stream"]

    AMQP.Basic.publish(channel, exchange_name, routing_key, type.encode(payload), opts)
  end
end
