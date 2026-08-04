defmodule HivexProxyServer do
  @moduledoc """
  Hivex proxy `server` is the public component of the `Hivex proxy`.

  ## Hivex proxy
  Hivex proxy is a custom solution of the `reverse proxy tunnel`. It enables `Hivex workers`,
  deployed in private networks, to be accessible from the Internet.

  Hivex proxy works by creating the TCP tunnel between `proxy server` and the `proxy client`:
    * `proxy server` is listening on the requests/connections from clients (over Internet)
    * `proxy client` is forwarding all traffic to a dedicated service/server (private)

  So the expected traffic is:
  client -- request --> proxy server --> <-tunnel-> --> proxy client --> service
  service --> response --> proxy client --> <-tunnel-> --> proxy server --> client

  The proxy client can be deployed in the private network -- behind NAT and/or firewall. The only
  requirement is that it has access to the Internet -- thus, it has access to the proxy server.
  The proxy client initiates the connection to the proxy server and upon successful connection a
  tunnel --the persistent connection-- is created. That way, the proxy server can communicate with
  the proxy client, bypassing any NAT and firewall restrictions.

  Hivex proxy is meant to be used as part of the `Hivex` platform. The proxy server is managed by
  `Hivex` and the proxy client by `Hivex worker`. However the proxy is built as standalone software
  so that it can be potentially reused in other Elixir applications.

  ## Hivex proxy server
  The proxy server takes care of forwarding traffic from the Internet to a correct proxy client.

  First, the proxy client initiates the creation of the tunnel. If the proxy client is authorized
  (currently it always is) the tunnel is created. Secondly, the proxy client sends a `bind request`
  to the proxy server. The request instructs the proxy server to create a `listener`. Details about
  listener configuration are sent in the request -- mainly on which port should the listener
  listen.

  ### Listener
  In order for the proxy server to accept traffic on a port, it must start a listener on the given
  port. The proxy server utilizes `ThousandIsland` supervisor to create listeners. In essence, a
  listener is an instance of the `ThousandIsland` supervisor that is configured to listen on any
  traffic on the given port.

  The port is given by the client using the `bind request` control message.

  ### Control messages
  `Control messages` are the mechanism used by proxy clients and servers to exchange data during the
  tunnel establishment process.

  #### Message parts
  Each control message is a simple binary sequence. Each message can contain the following parts:
    * VER -- 1 byte
      * version of the protocol
    * CMD -- 1 byte
      * command
      * possible values:
        * 0x01 -- BIND
    * PORT -- 2 bytes
      * binary encoded unsigned integer
      * port number
      * for example:
        * 0x0683 --> 1667

  #### Bind request
  Control message from the proxy client requesting the proxy server to create a listener.

  ```
  0x01 (VER), 0x01 (CMD), 0x0683 (PORT)
  ```

  #### Bind response
  Control message from the proxy server as acknowledgment of the created listener.

  ```
  0x01 (VER), 0x01 (CMD), 0x0683 (PORT)
  ```
  """
end
