#!/bin/bash
echo "stream {"
    for PORT in {30000..30999}
    do
        echo "  upstream backend$PORT {
        server 10.10.1.1:$(($PORT+10000));
    }
    server {
        listen $PORT backlog=32768;
        proxy_pass backend$PORT;
        proxy_timeout 60m;
    }"
    done
echo "}"