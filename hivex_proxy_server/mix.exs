defmodule HivexProxyServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :hivex_proxy_server,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HivexProxyServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:thousand_island, "~> 1.5"}
    ]
  end
end
