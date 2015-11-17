defmodule Smex.Messaging.Subscriber do
  use GenServer

  defstruct queue_name: nil, prefetch: 1, fanout: false, fanout_persistence: true, fanout_queue_suffix: nil

  def subscribe(%Smex.Messaging.Channel{amqp_channel: channel}, subscriber = %Smex.Messaging.Subscriber{}) do
    AMQP.Basic.qos(channel, prefetch_count: subscriber.prefetch)

    exchange_name = "smith.#{subscriber.queue_name}"
    if subscriber.fanout do
      if subscriber.fanout_persistence do
        if !subscriber.fanout_queue_suffix do
          raise "fanout_queue_suffix required unless fanout_persistence=false"
        end
        queue_name = "#{exchange_name}.#{subscriber.fanout_queue_suffix}"
      else
        # Here we use a random queue name because we don't care about it
        # being persistent
        queue_name = ""
      end
    else
      queue_name = exchange_name
    end

    routing_key = exchange_name

    if subscriber.fanout do
      AMQP.Exchange.fanout(channel, exchange_name, durable: true, auto_delete: false)
    else
      AMQP.Exchange.direct(channel, exchange_name, durable: true, auto_delete: false)
    end

    AMQP.Queue.declare(channel, queue_name, durable: subscriber.fanout_persistence, auto_delete: !subscriber.fanout_persistence)
    AMQP.Queue.bind(channel, queue_name, exchange_name, routing_key: routing_key)

    if subscriber.fanout do
      AMQP.Exchange.fanout(channel, exchange_name, durable: true, auto_delete: false)
    else
      AMQP.Exchange.direct(channel, exchange_name, durable: true, auto_delete: false)
    end

    consumer_tag = AMQP.Basic.consume(channel, queue_name)
  end
end
