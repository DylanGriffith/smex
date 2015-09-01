require IEx
defmodule Smex.ACL.Test do
  use ExUnit.Case

  test "ACLs are compiled properly" do
    ACL.Dashboard.User.new
    Smith.ACL.Tweets.new
  end

  test "acl_type_hash returns the correct type hash" do
    assert Smex.ACL.acl_type_hash(ACL.Null) == "180sqw3"
  end
end
