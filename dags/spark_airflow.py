import airflow
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.models import Connection
from airflow import settings
import subprocess
import os

# # Create Spark connection
# spark_conn = Connection(
#     conn_id="spark-conn",
#     conn_type="spark",
#     host="spark://spark-master",
#     port=7077
# )

# # Add the connection to the session
# session = settings.Session()
# session.add(spark_conn)
# session.commit()

dag = DAG(
    dag_id="sparking_flow",
    default_args={
        "owner": "nhannt22@hdbank.com.vn",
        "start_date": airflow.utils.dates.days_ago(1)
    },
    schedule_interval="@daily"
)

def run_spark_job():
    script_path = os.path.join(os.environ.get('AIRFLOW_HOME', ''), 'jobs', 'python', 'wordcountjob.py')
    result = subprocess.run(['python', script_path], capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        raise Exception(f"Spark job failed: {result.stderr}")

# start = PythonOperator(
#     task_id="start",
#     python_callable=lambda: print("Jobs started"),
#     dag=dag
# )

python_job = PythonOperator(
    task_id="python_job",
    python_callable=run_spark_job,
    dag=dag
)

# end = PythonOperator(
#     task_id="end",
#     python_callable=lambda: print("Jobs completed successfully"),
#     dag=dag
# )

python_job