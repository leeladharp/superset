ARG NODE_VERSION=latest
ARG PYTHON_VERSION=3.6.8
ARG SUPERSET_DEPLOYED_ENV=dev

ARG ARG_SUPERSET_HOME=/opt/superset
# --- Build assets with NodeJS

FROM node:${NODE_VERSION} AS build

ENV SUPERSET_HOME=/opt/superset
RUN mkdir -p ${SUPERSET_HOME}
WORKDIR ${SUPERSET_HOME}
COPY . ${SUPERSET_HOME}

# Build assets and copy files
WORKDIR ${SUPERSET_HOME}/superset/assets
RUN npm install && \
    npm run build && \
    npm update


FROM python:${PYTHON_VERSION} AS dist
# Copy prebuilt workspace into stage
ENV SUPERSET_HOME=/opt/superset
WORKDIR ${SUPERSET_HOME}
COPY --from=build ${SUPERSET_HOME} .

# Create package to install
RUN python setup.py sdist && \
    tar czfv /tmp/superset.tar.gz requirements.txt keyvault-requirements.txt dist \
        Resources extra-libs



# --- Install dist package and finalize app
FROM python:${PYTHON_VERSION} AS final
ENV SUPERSET_HOME=/opt/superset

# Configure environment
ENV GUNICORN_BIND=0.0.0.0:2020 \
    GUNICORN_LIMIT_REQUEST_FIELD_SIZE=0 \
    GUNICORN_LIMIT_REQUEST_LINE=0 \
    GUNICORN_TIMEOUT=60 \
    GUNICORN_WORKERS=3 \
    GUNICORN_THREADS=4 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_REPO=/ \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=${SUPERSET_HOME} \
    SUPERSET_DEPLOYED_ENV=${SUPERSET_DEPLOYED_ENV} \
    FLASK_APP=superset


ENV HADOOP_HOME=/opt/hadoop \
    HIVE_HOME=/opt/hive \
    PATH=$PATH:$HIVE_HOME/bin
  
ENV GUNICORN_CMD_ARGS="--workers ${GUNICORN_WORKERS} --threads ${GUNICORN_THREADS} --timeout ${GUNICORN_TIMEOUT} --bind ${GUNICORN_BIND} --limit-request-line ${GUNICORN_LIMIT_REQUEST_LINE} --limit-request-field_size ${GUNICORN_LIMIT_REQUEST_FIELD_SIZE}"

# Create superset user & install dependencies
WORKDIR /tmp/superset
COPY --from=dist /tmp/superset.tar.gz .
RUN useradd -U -m superset && \
    mkdir -p /etc/superset && \
    mkdir -p ${SUPERSET_HOME} && \
    chown -R superset:superset /etc/superset && \
    chown -R superset:superset ${SUPERSET_HOME} && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        default-libmysqlclient-dev \
        freetds-bin \
        freetds-dev \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-2 \
        libsasl2-dev \
        libsasl2-modules-gssapi-mit \
        libssl1.0 \
        openjdk-8-jre && \
    apt-get clean && \
    tar xzf superset.tar.gz && \
    pip install dist/*.tar.gz -r requirements.txt -r keyvault-requirements.txt
#    rm -rf ./*
#Initialize superset database and install
RUN superset db upgrade && \
    flask fab create-admin --username admin --firstname dvt --lastname admin --email admin.org --password admin && \
    superset init && \
    chown -R superset:superset ${SUPERSET_HOME}

RUN bash Resources/setup_hive_beeline.sh && \
    bash Resources/hive_jdbc_superset_patch.sh /tmp/superset 

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre \
    CLASSPATH=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*:/opt/hadoop/share/hadoop/mapreduce/lib/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/contrib/capacity-scheduler/*.jar:/opt/hive/lib/* \
    HIVE_JDBC_DRIVER_PATH=/opt/hive/lib/ \
    HIVE_JDBC_JAR_NAME=hive-jdbc.jar


# Configure Filesystem
#COPY bin /usr/local/bin
WORKDIR /home/superset
#VOLUME /etc/superset \
#       /home/superset \
#       /var/lib/superset

# Finalize application
EXPOSE 2020
HEALTHCHECK CMD ["curl", "-f", "http://localhost:2020/health"]
CMD gunicorn superset:app
#USER superset
