defmodule Smex.ACL do
  use Protobuf, from: Path.expand(System.get_env("SMITH_ACL_PATH") || "../acls/*.proto")

  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: :acl_cache)
  end

  @doc """
  Converts an ACL type to the corresponding hash string used by smex messaging.

  ## Examples

    iex> Smex.ACL.acl_type_hash(ACL.Null)
    "180sqw3"
  """
  def acl_type_hash(type) do
    type = type
            |> Atom.to_string
            |> String.replace(~r/^Elixir./, "")
            |> String.replace(".", "::")
    Murmur.hash(:x86_32, type)
    |> Integer.to_string(36)
    |> String.downcase
  end
end
