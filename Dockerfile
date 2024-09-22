FROM apache/airflow:slim-latest-python3.11

USER root

# Set Airflow base URL
ENV AIRFLOW__WEBSERVER__BASE_URL=/airflow

# Install OpenJDK-8
RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get install -y gcc && \
    apt-get install -y software-properties-common && \
    apt-add-repository 'deb http://ftp.de.debian.org/debian sid main' && \
    apt update --allow-unauthenticated && \
    apt-get install -y openjdk-8-jdk && \
    apt-get clean

# Install Spark
ENV SPARK_VERSION=3.4.1
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark

# RUN mkdir -p ${SPARK_HOME} && \
#     curl -sL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | tar -xz -C ${SPARK_HOME} --strip-components=1

# Copy Spark source file from current directory
COPY ./source/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz /tmp/
#Create Spark directory and extract the archive
RUN mkdir -p ${SPARK_HOME} && \
    tar -xzf /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C ${SPARK_HOME} --strip-components=1 && \
    rm /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Download JDBC driver
RUN curl -O https://jdbc.postgresql.org/download/postgresql-42.6.0.jar && \
    mv postgresql-42.6.0.jar ${SPARK_HOME}/jars/

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER airflow

# Install JPype1 separately with specific version
# RUN pip install --no-cache-dir JPype1==1.4.1

# Install PySpark, JDBC, and Delta Lake dependencies
RUN pip install --no-cache-dir \
    pyspark[sql]==${SPARK_VERSION} \
    delta-spark==2.4.0 \
    psycopg2-binary \
    notebook \
    jupyter \
    jupyterlab \
    pandas \
    apache-airflow \
    apache-airflow-providers-apache-spark \
    apache-airflow-providers-jdbc

# Set Spark environment variables
# ENV PATH=$PATH:${SPARK_HOME}/bin   
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-arm64
RUN export JAVA_HOME
ENV PATH $PATH:$JAVA_HOME/bin
ENV PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH
ENV SPARK_MASTER=spark://spark-master:7077

# Generate default Airflow config
# RUN airflow config list > /opt/airflow/airflow.cfg

# Copy DAGs to the DAGs folder
COPY dags/ /opt/airflow/dags/
COPY jobs/ /opt/airflow/jobs/
COPY airflow.cfg /opt/airflow/airflow.cfg

# Set the working directory
WORKDIR /opt/airflow

# Configure Jupyter for base URL
RUN mkdir -p /home/airflow/.jupyter

RUN echo "c.NotebookApp.base_url = '/jupyter'" >> /home/airflow/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.allow_origin = '*'" >> /home/airflow/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.disable_check_xsrf = True" >> /home/airflow/.jupyter/jupyter_notebook_config.py
RUN python -c "from jupyter_server.auth import passwd; print(passwd('1_Abc_123', 'sha1'))" > /tmp/sha1.txt
RUN echo "c.NotebookApp.password = u'$(cat /tmp/sha1.txt)'" >> /home/airflow/.jupyter/jupyter_notebook_config.py
RUN rm /tmp/sha1.txt

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]