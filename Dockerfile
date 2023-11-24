#Dockerfile Imagem Spark

FROM python:3.11-bullseye as spark-base

#Atualiza SO e instala os pacotes necessarios
#openjdk eh necessario para instalar o spark
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        curl \
        vim \
        nano \
        unzip \
        rsync \
        openjdk-11-jdk \
        build-essential \
        software-properties-common \
        ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#Variaveis de ambiente
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}

RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME}
#A partir daqui tudo vai ser feito dentro da pasta SPARK_HOME
WORKDIR ${SPARK_HOME}

#Download dos arquivos binarios do spark
#Extrai o arquivo .tgz e copia para a /opt/spark
RUN curl https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz -o spark-3.5.0-bin-hadoop3.tgz \
    && tar xvzf spark-3.5.0-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
    && rm -rf spark-3.5.0-bin-hadoop3.tgz

FROM spark-base as pyspark

#Copia o arquivo de requerimentos para dentro do container e faz a instalacao das dependencias
COPY requirements/requirements.txt .
RUN pip3 install -r requirements.txt

ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_HOME="/opt/spark"
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV SPAR_MASTER_PORT 7077
ENV PYPSARK_PYTHON python3

#copia o arquivo de configuracao do spark para dentro do container
COPY conf/spark-defaults.conf "${SPARK_HOME}/conf"

#da permissao de execucao para o dono do arquivo
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

ENV PYTHONPATH=${SPARK_HOME}/python/:${PYTHONPATH}

COPY entrypoint.sh .

#Da o privilegio de execucao no entrypoin
RUN chmod +x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]