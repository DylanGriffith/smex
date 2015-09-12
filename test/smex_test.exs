defmodule SmexTest do
  use ExUnit.Case

  test "#publish sends to queue" do
    message = ACL.Null.new(null: "helloworld")
    assert Smex.publish("some_test_queue", message) == :ok
    assert Smex.publish("some_test_queue", message) == :ok
    assert Smex.publish("some_test_queue", message) == :ok
    assert Smex.publish("some_test_queue", message) == :ok
    assert Smex.publish("some_test_queue", message) == :ok
  end

  test "#subscribe subscribes to queue" do
    :ok = Smex.publish("some_test_queue", ACL.Null.new(null: "helloworld"))
    defmodule TestSubscriber do
      use Smex.Messaging.Subscriber, queue_name: "some_test_queue", type: ACL.Null

      def start do
        Smex.Messaging.Subscriber.start(__MODULE__)
      end

      def bootup do
        {:ok, %{mystate: true}}
      end

      def consume(%{channel: channel, payload: payload, tag: tag, process: process}) do
        assert payload.__struct__ == ACL.Null
        Smex.ack(channel, tag)
        Smex.Messaging.Subscriber.cancel(process)
      end
    end

    {:ok, subscriber} = TestSubscriber.start
    ref  = Process.monitor(subscriber)
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
  end

  test "fanout exchanges" do
    :ok = Smex.publish("some_fanout_test_queue", ACL.Null.new(null: "helloworld"), fanout: true)
    defmodule TestSubscriberFanout do
      use Smex.Messaging.Subscriber, queue_name: "some_fanout_test_queue", type: ACL.Null, fanout: true, fanout_queue_suffix: "the_suffix"

      def start do
        Smex.Messaging.Subscriber.start(__MODULE__)
      end

      def bootup do
        {:ok, %{mystate: true}}
      end

      def consume(%{channel: channel, payload: payload, tag: tag, process: process}) do
        assert payload.__struct__ == ACL.Null
        Smex.ack(channel, tag)
        Smex.Messaging.Subscriber.cancel(process)
      end
    end

    {:ok, subscriber} = TestSubscriberFanout.start
    ref  = Process.monitor(subscriber)
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
  end
end
