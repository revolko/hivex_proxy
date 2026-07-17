defmodule HivexProxyServerTest do
  use ExUnit.Case
  doctest HivexProxyServer

  test "greets the world" do
    assert HivexProxyServer.hello() == :world
  end
end
