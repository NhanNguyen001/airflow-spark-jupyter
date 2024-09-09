FROM apache/airflow:2.7.2-python3.11

USER root

# Set Airflow base URL
ENV AIRFLOW__WEBSERVER__BASE_URL=/airflow

# Install OpenJDK-11
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get clean;

# Set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME

# Install Spark
ENV SPARK_VERSION=3.4.1
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark

RUN mkdir -p ${SPARK_HOME} && \
    curl -sL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | tar -xz -C ${SPARK_HOME} --strip-components=1

# Set Spark environment variables
ENV PATH=$PATH:${SPARK_HOME}/bin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH

# Download JDBC driver
RUN curl -O https://jdbc.postgresql.org/download/postgresql-42.6.0.jar && \
    mv postgresql-42.6.0.jar ${SPARK_HOME}/jars/

USER airflow

# Install PySpark, JDBC, and Delta Lake dependencies
RUN pip install --no-cache-dir \
    pyspark[sql]==${SPARK_VERSION} \
    delta-spark==2.4.0 \
    psycopg2-binary

# Install Jupyter and related packages
RUN pip install --no-cache-dir \
    jupyter \
    jupyterlab \
    pandas \
    matplotlib \
    seaborn

# Configure Jupyter for base URL
RUN mkdir -p /home/airflow/.jupyter
RUN echo "c.NotebookApp.base_url = '/jupyter'" >> /home/airflow/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.allow_origin = '*'" >> /home/airflow/.jupyter/jupyter_notebook_config.py

# Install additional Airflow providers
RUN pip install --no-cache-dir \
    apache-airflow-providers-apache-spark \
    apache-airflow-providers-jdbc

# Set the working directory
WORKDIR /opt/airflow