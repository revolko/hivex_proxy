server = %HivexProxyClient.Server{ip: :localhost, port: 4050, proxy_listener_port: 8080}
HivexProxyClient.ConnectionsSupervisor.register_server(server)
