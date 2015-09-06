defmodule Smex do
  use Application

  def start(_type, _args) do
    Smex.Supervisor.start_link
  end

  def publish(destination, payload, opts \\ []) do
    opts = opts |> Keyword.put(:destination, destination)|> Enum.into %{}
    publisher = Map.merge(%Smex.Messaging.Publisher{}, opts)
    Smex.Messaging.Publisher.publish(publisher, payload)
  end

  def subscribe(exchange_name, opts, fun) do
  end

  def conn_string do
    System.get_env("RABBITMQ_URL") || "amqp://guest:guest@localhost"
  end
end
