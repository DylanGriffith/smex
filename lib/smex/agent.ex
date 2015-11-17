defmodule Smex.Agent do
  defmacro __using__(_opts) do
    quote do
      require Logger
      use AMQP

      def handle_call(:cancel, _from, state) do
        {:stop, :normal, state}
      end

      def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
        {:noreply, state}
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
        {:stop, :normal, state}
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
        {:noreply, state}
      end

      # Handle rabbitmq messages
      def handle_info({:basic_deliver, payload, meta = %{delivery_tag: delivery_tag, redelivered: redelivered, type: type_hash}}, state) do
        Logger.debug("Received payload with type_hash: #{type_hash}")
        type = Smex.ACL.acl_type_from_hash(type_hash)
        if type do
          GenServer.cast(self, {:smex_message, type.decode(payload), meta})
        else
          Logger.error("Received unknown type hash: #{type_hash}")
        end
        {:noreply, state}
      end
    end
  end
end
