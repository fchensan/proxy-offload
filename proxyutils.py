import subprocess
import json
import socket
from time import sleep
import psutil
from datetime import datetime
from os import fsync
from subprocess import check_output

DEFAULT_LISTENING_PORT = 22346

START_CLIENT = 0
START_SAR = 1
STOP_RETRIEVE_SAR = 2
RETRIEVE_IPERF = 3
RESET = 4
START_MONITOR = 5
STOP_RETRIEVE_MONITOR = 6

def is_json(string):
    try:
        json.loads(string)
    except ValueError as e:
        return False
    return True

def monitor(interface, interval, filepath):
    headers = "datetime,bytes_sent,bytes_recv,packets_sent,packets_recv,errin,errout,dropin,dropout,percent_memory,tcp_conns,"
    headers += "cpu_system,cpu_idle,cpu_irq,cpu_softirq"
    # for i in range(psutil.cpu_count()):
    #     headers += f"cpu_system_{i},cpu_idle_{i},cpu_irq_{i},cpu_softirq_{i}"

    headers += "\n"

    bytes_sent = bytes_recv = packets_sent = packets_recv = errin = errout = dropin = dropout = 0
    counters = psutil.net_io_counters(pernic=True)[interface]

    with open(filepath, "w") as file:
        file.write(headers)

    while True:
        with open(filepath, "a") as file:
            prev_bytes_sent = counters.bytes_sent
            prev_bytes_recv = counters.bytes_recv
            prev_packets_sent = counters.packets_sent
            prev_packets_recv = counters.packets_recv
            prev_errin = counters.errin
            prev_errout = counters.errout
            prev_dropin = counters.dropin
            prev_dropout = counters.dropout

            sleep(interval)

            counters = psutil.net_io_counters(pernic=True)[interface]
            delta_bytes_sent = counters.bytes_sent - prev_bytes_sent
            delta_bytes_recv = counters.bytes_recv - prev_bytes_recv
            delta_packets_sent = counters.packets_sent - prev_packets_sent
            delta_packets_recv = counters.packets_recv - prev_packets_recv
            delta_errin = counters.errin - prev_errin
            delta_errout = counters.errout - prev_errout
            delta_dropin = counters.dropin - prev_dropin
            delta_dropout = counters.dropout - prev_dropout

            entry = [datetime.now()]
            entry += [delta_bytes_sent,delta_bytes_recv,delta_packets_sent,delta_packets_recv,delta_errin,
            delta_errout,delta_dropin,delta_dropout]
            entry += [psutil.virtual_memory().percent]
            entry += [int(
                check_output(['ss', '-s'])
                    .split()[5]
                    .decode("utf-8")[:-1]
                )
            ]
            
            cpu_times = psutil.cpu_times_percent()
            entry += [cpu_times.system,cpu_times.idle,cpu_times.irq,cpu_times.softirq]
            # for cpu_time in cpu_times:
            #     entry += [cpu_time.system,cpu_time.idle,cpu_time.irq,cpu_time.softirq]

            entry_as_string = ",".join(str(data) for data in entry)

            file.write(entry_as_string+"\n")

class Node():
    def __init__(self, address, listening_port=DEFAULT_LISTENING_PORT):
        self.address = address
        self.listening_port = listening_port

    def send_command(self, command, options={}, receive=False):
        data = {
            "command": command,
            "options": options
        }

        json_data = json.dumps(data)

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        server_address = (self.address, self.listening_port)
        sock.connect(server_address)

        # Send the JSON data over the socket
        sock.sendall(json_data.encode())

        if receive:
            received_data = b""
            while not is_json(received_data.decode("utf-8")):
                received_data += sock.recv(1024)
            return json.loads(received_data.decode("utf-8"))

        # Close the socket
        sock.close()

    def start_iperf_client(self, server_address, server_port, duration, num_streams, target_bitrate):
        # Create a dictionary to send over the socket
        self.send_command(START_CLIENT, {
            "server_address": server_address,
            "port": server_port,
            "duration": duration,
            "num_streams": num_streams,
            "target_bitrate": (None if target_bitrate==0 else target_bitrate)
        })

    def kill_all_iperf(self):
        pass

    def start_haproxy(self, path_to_config_file):
        pass

    def start_monitor():
        pass

    def start_sar(self):
        self.send_command(START_SAR)

    def start_monitor_script(self, interface):
        self.send_command(START_MONITOR, {
            "interface": interface
        })
    
    def retrieve_iperf_log(self, port, filepath):
        received_data = self.send_command(RETRIEVE_IPERF, options={"port":port}, receive=True)
        with open(filepath+".log", "w") as file:
            file.write(received_data['log'])
        with open(filepath+".err", "w") as file:
            file.write(received_data['err'])

    def stop_and_retrieve_sar(self, filepath):
        received_data = self.send_command(STOP_RETRIEVE_SAR, receive=True)
        with open(filepath, "w") as file:
            file.write(received_data['content'])

    def stop_and_retrieve_monitor_script(self, filepath):
        received_data = self.send_command(STOP_RETRIEVE_MONITOR, receive=True)
        with open(filepath, "w") as file:
            file.write(received_data['content'])

    def reset(self):
        self.send_command(RESET)

class Agent():
    def __init__(self):
        pass

    def start_iperf_client(self, server_address, server_port, duration, num_streams, target_bitrate):
        if target_bitrate == None:
            command = f"nohup ~/iperf/src/iperf3 -c {server_address} -p {server_port} -t {duration} -P {num_streams} -i 60 --timestamp > /tmp/iperf-{server_port}.log 2> /tmp/iperf-{server_port}.err &"
        else:
            command = f"nohup ~/iperf/src/iperf3 -c {server_address} -p {server_port} -t {duration} -P {num_streams} -b {target_bitrate} -i 60 --timestamp > /tmp/iperf-{server_port}.log 2> /tmp/iperf-{server_port}.err &"
        subprocess.run(command, shell=True)

    def kill_all_iperf(self):
        subprocess.run("sudo pkill iperf".split())

    def start_haproxy(self, config_file):
        pass

    def start_sar(self):
        command = f"nohup sar 20 > /tmp/temp-sar.log 2> /dev/null &"
        subprocess.run(command, shell=True)

    def start_monitor_script(self, interface):
        command = f"nohup ~/proxy-offload/proxy-host/monitor.sh {interface} 20 > /tmp/temp-monitor.log 2> /dev/null &"
        subprocess.run(command, shell=True)

    def stop_and_retrieve_sar(self, connection):
        subprocess.run("sudo pkill sar".split())
        with open("/tmp/temp-sar.log", 'r') as file:
            file_contents = file.read()
            data = {"content": file_contents}
            json_data = json.dumps(data)
            connection.sendall(json_data.encode("utf-8"))

    def retrieve_iperf_log(self, connection, port):
        with open(f"/tmp/iperf-{port}.log", 'r') as file:
            log_contents = file.read()
        with open(f"/tmp/iperf-{port}.err", 'r') as file:
            err_contents = file.read()

        data = {"log": log_contents, "err": err_contents}
        json_data = json.dumps(data)
        connection.sendall(json_data.encode("utf-8"))
            
    def stop_and_retrieve_monitor(self, connection):
        with open("/tmp/temp-monitor.log", 'r') as file:
            file_contents = file.read()
            data = {"content": file_contents}
            json_data = json.dumps(data)
            connection.sendall(json_data.encode("utf-8"))

    def reset(self):
        command = f"sudo pkill iperf; sudo pkill sar;"
        subprocess.run(command, shell=True)

    def listen(self, address="0.0.0.0", port=DEFAULT_LISTENING_PORT):
        # Create a TCP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # Bind the socket to a local address and port
        server_address = (address, DEFAULT_LISTENING_PORT)
        sock.bind(server_address)

        # Listen for incoming connections
        sock.listen(1)

        print(f"Listening at {address}:{port}.")

        # Keep listening for commands, until Ctrl-C is pressed.
        try:
            while True:
                connection, client_address = sock.accept()

                # Receive the JSON data over the socket
                data = connection.recv(1024)

                # Deserialize the JSON data into a Python dictionary
                json_data = data.decode()
                received_data = json.loads(json_data)

                # Process the dictionary as desired
                print(f'Received data: {received_data}')

                if received_data['command'] == START_CLIENT:
                    options = received_data['options']
                    self.start_iperf_client(server_address=options['server_address'],
                                            server_port=options['port'],
                                            duration=options['duration'],
                                            num_streams=options['num_streams'],
                                            target_bitrate=options['target_bitrate'])
                elif received_data['command'] == START_SAR:
                    self.start_sar()
                elif received_data['command'] == STOP_RETRIEVE_SAR:
                    self.stop_and_retrieve_sar(connection)
                elif received_data['command'] == RETRIEVE_IPERF:
                    options = received_data['options']
                    self.retrieve_iperf_log(connection, options['port'])
                elif received_data['command'] == RESET:
                    self.reset()
                elif received_data['command'] == STOP_RETRIEVE_MONITOR:
                    self.stop_and_retrieve_monitor(connection)

                # Close the connection
                connection.close()
        except KeyboardInterrupt:
            pass

        # Close the socket
        sock.close()

# agent = Agent()
# agent.listen()
