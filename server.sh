#!/usr/bin/env bash

# 'echo -e "HTTP/1.1 200 OK\n\n $(date)"'

function process {
    echo -e "HTTP/1.1 200 OK\n\n $(date)"
}

socat -v tcp-l:12345,fork exec:'sed \'s|^.*?\r\n\r\n||\''