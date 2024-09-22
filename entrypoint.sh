#!/bin/bash

# Initialize the database
airflow db migrate

# Create an admin user if it doesn't exist
airflow users create --username admin --password admin --firstname admin --lastname admin --role Admin --email admin@examples.com || true

# Run the scheduler in the background
airflow scheduler &

# Run the web server in the background
airflow webserver &

# Run Jupyter Notebook in the foreground
# exec jupyter notebook --ip='*' --NotebookApp.token='' --NotebookApp.password='' --allow-root
# Run Jupyter Notebook in the foreground
jupyter notebook --ip='*' --allow-root