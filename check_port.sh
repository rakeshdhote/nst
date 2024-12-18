#!/bin/bash

# Default list of ports to check and terminate if found
DEFAULT_PORTS=(8000 8001 8002 8111 3000)

# Get the list of ports from command line arguments or use default if not provided
if [ $# -gt 0 ]; then
    PORTS=("$@")
else
    PORTS=("${DEFAULT_PORTS[@]}")
fi

for PORT in "${PORTS[@]}"; do
    # Find the process using the specified port
    PID=$(lsof -t -i :"${PORT}")

    if [ -n "${PID}" ]; then
        echo "Port ${PORT} is in use by process ${PID}. Terminating the process..."
        kill -9 "${PID}"
        echo "Process ${PID} terminated."
    else
        echo "Port ${PORT} is not in use."
    fi
done
