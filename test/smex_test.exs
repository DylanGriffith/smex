defmodule SmexTest do
  use ExUnit.Case

  test "#send sends to queue" do
    :ok = Smex.publish("some_test_queue_foobar", ACL.Null.new(null: "helloworld"))
  end

  test "#receive subscribes to queue" do
    Smex.subscribe("some_test_queue", [type: ACL.Null], fn (payload, receiver) ->
      IO.inspect(payload)
      Smex.ack(receiver)
    end)
  end
end
