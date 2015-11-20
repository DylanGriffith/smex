Smex
====

A library for simplify the sending of protocol buffers over rabbitmq. This is
intended to allow compatible communication with [the more comprehensive ruby
framework Smith](https://github.com/filterfish/smith2) but this can be used on
it's own as a way of using protocol buffers and rabbitmq.

## Usage

### Add Dependendencies & Application
Add this library to your dependendencies like `{:smex, github: "DylanGriffith/smex"}`. Then add `:smex` to your applications.

### Configure The Location Of Your Protocol Buffers
You will also need your own protocol buffers in some directory then configure
that in `config/config.exs` like:

```elixir
config :smex,
  protobuf_dir: "/path/to/my/protobufs"
```

This directory can contain any `.proto` files and they will automatically be
compiled. For the purposes of the following examples you can just have a single
file call in the directory called `greeting.proto` containing:

```protobuf
package PB;

message Greeting {
  required string greeting = 1;
}
```

All protocol buffers are compiled to structs.

### Sending Messages
Now your ready to start sending messages:

```elixir
{:ok, connection} = Smex.connect("amqp://guest:guest@localhost")

{:ok, channel} = Smex.open(connection)
:ok = Smex.publish(channel, PB.Greeting.new(greeting: "Hello, World!"), destination: "smex.test.some_test_queue")
```

### Subscribing In A GenServer
Then if you want to subscribe to messages you can create a simple `GenServer`
like:

```elixir
defmodule MyServer do
  use GenServer
  use Smex.Agent

  def init(_opts) do
    # Setup the connection
    {:ok, connection} = Smex.connect("amqp://guest:guest@localhost")
    {:ok, channel} = Smex.open(connection)

    # Subscribe to desired queue
    consumer_tag = Smex.subscribe(channel, queue_name: "smex.test.some_test_queue")

    # Standard GenServer return
    {:ok, %{connection: connection, channel: channel, consumer_tag: consumer_tag}}
  end

  # Pattern match just the protocol buffer types you expect on this queue
  def handle_cast({:smex_message, m = %PB.Greeting{}, meta}, state = %{channel: channel}) do
    IO.puts("Received a PB.Greeting:")
    IO.inspect(m)

    # Acknowledge receipt of message. This is necessary.
    Smex.ack(channel, meta)

    # Standard GenServer return
    {:stop, :normal, state}
  end
end
```

Since this is just a standard `GenServer` you can add to any supervision tree
you want or do any other stuff you can do with a `GenServer`.
