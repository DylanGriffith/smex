defmodule Smex.AgentTest do
  use ExUnit.Case

  test '#publish/subscribe' do
    {:ok, connection} = Smex.connect("amqp://guest:guest@localhost")
    {:ok, channel} = Smex.open(connection)

    defmodule TestSubscriberAgent do
      use GenServer
      use Smex.Agent

      def init(_opts) do
        {:ok, connection} = Smex.connect("amqp://guest:guest@localhost")
        {:ok, channel} = Smex.open(connection)
        consumer_tag = Smex.subscribe(channel, queue_name: "smex.test.some_test_queue")
        {:ok, %{connection: connection, channel: channel, consumer_tag: consumer_tag}}
      end

      def handle_cast({:smex_message, m = %ACL.Null{}, meta}, state = %{channel: channel}) do
        assert m.__struct__ == ACL.Null
        assert m.null == "helloworld"
        Smex.ack(channel, meta)
        {:stop, :normal, state}
      end
    end

    {:ok, pid} = GenServer.start(TestSubscriberAgent, [])
    ref = Process.monitor(pid)

    :ok = Smex.publish(channel, ACL.Null.new(null: "helloworld"), destination: "smex.test.some_test_queue")
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
  end

  test '#publish/subscribe with fanout' do
    {:ok, connection} = Smex.connect("amqp://guest:guest@localhost")
    {:ok, channel} = Smex.open(connection)

    defmodule TestSubscriberFanoutAgent do
      use GenServer
      use Smex.Agent

      def init(_opts) do
        {:ok, connection} = Smex.connect("amqp://guest:guest@localhost")
        {:ok, channel} = Smex.open(connection)
        consumer_tag = Smex.subscribe(channel, queue_name: "smex.test.some_fanout_test_queue", fanout: true, fanout_queue_suffix: "suffix")
        {:ok, %{connection: connection, channel: channel, consumer_tag: consumer_tag}}
      end

      def handle_cast({:smex_message, m = %ACL.Null{}, meta}, state = %{channel: channel}) do
        assert m.__struct__ == ACL.Null
        assert m.null == "helloworld"
        Smex.ack(channel, meta)
        {:stop, :normal, state}
      end
    end

    {:ok, pid} = GenServer.start(TestSubscriberFanoutAgent, [])
    :ok = Smex.publish(channel, ACL.Null.new(null: "helloworld"), [destination: "smex.test.some_fanout_test_queue", fanout: true])
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
  end
end
