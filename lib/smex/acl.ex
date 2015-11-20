defmodule Smex.ACL do

  use Protobuf, from: Path.expand(Path.expand(Application.get_env(:smex, :protobuf_dir) <> "/*.proto", __DIR__))

  def start_link do
    pid = Agent.start_link(fn -> HashDict.new end, name: :acl_cache)
    inverse_map_all_acls_to_hash
    pid
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

  @doc """
  Converts a hash string used by smex messaging to the corresponding ACL type.

  ## Examples
  iex> Smex.ACL.acl_type_from_hash("180sqw3")
  ACL.Null
  """
  def acl_type_from_hash(hash) do
    case Agent.get(:acl_cache, fn (dict) -> dict |> Dict.fetch(hash) end) do
      {:ok, result} -> result
      :error -> nil
    end
  end

  defp inverse_map_all_acls_to_hash do
    names = defs |> Enum.map(&(elem(elem(&1, 0), 1)))
    names = names |> Enum.map(&({acl_type_hash(&1), &1}))

    Agent.update(:acl_cache, fn(dict) -> (names |> Enum.into(dict)) end)
  end
end
