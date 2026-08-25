defmodule HivexProxyClient.Server do
  @moduledoc """
  Server reference struct.

  Server can be web application, game server, or any other TCP/UPD server.
  """

  @type t :: %__MODULE__{
          ip: String.t(),
          port: integer(),
          proxy_listener_port: integer()
        }

  @enforce_keys [:ip, :port]
  defstruct [:ip, :port, proxy_listener_port: 0]
end
