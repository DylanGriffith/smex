Smex
====

An Elixir library for simplifying the sending of protocol buffers over rabbitmq. This is
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

NOTE: I have to use a forked version of the `exprotobuf` to support the features I needed so you may have problems if you already have `exprotobuf` as a dependency. I will fix this when the proper one has the features I need which seems to at least be in progress.

### Sending Messages
Now your ready to start sending messages:

```elixir
{:ok, connection} = Smex.connect("amqp://guest:guest@localhost")

{:ok, channel} = Smex.open(connection)

message = PB.Greeting.new(greeting: "Hello, World!")
queue = "smex.test.some_test_queue"

:ok = Smex.publish(channel, message, destination: queue)
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
  def handle_cast({:smex_message, m = %PB.Greeting{}, meta}, state = %{channel: chan}) do
    IO.puts("Received a PB.Greeting:")
    IO.inspect(m)

    # Acknowledge receipt of message. This is necessary.
    Smex.ack(chan, meta)

    # Standard GenServer return
    {:stop, :normal, state}
  end
end
```

Since this is just a standard `GenServer` you can add to any supervision tree
you want or do any other stuff you can do with a `GenServer`.

## Motivation
RabbitMQ is awesome and asynchronous message passing is so hot right now. AMQP
is complicated with lots of features that it forces you to understand even for
simple use cases. Protocol buffers are fast and efficient data formats and
translate neatly into elixir structs. This library provides a really
straightforward way of getting started with these awesome libraries and intends
to still provide you with the option of utilising more advanced features of
AMQP when/if you eventually need it.
