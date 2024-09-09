#!/bin/bash
set -e

# Start Jupyter Lab in the background
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &

# Run the command passed to docker run
exec "$@"