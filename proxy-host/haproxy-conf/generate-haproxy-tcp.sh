#!/bin/bash
echo "defaults
   mode tcp
   timeout client 7200s
   timeout server 7200s
   timeout connect 60s
"

for PORT in {30000..39999}
do
    echo "listen px$PORT
    bind :$PORT
    server s1 10.10.1.1:$PORT
    "
done
