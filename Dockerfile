FROM maven:3.6.3-jdk-11 AS BUILD

ENV ANT_VERSION=1.10.9
ENV ANT_HOME=/opt/ant

# Temporary Workaround to Surefire issue 
ENV _JAVA_OPTIONS=-Djdk.net.URLClassPath.disableClassPathURLCheck=true

# change to tmp folder

WORKDIR /tmp

# Download and extract apache ant to opt folder
RUN wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz.sha512 \
    && echo "$(cat apache-ant-${ANT_VERSION}-bin.tar.gz.sha512) apache-ant-${ANT_VERSION}-bin.tar.gz" | sha512sum -c \
    && tar -zxf apache-ant-${ANT_VERSION}-bin.tar.gz -C /opt/ \
    && ln -s /opt/apache-ant-${ANT_VERSION} /opt/ant \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz.sha512

# add executables to path
RUN update-alternatives --install "/usr/bin/ant" "ant" "/opt/ant/bin/ant" 1 && \
    update-alternatives --set "ant" "/opt/ant/bin/ant" 

RUN     apt-get update && apt-get install -y \
               git \
	&& rm -rf /var/lib/apt/lists/*

# TODO : add specific COPY
COPY . .
#COPY datafari-ce datafari-ce
#COPY datafari-ee/datafari-zookeeper datafari-ee/datafari-zookeeper
#COPY datafari-ee/datafari-zookeeper-mcf datafari-ee/datafari-zookeeper-mcf
#COPY .drone.yml .drone.yml
#COPY datafari-ee/CHANGES.txt datafari-ee/CHANGES.txt
#COPY datafari-ee/LICENSE.txt datafari-ee/LICENSE.txt
#COPY datafari-ee/README.txt datafari-ee/README.txt
#COPY datafari-ee/pom.xml datafari-ee/pom.xml
#COPY .git .git
RUN mvn -f pom.xml -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn -B clean install
RUN ls
#COPY datafari-ee/apache apache
RUN ls
#COPY datafari-ee/bin/common bin/common
#COPY datafari-ee/linux linux
#COPY datafari-ee/opensearch opensearch
#COPY datafari-ee/ssl-keystore ssl-keystore
RUN ant docker-compose-modifications -f ./linux/build.xml
CMD ["/bin/bash", "-c", "sleep 300000"]
