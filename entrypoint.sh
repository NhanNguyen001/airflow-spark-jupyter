# # Start Jupyter Lab in the background
# jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &

# # Run the command passed to docker run
# exec "$@"

#!/bin/bash
set -e

# Initialize Airflow database if it hasn't been initialized
airflow db init

# Create admin user if it doesn't exist
airflow users list | grep -q admin || \
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin

# Start Jupyter Lab in the background if the command is jupyter
if [ "$1" = "jupyter" ]; then
  jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &
fi

# Run the command passed to docker run
exec "$@"