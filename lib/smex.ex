defmodule Smex do
  use Application

  def start(_type, _args) do
    Smex.Supervisor.start_link
  end
end
