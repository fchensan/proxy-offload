import subprocess
import json
import socket
from time import sleep

DEFAULT_LISTENING_PORT = 22346

START_CLIENT = 0
START_SAR = 1
STOP_RETRIEVE_SAR = 2

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

        print("sending")

        # Send the JSON data over the socket
        sock.sendall(json_data.encode())

        print("receiving")

        if receive:
            received_data = b""
            while not is_json(received_data.decode("utf-8")):
                received_data += sock.recv(1024)
            return json.loads(received_data.decode("utf-8"))

        # Close the socket
        sock.close()
    
    def start_iperf_server(self):
        pass

    def start_iperf_client(self):
        # Create a dictionary to send over the socket
        self.send_command(START_CLIENT, {
            "server": "10.10.1.3"
        })

    def kill_all_iperf(self):
        pass

    def start_haproxy(self, path_to_config_file):
        pass

    def start_sar(self):
        self.send_command(START_SAR)

    def start_monitor_script(self):
        pass

    def stop_and_retrieve_sar(self, filepath):
        received_data = self.send_command(STOP_RETRIEVE_SAR, receive=True)
        with open(filepath, "w") as file:
            file.write(received_data['content'])

    def stop_and_retrieve_monitor_script(self):
        pass

class Agent():
    def __init__(self):
        pass
    
    def start_iperf_server(self):
        pass

    def start_iperf_client(self, server_address, server_port, duration, num_streams, target_bitrate):
        command = f"nohup iperf3 -c {server_address} -p {server_port} -t {duration} -P {num_streams} -b {target_bitrate} > /dev/null 2> /dev/null &"
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
        with open("/tmp/temp-sar.log", 'rb') as file:
            file_contents = file.read()
            data = {"content": str(file_contents)}
            json_data = json.dumps(data)
            connection.sendall(json_data.encode("utf-8"))
            
    def stop_and_retrieve_monitor_script(self):
        pass

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

                # Close the connection
                connection.close()
        except KeyboardInterrupt:
            pass

        # Close the socket
        sock.close()

# agent = Agent()
# agent.listen()
