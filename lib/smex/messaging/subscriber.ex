defmodule Smex.Messaging.Subscriber do
  use GenServer

  defstruct queue_name: nil, prefetch: 1, fanout: false, fanout_persistence: true, fanout_queue_suffix: nil, type: nil

  def start_link(module) do
    GenServer.start_link(module, [])
  end

  def start(module) do
    GenServer.start_link(module, [])
  end

  @doc """
  Cancel a running subscriber.
  """
  def cancel(pid) do
    GenServer.call(pid, :cancel)
  end

  defmacro __using__(opts) do

    quote do
      use GenServer

      def init(_opts) do
        Process.link(:erlang.whereis(Smex.Messaging))
        opts = unquote(opts) |> Enum.into %{}
        subscriber = Map.merge(%Smex.Messaging.Subscriber{}, opts)
        channel = Smex.Messaging.channel
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

        AMQP.Queue.declare(channel, queue_name, durable: subscriber.fanout_persistence, auto_delete: !subscriber.fanout_persistence)
        AMQP.Queue.bind(channel, queue_name, exchange_name, routing_key: routing_key)

        if subscriber.fanout do
          AMQP.Exchange.fanout(channel, exchange_name, durable: true, auto_delete: false)
        else
          AMQP.Exchange.direct(channel, exchange_name, durable: true, auto_delete: false)
        end

        consumer_tag = AMQP.Basic.consume(channel, queue_name)

        {:ok, state} = run
        {:ok, %{inner_state: state, subscriber: subscriber, channel: channel}}
      end

      def handle_call(:cancel, _from, state) do
        {:stop, :normal, state}
      end

      def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
        {:noreply, chan}
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
        {:stop, :normal, chan}
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
        {:noreply, chan}
      end

      # Handle rabbitmq messages
      def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered, type: type_hash}}, state) do
        type = Smex.ACL.acl_type_from_hash(type_hash)
        if type == state[:subscriber].type do
          # TODO: Consider supporting updating the state somehow from the class using this module.
          message = %{
            state: state[:inner_state],
            channel: state[:channel],
            payload: type.decode(payload),
            tag: tag,
            redelivered: redelivered,
            process: self
          }
          spawn fn -> consume(message) end
        else
          # TODO: Call handler function. Have default handler function implementation that sends to error queue.
          raise "unsupported ACL type given with hash: #{type_hash} and type: #{type}"
        end
        {:noreply, state}
      end

    end
  end
end
