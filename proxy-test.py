from proxyutils import Node, DEFAULT_LISTENING_PORT
from time import sleep

node = Node("10.10.1.4", DEFAULT_LISTENING_PORT)
node.start_sar()
sleep(5)
node.stop_and_retrieve_sar("/users/fchensan/sar.log")
