FROM anapsix/alpine-java:8_server-jre

ENV DRUID_VERSION=0.10.0 \
    ZOOKEEPER_VERSION=3.4.10 \
    PATH=/usr/local/bin:${PATH}

    # Prepare the container to install the software
RUN set -ex && \
    apk upgrade --update && \
    apk add --update curl mariadb mariadb-client supervisor && \
    rm -rf /var/cache/apk/* && \
    # Zookeeper
    curl http://mirrors.myaegean.gr/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz | tar -xzf - -C /usr/local && \
    cp /usr/local/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo_sample.cfg /usr/local/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo.cfg && \
    ln -s /usr/local/zookeeper-${ZOOKEEPER_VERSION} /usr/local/zookeeper && \
    # Druid
    addgroup -S druid && \
    adduser -S -G druid -h /var/lib/druid druid && \
    curl http://static.druid.io/artifacts/releases/druid-${DRUID_VERSION}-bin.tar.gz | tar -xzf - -C /usr/local && \
    ln -s /usr/local/druid-${DRUID_VERSION} /usr/local/druid && \
    curl http://static.druid.io/artifacts/releases/mysql-metadata-storage-${DRUID_VERSION}.tar.gz | tar -xzf - -C /usr/local/druid/extensions && \
    # Druid task logs
    mkdir /var/log/druid && \
    chown druid:druid /var/log/druid && \
    # Remove not needed tools
    apk del curl && \
    # Mysql
    mysql_install_db --user=mysql --rpm && \
    (mysqld_safe &) && \
    sleep 2 && \
    # Druid mysql settings
    mysql -u root -e "GRANT ALL ON druid.* TO 'druid'@'localhost' IDENTIFIED BY 'diurd'; CREATE database druid CHARACTER SET utf8;" && \
    java -cp "/usr/local/druid/lib/*" \
         -Ddruid.extensions.directory=/usr/local/druid/extensions \
         '-Ddruid.extensions.loadList=["mysql-metadata-storage"]' \
         -Ddruid.metadata.storage.type=mysql \
          io.druid.cli.Main tools metadata-init \
	 --connectURI="jdbc:mysql://localhost:3306/druid" \
         --user=druid --password=diurd && \
    killall -TERM mysqld && \
    sleep 2

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 3306: MySQL
# - 2181 2888 3888: ZooKeeper
EXPOSE 8081 8082 8083 3306 2181 2888 3888
ENTRYPOINT export HOSTIP="$(resolveip -s $HOSTNAME)" && exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf