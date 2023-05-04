import subprocess
import json
import socket
from time import sleep

DEFAULT_LISTENING_PORT = 22346

START_CLIENT = 0
START_SAR = 1
STOP_RETRIEVE_SAR = 2
RETRIEVE_IPERF = 3
RESET = 4

def is_json(string):
    try:
        json.loads(string)
    except ValueError as e:
        return False
    return True

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
    
    def start_iperf_server(self):
        pass

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

    def start_sar(self):
        self.send_command(START_SAR)

    def start_monitor_script(self):
        pass
    
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

    def stop_and_retrieve_monitor_script(self):
        pass

    def reset(self):
        self.send_command(RESET)

class Agent():
    def __init__(self):
        pass
    
    def start_iperf_server(self):
        pass

    def start_iperf_client(self, server_address, server_port, duration, num_streams, target_bitrate):
        if target_bitrate == None:
            command = f"nohup iperf3 -c {server_address} -p {server_port} -t {duration} -P {num_streams} -i 20 --timestamp > /tmp/iperf-{server_port}.log 2> /tmp/iperf-{server_port}.err &"
        else:
            command = f"nohup iperf3 -c {server_address} -p {server_port} -t {duration} -P {num_streams} -b {target_bitrate} -i 20 --timestamp > /tmp/iperf-{server_port}.log 2> /tmp/iperf-{server_port}.err &"
        subprocess.run(command, shell=True)

    def kill_all_iperf(self):
        subprocess.run("sudo pkill iperf".split())

    def start_haproxy(self, config_file):
        pass

    def start_sar(self):
        command = f"nohup sar 20 > /tmp/temp-sar.log 2> /dev/null &"
        subprocess.run(command, shell=True)

    def start_monitor_script(self):
        pass

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
            
    def stop_and_retrieve_monitor_script(self):
        pass

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
                    self.retrieve_iperf_log(connection, options['port'])
                elif received_data['command'] == RESET:
                    self.reset()

                # Close the connection
                connection.close()
        except KeyboardInterrupt:
            pass

        # Close the socket
        sock.close()

# agent = Agent()
# agent.listen()
