defmodule HivexProxyClientTest do
  use ExUnit.Case
  doctest HivexProxyClient

  test "greets the world" do
    assert HivexProxyClient.hello() == :world
  end
end
