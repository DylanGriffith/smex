defmodule Smex.Messaging.Publisher do
  defstruct destination: nil, fanout: false

  def publish(publisher = %Smex.Messaging.Publisher{}, payload) do
    type = Map.get(payload, :__struct__)
    publish_raw(publisher, Smex.ACL.acl_type_hash(type), type.encode(payload))
  end

  def publish_raw(publisher, type_hash, raw_payload) do
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

    opts = [type: type_hash, content_type: "application/octet-stream"]

    AMQP.Basic.publish(channel, exchange_name, routing_key, raw_payload, opts)
  end
end
