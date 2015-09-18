defmodule TestSubscriber do
  use Smex.Messaging.Subscriber, queue_name: "some_test_queue", type: ACL.Null

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def run do
    {:ok, %{mystate: true}}
  end

  def consume(%{state: state, channel: channel, payload: payload, tag: tag, redelivered: redelivered, process: process}) do
    Smex.ack(channel, tag)
  end
end
