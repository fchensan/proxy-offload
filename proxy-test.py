from proxyutils import Node, DEFAULT_LISTENING_PORT
from time import sleep
from math import ceil
from os import makedirs

def run_experiment(title, total_conns, spawn_delay, streams_per_process, hold_duration, client_addresses, server_addresses, proxy_address, target_bitrate=0):
    makedirs(f"/users/fchensan/{title}/logs", exist_ok=True)
    client_nodes = [Node(address, DEFAULT_LISTENING_PORT) for address in client_addresses]
    server_nodes = [Node(address, DEFAULT_LISTENING_PORT) for address in server_addresses]
    
    if proxy_address != None:
        proxy_node = Node(proxy_address, DEFAULT_LISTENING_PORT)

    num_clients = len(client_nodes)
    num_servers = len(server_nodes)

    duration = spawn_delay*ceil(total_conns/streams_per_process) + hold_duration
    duration_left = duration

    starting_port = 30000
    end_port = starting_port + ceil(total_conns/streams_per_process)

    if proxy_address == None:
        client_idx = 0
        server_idx = 0

        for port in range(starting_port, end_port):
            client_nodes[client_idx].start_iperf_client(server_addresses[server_idx], port, duration_left, streams_per_process,
                target_bitrate)
            client_idx = (client_idx + 1) % num_clients
            server_idx = (server_idx + 1) % num_servers

            sleep(spawn_delay)
            duration_left -= spawn_delay

    else:
        client_idx = 0

        for port in range(starting_port, end_port):
            client_nodes[client_idx].start_iperf_client(proxy_address, port, duration_left, streams_per_process, target_bitrate)
            client_idx = (client_idx + 1) % num_clients

            sleep(spawn_delay)
            duration_left -= spawn_delay

    sleep(duration_left + 10)

    for i, client in enumerate(client_nodes):
        client.stop_and_retrieve_monitor_script(f"/users/fchensan/{title}/client-sar-{i}.log")

    for i, server in enumerate(server_nodes):
        server.stop_and_retrieve_monitor_script(f"/users/fchensan/{title}/server-monitor-{i}.log")

    if proxy_address != None:
        proxy_node.stop_and_retrieve_monitor_script(f"/users/fchensan/{title}/proxy-monitor.log")

    client_idx = 0

    for port in range(starting_port, end_port):
        client_nodes[client_idx].retrieve_iperf_log(port, f"/users/fchensan/{title}/logs/iperf-{port}.log")
        client_idx = (client_idx + 1) % num_clients

client_addresses = ["10.10.1.5", "10.10.1.7"]
server_addresses = ["10.10.1.7"]

run_experiment("new-test-1",
                total_conns=10,
                spawn_delay=1,
                streams_per_process=1,
                hold_duration=130,
                client_addresses=client_addresses,
                server_addresses=server_addresses,
                proxy_address="10.10.1.1")

