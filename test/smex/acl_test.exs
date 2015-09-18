require IEx
defmodule Smex.ACL.Test do
  use ExUnit.Case

  test "ACLs are compiled properly" do
    ACL.Null.new
    ACL.Notification.Update.new
    ACL.Term.new
  end

  test "acl_type_hash returns the correct type hash" do
    assert Smex.ACL.acl_type_hash(ACL.Null) == "180sqw3"
  end

  test "I can map from a type hash to acl name" do
    assert Smex.ACL.acl_type_from_hash("180sqw3") == ACL.Null
    assert Smex.ACL.acl_type_from_hash("9qotwg") == ACL.Terms
    assert Smex.ACL.acl_type_from_hash("bpk3uz") == ACL.Notification.Updates
  end

  test "I can encode and decode" do
    term = ACL.Term.new(id: 123, term: "my term")
    update = ACL.Notification.Update.new(update: "my update", term: term)

    encoded = ACL.Notification.Update.encode(update)
    decoded = ACL.Notification.Update.decode(encoded)

    assert decoded == update
  end

  test "nested enum" do
    term = ACL.Term.new(id: 123, term: "my term", type: :SECOND)
    assert term == ACL.Term.decode(ACL.Term.encode(term))
  end
end
