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
    :ok = Smex.publish("some_test_queue", ACL.Null.new(null: "helloworld"))
    defmodule TestSubscriber do
      use Smex.Messaging.Subscriber, queue_name: "some_test_queue", type: ACL.Null

      def start_link do
        GenServer.start_link(__MODULE__, [])
      end

      def bootup do
        {:ok, %{mystate: true}}
      end

      def consume(_state, channel, payload, tag, _redelivered) do
        assert payload.__struct__ == ACL.Null
        Smex.ack(channel, tag)
      end
    end

    # TODO: I don't think this test actually does anything apart from assert
    # things compile. The only way I can think to get this to work is to
    # somehow have this pid sent into the TestSubscriber on startup and then
    # have the TestSubscriber `send` to that pid when it has actually consumed
    # some messages then I can `receive` here and block until stuff actually
    # happens.
    TestSubscriber.start_link
  end
end
