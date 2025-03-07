#!/bin/bash -e
#
#
# Start Solr only
#
#

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source "${DIR}/set-datafari-env.sh"
source "${DIR}/utils.sh"
source $INIT_STATE_FILE
source $CONFIG_FILE
source "${DIR}/../elk/scripts/set-elk-env.sh"
source "${DIR}/../elk/scripts/elk-utils.sh"


if run_as ${DATAFARI_USER} "bash datafari-manager.sh is_running $SOLR_PID_FILE"; then
  PID=$(run_as ${DATAFARI_USER} "cat $SOLR_PID_FILE");
  echo "Error : Solr seems to be already running with PID $PID"
  exit 1
fi

if  [[ "$NODETYPE" = *solr* ]];
then
  
    
  run_as ${DATAFARI_USER} "bash datafari-manager.sh start_solr";



  if  [[ "$ELKactivation" = *true* ]]; then
    if  [[ "$STATE" = *initialized* ]]; then
      cd $ELK_HOME/scripts
      run_as ${DATAFARI_USER} "bash elk-manager.sh init_standalone_logstash";
      cd $DIR
        
    fi
    if run_as ${DATAFARI_USER} "bash datafari-manager.sh is_running $LOGSTASH_PID_FILE"; then
      echo "Error : Logstash seems to be already running with PID $(cat $LOGSTASH_PID_FILE)"
      exit 1
    fi
    cd $ELK_HOME/scripts
    run_as ${DATAFARI_USER} "bash elk-manager.sh start_logstash";
    cd $DIR
        
    
  fi

  if  [[ "$STATE" = *initialized* ]]; then
    run_as ${DATAFARI_USER} `sed -i 's/\(STATE *= *\).*/\1active/' $INIT_STATE_FILE`  
  fi
fi
