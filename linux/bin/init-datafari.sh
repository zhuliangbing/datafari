#!/bin/bash

# Init Datafari
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/set-datafari-env.sh"
source "${DIR}/utils.sh"
source $INIT_STATE_FILE
source $CONFIG_FILE
source "${DATAFARI_HOME}/tomcat/conf/version.properties"
installerLog="${DATAFARI_HOME}/logs/installer.log"


@VERSION-METHODS@


question_ip_node() {
    read -p  "Specify the IP of the current host [127.0.0.1]: " node_host
    node_host=${node_host:-127.0.0.1}
    set_property "NODEHOST" $node_host $CONFIG_FILE
}

question_solr_collection() {
    read -p "What is the name of the main Solr Collection [FileShare]: " solr_main_collection
    solr_main_collection=${solr_main_collection:-FileShare}
    set_property "SOLRMAINCOLLECTION" $solr_main_collection $CONFIG_FILE
}

question_solr_shards_number() {
    read -p "Enter the number of shards you want for your index [2]: " solr_shards_number
    solr_shards_number=${solr_shards_number:-2}
    set_property "SOLRNUMSHARDS" $solr_shards_number $CONFIG_FILE
}

question_datafari_password() {
    read -p "Enter the Datafari password [admin]: " datafari_password
    datafari_password=${datafari_password:-admin}
    set_property "TEMPADMINPASSWORD" $datafari_password $CONFIG_FILE
  set_property "MCFPASSWORD" $datafari_password $CONFIG_FILE
}

question_postgresql_password() {
    read -p "Enter the Postgresql password [admin]: " postgresql_password
    postgresql_password=${postgresql_password:-admin}
    set_property "TEMPPGSQLPASSWORD" $postgresql_password $CONFIG_FILE
}

question_elk_start() {
  read -p "Do you want to start ELK (yes/no) [yes] ? " elk_start
  elk_start=${elk_start:-yes}
  if [[ "$elk_start" = "yes" ]] || [[ "$elk_start" = "y" ]] || [[ "$elk_start" = "true" ]]; then
    elk_start=true
  else
    elk_start=false
  fi
  set_property "ELKactivation"  $elk_start $CONFIG_FILE
}

question_start_datafari() {
  read -p "Do you want Datafari to be started (yes/no)? [yes] ? " start_datafari
  start_datafari=${start_datafari:-true}
  if [[ "$start_datafari" = "yes" ]] || [[ "$start_datafari" = "y" ]] || [[ "$start_datafari" = "true" ]]; then
    start_datafari=true
  else
    start_datafari=false
  fi
}
    
## Installer functions

getProperty() {
    awk -F'=' -v k="$1" '$1==k&&sub(/^[^=]*=/,"")' $2
}

delete_certificates() {
  # Delete dev SSL certificates

  chmod -R 775 $DATAFARI_HOME/ssl-keystore
  rm -f $DATAFARI_HOME/ssl-keystore/datafari-keystore.p12
  rm -f $DATAFARI_HOME/ssl-keystore/datafari-key.pem
  rm -f $DATAFARI_HOME/ssl-keystore/datafari-cert.pem
  rm -f $DATAFARI_HOME/ssl-keystore/datafari-cert.csr

  # Delete Apache certificates
  rm -f $DATAFARI_HOME/ssl-keystore/apache/datafari.csr
  rm -f $DATAFARI_HOME/ssl-keystore/apache/datafari.crt
  rm -f $DATAFARI_HOME/ssl-keystore/apache/datafari.key
}

init_war() {
  
  mkdir -p $TOMCAT_HOME/webapps/Datafari
  mv $TOMCAT_HOME/webapps/Datafari.war $TOMCAT_HOME/webapps/Datafari
  unzip -qq $TOMCAT_HOME/webapps/Datafari/Datafari.war -d $TOMCAT_HOME/webapps/Datafari
  
  @WAR_VERSION_INIT@
}

init_war_mcf() {
  mv $TOMCAT_HOME/webapps/Datafari $TOMCAT_HOME/webapps/adminmcfdistant$1
}

init_git() {

  # Get Git commit id and version 

  file="$TOMCAT_HOME/conf/git.properties"

  if [ -f "$file" ]; then
    while IFS='=' read -r key value; do
      if [[ $key == git.commit.id.abbrev ]]; then

        commit=$value
        echo $commit
      fi

      if [[ $key == git.build.version ]]; then

        version=$value
        echo $version
      fi
    done <"$file"
  fi
  sed -i -e "s/@VERSION@/$version/g" $TOMCAT_HOME/webapps/Datafari/footer.jsp >>$installerLog 2>&1
  sed -i -e "s/@VERSION@/$version/g" $TOMCAT_HOME/webapps/Datafari/admin/admin-footer.jsp >>$installerLog 2>&1
  sed -i -e "s/@COMMIT@/$commit/g" $TOMCAT_HOME/webapps/Datafari/admin/admin-footer.jsp >>$installerLog 2>&1

}

init_elk() {
  #change elk address
  sed -i -e "s/localhost/${1}/g" $TOMCAT_HOME/conf/elk.properties >>$installerLog 2>&1
  sed -i "/server.host:/c\server.host: 0.0.0.0" $DATAFARI_HOME/elk/kibana/config/kibana.yml >>$installerLog 2>&1
  
  # Init MetricBeat
  if [ "$2" = "mono" ]; then
    sed -i -e "s~@METRICBEAT-CONFIGURATION@~mono~g" $DATAFARI_HOME/elk/scripts/elk-manager.sh >>$installerLog 2>&1
  else
    sed -i -e "s~@METRICBEAT-CONFIGURATION@~multi~g" $DATAFARI_HOME/elk/scripts/elk-manager.sh >ƒ>$installerLog 2>&1
  fi

}

init_logstash() {
  sed -i -e "s/@ES_HOST@/$1:9200/g" $DATAFARI_HOME/elk/logstash/logstash-datafari.conf >>$installerLog 2>&1
}

init_elk_apache() {
  if [ -d /etc/apache2 ]; then
    cp $DATAFARI_HOME/elk/proxy/elk.conf /etc/apache2/sites-available/
    ln -s /etc/apache2/sites-available/elk.conf /etc/apache2/sites-enabled/elk.conf
  fi
}

init_memory() {
  
  sed -i -e "s/@SOLRMEMORY@/${SOLRMEMORY}/g" $DATAFARI_HOME/solr/bin/solr.in.sh >>$installerLog 2>&1
  sed -i -e "s/@MCFAGENTMEMORY@/${MCFAGENTMEMORY}/g" $DATAFARI_HOME/mcf/mcf_home/options.env.unix >>$installerLog 2>&1
  sed -i -e "s/@TOMCATMEMORY@/${TOMCATMEMORY}/g" $DATAFARI_HOME/tomcat/bin/setenv.sh >>$installerLog 2>&1
  sed -i -e "s/@TOMCATMCFMEMORY@/${TOMCATMCFMEMORY}/g" $DATAFARI_HOME/tomcat-mcf/bin/setenv.sh >>$installerLog 2>&1
  sed -i -e "s/@CASSANDRAMEMORY@/${CASSANDRAMEMORY}/g" $DATAFARI_HOME/cassandra/conf/jvm-server.options >>$installerLog 2>&1
  sed -i -e "s/@POSTGRESQLMEMORY@/${POSTGRESQLMEMORY}/g" $DATAFARI_HOME/pgsql/postgresql.conf.save >>$installerLog 2>&1
  sed -i -e "s/@ELASTICSEARCHMEMORY@/${ELASTICSEARCHMEMORY}/g" $DATAFARI_HOME/elk/elasticsearch/config/jvm.options >>$installerLog 2>&1
  sed -i -e "s/@LOGSTASHMEMORY@/${LOGSTASHMEMORY}/g" $DATAFARI_HOME/elk/logstash/config/jvm.options >>$installerLog 2>&1
  sed -i -e "s/@KIBANAMEMORY@/${KIBANAMEMORY}/g" $DATAFARI_HOME/elk/scripts/set-elk-env.sh >>$installerLog 2>&1
  sed -i -e "s/@TIKASERVERMEMORY@/${TIKASERVERMEMORY}/g" $DATAFARI_HOME/tika-server/bin/set-tika-env.sh >>$installerLog 2>&1
  sed -i -e "s/@TIKACHILDMEMORY@/${TIKACHILDMEMORY}/g" $DATAFARI_HOME/tika-server/conf/tika-config.xml >>$installerLog 2>&1
  
  
}

init_temp_directory() {
  
  sed -i -e "s~@TOMCATTMPDIR@~${TOMCATTMPDIR}~g" $DATAFARI_HOME/tomcat/bin/setenv.sh >>$installerLog 2>&1
  sed -i -e "s~@TOMCATMCFTMPDIR@~${TOMCATMCFTMPDIR}~g" $DATAFARI_HOME/tomcat_mcf/bin/setenv.sh >>$installerLog 2>&1
  sed -i -e "s~@MCFTMPDIR@~${MCFTMPDIR}~g" $DATAFARI_HOME/mcf/mcf_home/options.env.unix >>$installerLog 2>&1
  sed -i -e "s~@SOLRTMPDIR@~${SOLRTMPDIR}~g" $DATAFARI_HOME/solr/bin/solr.in.sh >>$installerLog 2>&1
  sed -i -e "s~@TIKATMPDIR@~${TIKATMPDIR}~g" $DATAFARI_HOME/tika-server/conf/tika-config.xml >>$installerLog 2>&1  
}



generate_certificates() {
  # Generate SSL certificate for datafari
  $JAVA_HOME/bin/keytool -genkey -alias tomcat -keyalg RSA -keystore $DATAFARI_HOME/ssl-keystore/datafari-keystore.p12 -validity 9999 -storepass DataFariAdmin -keypass DataFariAdmin -dname "cn=${1}, ou=francelabs, o=francelabs, l=nice, st=paca, c=pa" -ext "SAN:c=DNS:localhost,IP:127.0.0.1,IP:${1}"
  $JAVA_HOME/bin/keytool -export -keystore $DATAFARI_HOME/ssl-keystore/datafari-keystore.p12 -storetype PKCS12 -alias tomcat -storepass DataFariAdmin -file $DATAFARI_HOME/ssl-keystore/datafari-cert.csr
  $JAVA_HOME/bin/keytool -import -keystore $DATAFARI_HOME/ssl-keystore/datafari-truststore.p12 -storetype PKCS12 -storepass DataFariAdmin -alias tomcat -noprompt -file $DATAFARI_HOME/ssl-keystore/datafari-cert.csr
}

generate_certificates_apache() {

  # Generate SSL certificate for Apache
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/ssl-keystore/apache/config/datafari-config.csr >>$installerLog 2>&1
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/ssl-keystore/apache/config/tomcat.conf >>$installerLog 2>&1
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/ssl-keystore/apache/config/datafari-services.conf >>$installerLog 2>&1
  openssl req -config $DATAFARI_HOME/ssl-keystore/apache/config/datafari-config.csr -new -newkey rsa:2048 -nodes -keyout $DATAFARI_HOME/ssl-keystore/apache/datafari.key -out $DATAFARI_HOME/ssl-keystore/apache/datafari.csr
  openssl x509 -req -days 365 -in $DATAFARI_HOME/ssl-keystore/apache/datafari.csr -signkey $DATAFARI_HOME/ssl-keystore/apache/datafari.key -out $DATAFARI_HOME/ssl-keystore/apache/datafari.crt
  mkdir -p $DATAFARI_HOME/ssl-keystore/apache/backup/
  cp $DATAFARI_HOME/ssl-keystore/apache/datafari.key $DATAFARI_HOME/ssl-keystore/apache/backup/
  cp $DATAFARI_HOME/ssl-keystore/apache/datafari.crt $DATAFARI_HOME/ssl-keystore/apache/backup/
  
}

generate_certificates_elk() {

  # Generate SSL certificate for Apache
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/ssl-keystore/elk/config/datafari-config.csr >>$installerLog 2>&1
  openssl req -config $DATAFARI_HOME/ssl-keystore/elk/config/datafari-config.csr -new -newkey rsa:2048 -nodes -keyout $DATAFARI_HOME/ssl-keystore/elk/datafari-key.pem -out $DATAFARI_HOME/ssl-keystore/elk/datafari.csr
  openssl x509 -req -days 365 -in $DATAFARI_HOME/ssl-keystore/elk/datafari.csr -signkey $DATAFARI_HOME/ssl-keystore/elk/datafari-key.pem -out $DATAFARI_HOME/ssl-keystore/elk/datafari-cert.pem
  mkdir $DATAFARI_HOME/ssl-keystore/elk/backup/
  cp $DATAFARI_HOME/ssl-keystore/elk/datafari-key.pem $DATAFARI_HOME/ssl-keystore/elk/backup/
  cp $DATAFARI_HOME/ssl-keystore/elk/datafari-cert.pem $DATAFARI_HOME/ssl-keystore/elk/backup
  mv $DATAFARI_HOME/ssl-keystore/elk/datafari-key.pem $DATAFARI_HOME/elk/elasticsearch/config/
  mv $DATAFARI_HOME/ssl-keystore/elk/datafari-cert.pem $DATAFARI_HOME/elk/elasticsearch/config/
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/elk/elasticsearch/plugins/opendistro_security/tools/install_datafari_configuration.sh >>$installerLog 2>&1

}

init_collection_name() {
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $SOLR_INSTALL_DIR/solr_home/FileShare/core.properties >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $SOLR_INSTALL_DIR/solr_home/FileShare/conf/customs_schema/addCustomSchemaInfo.sh >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $DATAFARI_HOME/bin/datafari-manager.sh >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $DATAFARI_HOME/bin/common/config/manifoldcf/init/outputconnections/DatafariSolrNoTika.json >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/webapps/Datafari/resources/js/admin/ajax/alerts.js >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/webapps/Datafari/resources/js/parameters.js >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/webapps/Datafari/resources/js/admin/ajax/queryElevator.js >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/webapps/Datafari/resources/js/AjaxFranceLabs/modules/QueryElevator.module.js >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/webapps/Datafari/admin/ajax/SchemaAdmin.jsp >>$installerLog 2>&1
  sed -i -e "s~@MAINCOLLECTION@~${1}~g" $TOMCAT_HOME/webapps/Datafari/admin/admin-sidebar.jsp >>$installerLog 2>&1

}

init_node_host() {
  sed -i -e "s/@NODEHOST@/${1}/g" $SOLR_INSTALL_DIR/bin/solr.in.sh >>$installerLog 2>&1
  sed -i -e "s/@NODEHOST@/${1}/g" $SOLR_INSTALL_DIR/server/etc/jetty.xml >>$installerLog 2>&1
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/bin/zkUtils/reloadCollections.sh >>$installerLog 2>&1
  sed -i -e "s/@NODEHOST@/${1}/g" $DATAFARI_HOME/bin/zkUtils/init-solr-collections.sh >>$installerLog 2>&1
}

init_solr_node() {
  sed -i -e "s/@SOLRNODEIP@/${1}/g" $DATAFARI_HOME/bin/zkUtils/reloadCollections.sh >>$installerLog 2>&1
  sed -i -e "s/@SOLRNODEIP@/${1}/g" $DATAFARI_HOME/bin/zkUtils/init-solr-collections.sh >>$installerLog 2>&1
  sed -i -e "s/@SOLRNODEIP@/${1}/g" $TOMCAT_HOME/conf/solr.properties >>$installerLog 2>&1
  sed -i -e "s/@SOLRNODEIP@/${1}/g" $DATAFARI_HOME/ssl-keystore/apache/config/tomcat.conf >>$installerLog 2>&1
  
    
}

init_solr_hosts() {
  sed -i -e "s/@SOLRHOSTS@/${1}/g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  sed -i -e "s/@SOLRHOSTS@/${1}/g" $SOLR_INSTALL_DIR/bin/solr.in.sh >>$installerLog 2>&1
  sed -i -e "s/@SOLRHOSTS@/${1}/g" $DATAFARI_HOME/bin/zkUtils/init-zk.sh >>$installerLog 2>&1
}

init_zk() {
  #sed -i -e "s/@NODEHOST@/${1}/g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  sed -i -e "s/@ZKHOST@/${1}/g" $DATAFARI_HOME/bin/common/config/manifoldcf/init/outputconnections/DatafariSolrNoTika.json >>$installerLog 2>&1
  @VERSION-INIT-ZK@
}

init_zk_data() {
  mkdir -p $DATAFARI_HOME/zookeeper/data
  touch $DATAFARI_HOME/zookeeper/data/myid
  echo "${1}" >>$DATAFARI_HOME/zookeeper/data/myid
}

init_zk_mcf() {
  sed -i -e "s/@ZKHOST-MCF@/localhost:2182/g" $MCF_HOME/properties.xml >>$installerLog 2>&1
}

init_mcf() {
  sed -i -e "s/@MCFPROCESSID@/${1}/g" $MCF_HOME/options.env.unix >>$installerLog 2>&1
}

init_shards() {
  sed -i -e "s/@NUMSHARDS@/${1}/g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  sed -i -e "s/@NUMSHARDS@/${1}/g" $DATAFARI_HOME/bin/start-datafari.sh >>$installerLog 2>&1
}

init_main_node() {
  sed -i -e "s/@ISMAINNODE@/true/g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  
}

init_solrcloud() {
  mkdir -p $SOLR_INSTALL_DIR/solrcloud
  mv $SOLR_INSTALL_DIR/solr_home/FileShare $SOLR_INSTALL_DIR/solrcloud
  mv $SOLR_INSTALL_DIR/solr_home/Statistics $SOLR_INSTALL_DIR/solrcloud
  mv $SOLR_INSTALL_DIR/solr_home/Promolink $SOLR_INSTALL_DIR/solrcloud
  mv $SOLR_INSTALL_DIR/solr_home/Entities $SOLR_INSTALL_DIR/solrcloud
  mv $SOLR_INSTALL_DIR/solr_home/Duplicates $SOLR_INSTALL_DIR/solrcloud
  mkdir -p $SOLR_INSTALL_DIR/solrcloud/FileShare/lib/custom/customer

}

init_folders() {
  mkdir -p $DATAFARI_HOME/logs/elk
  mkdir -p $DATAFARI_HOME/logs/tika-server
  mkdir -p $DATAFARI_HOME/bin/backup/
  mkdir -p $DATAFARI_HOME/bin/backup/cassandra
  mkdir -p $DATAFARI_HOME/bin/backup/datafari_conf
  mkdir -p $DATAFARI_HOME/bin/backup/mcf-script
  mkdir -p $DATAFARI_HOME/bin/backup/mcf
  mkdir -p $DATAFARI_HOME/bin/backup/solr
  mkdir -p $SOLR_INSTALL_DIR/solr_home/FileShare/lib/custom/customer/
  
  
}

init_password() {
  apacheAdminUser=apacheadmin
  elkAdminUser=elkadmin
  solrAdminUser=solradmin
  monitAdminUser=monitadmin
  glancesAdminUser=glancesadmin
  password=${1}
  realm=datafari
  cd $MCF_HOME/obfuscation-utility
  chmod -R 777 $MCF_HOME/obfuscation-utility/obfuscate.sh
  sed -i -e "s~@PASSWORD@~$(./obfuscate.sh ${1})~g" $MCF_HOME/properties-global.xml >>$installerLog 2>&1
  sed -i -e "s/@TEMPADMINPASSWORD@/${1}/g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  sed -i -e "s~@MCF_ADMIN_PASSWORD@~${1}~g" $DATAFARI_HOME/bin/purgeUtils/vacuum-mcf.sh >>$installerLog 2>&1
  sed -i -e "s~@MCF_ADMIN_PASSWORD@~${1}~g" $DATAFARI_HOME/bin/monitorUtils/check_jobs_mcf.sh >>$installerLog 2>&1
  digestAdminUser="$( printf "%s:%s:%s" "$apacheAdminUser" "$realm" "$password" | md5sum | awk '{print $1}' )"
  digestElkUser="$( printf "%s:%s:%s" "$elkAdminUser" "$realm" "$password" | md5sum | awk '{print $1}' )"
  digestSolrUser="$( printf "%s:%s:%s" "$solrAdminUser" "$realm" "$password" | md5sum | awk '{print $1}' )"
  digestMonitUser="$( printf "%s:%s:%s" "$monitAdminUser" "$realm" "$password" | md5sum | awk '{print $1}' )"
  digestGlancesUser="$( printf "%s:%s:%s" "$glancesAdminUser" "$realm" "$password" | md5sum | awk '{print $1}' )"
  printf "%s:%s:%s\n" "$apacheAdminUser" "$realm" "$digestAdminUser" >> "$DATAFARI_HOME/apache/password/htpasswd"
  printf "%s:%s:%s\n" "$elkAdminUser" "$realm" "$digestElkUser" >> "$DATAFARI_HOME/apache/password/htpasswd"
  printf "%s:%s:%s\n" "$solrAdminUser" "$realm" "$digestSolrUser" >> "$DATAFARI_HOME/apache/password/htpasswd"
  printf "%s:%s:%s\n" "$monitAdminUser" "$realm" "$digestMonitUser" >> "$DATAFARI_HOME/apache/password/htpasswd"
  printf "%s:%s:%s\n" "$glancesAdminUser" "$realm" "$digestGlancesUser" >> "$DATAFARI_HOME/apache/password/htpasswd"
}

init_password_postgresql() {
  sed -i -e "s~@POSTGRESPASSWORD@~$(./obfuscate.sh ${1})~g" $MCF_HOME/properties-global.xml >>$installerLog 2>&1
  sed -i -e "s~@POSTGRESPASSWORD@~$(./obfuscate.sh ${1})~g" $TOMCAT_HOME/conf/mcf-postgres.properties >>$installerLog 2>&1
  sed -i -e "s~@POSTGRESPASSWORD@~${1}~g" $DATAFARI_HOME/pgsql/pwd.conf >>$installerLog 2>&1
}

init_apache_ssl() { 
  getMCF=""
  getMCFSimplified=""
  getSolrAdmin=""
  apachePresent="true"
  getMCFAdmin="\"/datafari-mcf-crawler-ui/\""
  getMCF="\"/datafari-mcf-crawler-ui/\""
  getMCFSimplified="\"/datafari-mcf-crawler-ui/index.jsp?p=showjobstatus.jsp\""
  getSolrAdmin="\"/solr/\""
  getMonitAdmin="\"/monit/\""
  getGlancesAdmin="\"/glances/\""
  sed -i -e "s/@APACHE@/true/g" $TOMCAT_HOME/conf/datafari.properties >>$installerLog 2>&1
  cp -r $DATAFARI_HOME/apache/html/* /var/www/html/

  if [ -d /etc/apache2 ]; then
    cp $DATAFARI_HOME/ssl-keystore/apache/config/tomcat.conf /etc/apache2/sites-available/
    cp $DATAFARI_HOME/ssl-keystore/apache/config/envvars /etc/apache2/
    ln -s /etc/apache2/* $DATAFARI_HOME/apache/
    rm -f /var/www/html/index.jsp
    mkdir /var/apache
    mkdir /var/apache/logs
    ln -s /var/apache/logs $DATAFARI_HOME/logs/apache
    a2enmod proxy
    a2enmod proxy_ajp
    a2enmod proxy_http
    a2enmod ssl
    a2enmod proxy_http
    a2enmod auth_digest
    a2enmod rewrite
    a2enmod headers
    a2dissite 000-default
    a2dissite default-ssl
    a2ensite tomcat
    /etc/init.d/apache2 start
    /etc/init.d/apache2 stop
    update-rc.d apache2 disable
    
  elif [ -d /etc/httpd ]; then
    cp $DATAFARI_HOME/ssl-keystore/apache/config/httpd.conf /etc/httpd/conf/
    mkdir /etc/httpd/sites-available /etc/httpd/sites-enabled
    mkdir /var/apache
    mkdir /var/apache/pid
    mkdir /var/apache/logs
    chmod -R 775 /var/apache
    chown -R $DATAFARI_USER /var/apache
    cp $DATAFARI_HOME/ssl-keystore/apache/config/tomcat.conf /etc/httpd/sites-available/
    ln -s /etc/httpd/sites-available/tomcat.conf /etc/httpd/sites-enabled/tomcat.conf
    ln -s /var/apache/pid $DATAFARI_HOME/pid/apache
    ln -s /var/apache/logs $DATAFARI_HOME/logs/apache
    cp $DATAFARI_HOME/ssl-keystore/apache/config/envvars /etc/httpd/
    ln -s /etc/httpd/* $DATAFARI_HOME/apache/
    rm -f /var/www/html/index.jsp
    /usr/sbin/setsebool -P httpd_can_network_connect 1
    apachectl start
    apachectl stop
    
  fi
  sed -i -e "s~\"@GET-MCF-IP@\"~${getMCFAdmin}~g" $TOMCAT_HOME/webapps/Datafari/admin/admin-sidebar.jsp >>$installerLog 2>&1
  sed -i -e "s~\"@GET-MCF-IP@\"~${getMCF}~g" $TOMCAT_HOME/webapps/Datafari/resources/js/header.js >>$installerLog 2>&1
  sed -i -e "s~\"@GET-MCF-IP@\"~${getMCFSimplified}~g" $TOMCAT_HOME/webapps/Datafari/resources/js/admin/ajax/mcfSimplified.js >>$installerLog 2>&1
  
  
  sed -i -e "s~\"@GET-SOLR-IP@\"~${getSolrAdmin}~g" $TOMCAT_HOME/webapps/Datafari/admin/admin-sidebar.jsp >>$installerLog 2>&1
  sed -i -e "s~\"@GET-MONIT-IP@\"~${getMonitAdmin}~g" $TOMCAT_HOME/webapps/Datafari/admin/admin-sidebar.jsp >>$installerLog 2>&1
  sed -i -e "s~\"@GET-GLANCES-IP@\"~${getGlancesAdmin}~g" $TOMCAT_HOME/webapps/Datafari/admin/admin-sidebar.jsp >>$installerLog 2>&1
  sed -i -e "s/@APACHE-PRESENT@/${apachePresent}/g" $TOMCAT_HOME/webapps/Datafari/admin/admin-sidebar.jsp >>$installerLog 2>&1
  
}


clean_monoserver_node() {
  rm -rf $DATAFARI_HOME/bin/start-solr.sh
  rm -rf $DATAFARI_HOME/bin/stop-solr.sh
  rm -rf $DATAFARI_HOME/bin/start-mcf.sh
  rm -rf $DATAFARI_HOME/bin/stop-mcf.sh
  rm -rf $DATAFARI_HOME/bin/start-zk.sh
  rm -rf $DATAFARI_HOME/bin/stop-zk.sh
  rm -rf $DATAFARI_HOME/bin/start-zk-mcf.sh
  rm -rf $DATAFARI_HOME/bin/stop-zk-mcf.sh
  rm -rf $DATAFARI_HOME/bin/start-visilia.sh
  rm -rf $DATAFARI_HOME/bin/cluster_init.sh
}

init_permissions() {
  echo "Init permissions of Datafari. Please wait (up to 5 minutes depending on the speed of your HDD)"
  cd $DIR
  mkdir $DATAFARI_HOME/tmp
  echo "Init permissions 1/6"
  find $DATAFARI_HOME -type f -not -perm 775 > list_files_permissions.txt
  while IFS= read -r file; do
    chmod 775 "$file"
  done < list_files_permissions.txt
  rm -rf list_files_permissions.txt
  echo "Init permissions 2/6"
  find $DATAFARI_HOME \! -user ${DATAFARI_USER} -print > list_files_owner.txt
  while IFS= read -r file; do
    chown ${DATAFARI_USER} "$file"
  done < list_files_owner.txt
  rm -rf list_files_owner.txt
  echo "Init permissions 3/6"
  chown -R ${POSTGRES_USER} $DATAFARI_HOME/pgsql/
  echo "Init permissions 4/6"
  chmod -R 700 $DATAFARI_HOME/pgsql/
  echo "Init permissions 5/6"
  chmod -R 777 $DATAFARI_HOME/pid
  chmod -R 777 $DATAFARI_HOME/logs
  echo "Init permissions 6/6"
  if [ -d /etc/apache2 ]; then
    chown -R ${DATAFARI_USER} /etc/apache2
    chmod -R 775 /etc/apache2
  elif [ -d /etc/httpd ]; then
    echo '$DATAFARI_USER ALL=NOPASSWD:/sbin/apachectl' >> /etc/sudoers
    chown -R ${DATAFARI_USER} /etc/httpd
    chmod -R 775 /etc/httpd
  fi
  echo "Init permissions end"
  
}

init_permissions_file_datafari_properties() {
sleep 30
echo "cht permissions datafari properties"
  chmod -R 775 $TOMCAT_HOME/conf/datafari.properties
  chown ${DATAFARI_USER} $TOMCAT_HOME/conf/datafari.properties
}

init_users() {
  id -u postgres >/dev/null 2>&1 || useradd postgres
  useradd ${DATAFARI_USER} -m -s /bin/bash
  if [ -d /etc/apache2 ]; then
    usermod -aG sudo ${DATAFARI_USER}
  elif [ -d /etc/httpd ]; then
    usermod -aG wheel ${DATAFARI_USER}
  fi
  echo "$DATAFARI_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
}

secure_tomcat() { 
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 8080 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 8080 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for ((i=1;i<=$mcfNodesNumber;i++)); do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 8080 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 8080 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8080 -j DROP
  
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 8009 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 8009 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for i in "${mcfNodesNumber}"; do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 8009 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 8009 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8009 -j DROP
  
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 8443 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 8443 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for ((i=1;i<=$mcfNodesNumber;i++)); do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 8443 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 8443 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8443 -j DROP
}




secure_tomcat_mcf() {
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 9080 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 9080 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for ((i=1;i<=$mcfNodesNumber;i++)); do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 9080 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 9080 -j ACCEPT
  iptables -A INPUT -p tcp --dport 9080 -j DROP
  
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 9009 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 9009 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for ((i=1;i<=$mcfNodesNumber;i++)); do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 9009 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 9009 -j ACCEPT
  iptables -A INPUT -p tcp --dport 9009 -j DROP

  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 9443 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 9443 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for ((i=1;i<=$mcfNodesNumber;i++)); do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 9443 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 9443 -j ACCEPT
  iptables -A INPUT -p tcp --dport 9443 -j DROP
  
}

secure_zk_solr() {
iptables -A INPUT -p tcp -s 127.0.0.1 --dport 2181 -j ACCEPT
  
    
IFS=', ' read -r -a array <<<"$SOLRHOSTS"
  for index in "${!array[@]}"; do
    echo "$index ${array[index]}"
    var2=${array[index]}
    var2=${var2%:2181}
    iptables -A INPUT -p tcp -s ${var2} --dport 2181 -j ACCEPT
  done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      IFS=', ' read -r -a array <<<"$MCFHOSTS"
  for index in "${!array[@]}"; do
    echo "$index ${array[index]}"
    var2=${array[index]}
    iptables -A INPUT -p tcp -s ${var2} --dport 2181 -j ACCEPT
  done
    fi
  
  iptables -A INPUT -p tcp -s $MAINNODEHOST --dport 2181 -j ACCEPT
  iptables -A INPUT -p tcp -s ${1} --dport 2181 -j ACCEPT
  iptables -A INPUT -p tcp --dport 2181 -j DROP
  
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 2888 -j ACCEPT
  
    IFS=', ' read -r -a array <<<"$SOLRHOSTS"
  for index in "${!array[@]}"; do
    echo "$index ${array[index]}"
    var2=${array[index]}
    var2=${var2%:2181}
    iptables -A INPUT -p tcp -s ${var2} --dport 2888 -j ACCEPT
  done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      IFS=', ' read -r -a array <<<"$MCFHOSTS"
  for index in "${!array[@]}"; do
    echo "$index ${array[index]}"
    var2=${array[index]}
    iptables -A INPUT -p tcp -s ${var2} --dport 2888 -j ACCEPT
  done
    fi
  
  iptables -A INPUT -p tcp -s $MAINNODEHOST --dport 2888 -j ACCEPT
  iptables -A INPUT -p tcp -s ${1} --dport 2888 -j ACCEPT
  
  iptables -A INPUT -p tcp --dport 2888 -j DROP
  
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 3888 -j ACCEPT
  
    IFS=', ' read -r -a array <<<"$SOLRHOSTS"
  for index in "${!array[@]}"; do
    echo "$index ${array[index]}"
    var2=${array[index]}
    var2=${var2%:2181}
    iptables -A INPUT -p tcp -s ${var2} --dport 3888 -j ACCEPT
  done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      IFS=', ' read -r -a array <<<"$MCFHOSTS"
  for index in "${!array[@]}"; do
    echo "$index ${array[index]}"
    var2=${array[index]}
    iptables -A INPUT -p tcp -s ${var2} --dport 3888 -j ACCEPT
  done
    fi
  
  iptables -A INPUT -p tcp -s $MAINNODEHOST --dport 3888 -j ACCEPT
  iptables -A INPUT -p tcp -s ${1} --dport 3888 -j ACCEPT
  
  iptables -A INPUT -p tcp --dport 3888 -j DROP
  

}

secure_elk() { 
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 9200 -j ACCEPT
  if [ "$NODETYPE" == "main" ]; then
    for ((i=1;i<=$solrNodesNumber;i++)); do

      solrvalue=solr$i
      solrproperty=$(echo $solrvalue)
      solrServer=`getProperty $solrproperty $CONFIG_FILE`

      iptables -A INPUT -p tcp -s ${solrServer} --dport 9200 -j ACCEPT
    done
  
    if [ $mcfNodesNumber -ne 0 ]; then
      for ((i=1;i<=$mcfNodesNumber;i++)); do

        mcfvalue=mcf$i
        mcfproperty=$(echo $mcfvalue)
        mcfServer=`getProperty $mcfproperty $CONFIG_FILE`
        iptables -A INPUT -p tcp -s ${mcfServer} --dport 9200 -j ACCEPT
  
      done
    fi
  fi
  iptables -A INPUT -p tcp -s ${1} --dport 9200 -j ACCEPT
  iptables -A INPUT -p tcp --dport 9200 -j DROP
  
}

secure_monit() {
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 2812 -j ACCEPT
  iptables -A INPUT -p tcp -s ${1} --dport 2812 -j ACCEPT
  iptables -A INPUT -p tcp --dport 2812 -j DROP
}

secure_glances() {
  iptables -A INPUT -p tcp -s 127.0.0.1 --dport 61208 -j ACCEPT
  iptables -A INPUT -p tcp -s ${1} --dport 61208 -j ACCEPT
  iptables -A INPUT -p tcp --dport 61208 -j DROP
}

stop_firewalld_start_iptables() {
  systemctl stop firewalld
  systemctl disable firewalld
  systemctl mask firewalld
  systemctl enable iptables
  systemctl start iptables
  iptables -F
}
save_iptables_rules() { 

  if [ -d /etc/apache2 ]; then
    iptables-save > /etc/iptables/rules.v4
  elif [ -d /etc/httpd ]; then
    
    service iptables save
  fi
}

log4shell_mitigation() {
  file_array=()

  for i in $(find $DATAFARI_HOME/elk -type f \( -name \*.jar \) -print)
  do
    isVulnerability=$(unzip -l $i | grep  org/apache/logging/log4j/core/lookup/JndiLookup.class)
    if [ "$isVulnerability"  != "" ]; then
      array_entry="$i"
echo "Found this file to patch : $i"
    file_array+=($array_entry)
fi
  done


if [ ${#file_array[@]} -eq 0 ]; then
    echo "No files need to be patched"
else
echo "Patch going to be applied on previous files"

for file_entry in "${file_array[@]}"
  do
echo $file_entry
zip -qd $file_entry org/apache/logging/log4j/core/lookup/JndiLookup.class
        chmod 775 $file_entry
        chown datafari $file_entry
done

fi

}


########
# initialization node types
   
initialization_monoserver() {
  echo "initialization for monoserver"
  localip=localhost
  #delete_certificates
  init_users
  init_war
  init_git
  init_folders
  init_elk localhost "mono"
  init_logstash localhost
  generate_certificates $NODEHOST
  generate_certificates_apache $NODEHOST
  generate_certificates_elk $NODEHOST
  init_collection_name $SOLRMAINCOLLECTION
  init_node_host $NODEHOST
  source "${DATAFARI_HOME}/bin/deployUtils/monoserver_${DATAFARITYPE}_memory.properties"
  init_memory
  source "${DATAFARI_HOME}/bin/deployUtils/temp_directory.properties"
  init_temp_directory
  init_solr_node $localip
  init_solr_hosts $localip
  init_zk $localip
  init_zk_mcf
  init_mcf "A"
  init_shards $SOLRNUMSHARDS
  init_main_node
  init_solrcloud
  clean_monoserver_node
  init_password $TEMPADMINPASSWORD
  init_password_postgresql $TEMPPGSQLPASSWORD
  init_apache_ssl
  if [ -d /etc/httpd ]; then
    stop_firewalld_start_iptables
  fi
  secure_tomcat $NODEHOST
  secure_tomcat_mcf $NODEHOST
  secure_monit $NODEHOST
  secure_glances $NODEHOST
  #secure_elk $NODEHOST
  save_iptables_rules
  
  log4shell_mitigation
  init_permissions
  sed -i 's/\(STATE *= *\).*/\1initialized/' $INIT_STATE_FILE
  init_permissions_file_datafari_properties

}


####


### Init Datafari main function

init_datafari() {

if [ "$(whoami)" != "root" ]; then
  echo "Script must be run as user: root"
  echo "Script will exit"
  exit 1
fi

if  [[ "$STATE" = *initialized* ]];
then
  echo "Datafari is already initialized. You can start Datafari directly."
  echo "If you want to reinitialize Datafari, edit the file $DATAFARI_HOME/bin/common/init_state.properties and replace the content by that : STATE=installed "
  echo "The script will now exit"
  exit 0
fi    
    
check_java;
check_ram;
check_python;
is_file_present $CONFIG_FILE
is_variable_set $INSTALLER_TYPE
if [ "$INSTALLER_TYPE" == "interactive" ]; then
    echo "Interactive installer mode. You need to answer some questions to initialize Datafari"
    interactive_questions
fi
source $CONFIG_FILE
is_variable_set $NODETYPE
if [ "$NODETYPE" == "monoserver" ]; then
    echo "Monoserver initialization"
    echo "check of the variables of the properties file are set"
    echo "nodehost check"
    is_variable_set $NODEHOST
    echo "numshards check"
    is_variable_set $SOLRNUMSHARDS
    echo "solrhosts check"
  is_variable_set $SOLRHOSTS
    echo "maincollection check"
    is_variable_set $SOLRMAINCOLLECTION
  echo "datafari password check"
    is_variable_set $TEMPADMINPASSWORD
  echo "postgresql password check"
    is_variable_set $TEMPPGSQLPASSWORD
    echo "elk activation check"
    is_variable_set $ELKactivation
    
  echo "Check complete."

    initialization_monoserver
fi

@VERSION-INIT@

#is_variable_set $NODEHOST
#is_variable_set $MAINNODEHOST
#is_variable_set $SOLRNUMSHARDS
#is_variable_set $SOLRHOSTS
#is_variable_set $SOLRMAINCOLLECTION

echo "Initialization done"

if [ "$INSTALLER_TYPE" == "interactive" ] && [ "$NODETYPE" == "monoserver" ]; then
    question_start_datafari
    if [ "$start_datafari" == "true" ]; then
      echo "Datafari is starting"
      cd $DIR
      bash start-datafari.sh
      echo "Datafari is started. The url to access to Datafari is : https://${NODEHOST}/Datafari"
      echo "If you use Docker on a remote server, adapt the URL to indicate the IP or the hostname of the container"
    else
      echo "You can now start Datafari. Launch the start-datafari.sh script. After Datafari is started, you can access to Datafari at this URL : https://${NODEHOST}/Datafari"
  fi
      
else
  echo "You can now start Datafari. Launch the start-datafari.sh script. After Datafari is started, you can access to Datafari at this URL : https://${NODEHOST}/Datafari"
  
  
fi




}


init_datafari;
