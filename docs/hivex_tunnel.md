# Hivex tunnel

The Hivex tunnel is a reverse proxy for Hivex workers to make their containers accessible from the Internet.
The tunnel is used as an alternative to setting up the worker to be publicly available.

## Architecture

TODO: image

The tunnel is created between two components: **server** and the **client** (come up with the better names).
On top of the connection between the server and the client, the server listens on the incoming traffic from
Internet. All the traffic dedicated for the client (decided by the listening port on the server) is forwarded
to the client through the tunnel.

The server is accessible from Internet -- it is meant to be deployed as part of the Hivex application.
The client is does not need to be accessible from Internet, but it needs network access to the server (can
be through Internet).

## Specification

The Hivex tunnel is heavily inspired by the SOCKS5 BIND connection.

The client initiates the connection to the server asking to create a listener on the server. Server starts
the listener (picking the best port) and acknowledges the creation (with the picked port).

From this point any traffic that arrives to the listener on the server gets forwarded through the tunnel to
the client. The client takes care of forwarding the traffic to the correct container/server.

TODO: figure out how to do the tunnel multiplexing -- a.k.a. how can client forward traffic to multiple
targetted containers (without relying on the HTTP headers -- to make it the L4 protocol).

## Elixir implementation

Both server and client are separate elixir applications. That means that they can be started as standalone
binaries. But still both mean to be started as part of Hivex system (either Hivex or the worker).

The decision to have it as application is supported by the fact that I don't plan for either of components
to require implementation by the "parent" application. The client or server can be used to provide a
corresponding functionality, but at no point should it require any implementation from other applications.
Thus, it is standalone app with its own "scope" of processes and its own config. Let's see how that goes.
