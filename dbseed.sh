#!/bin/bash
# Author: Maxim Vasilev <admin@qwertys.ru>
# Description: Reinitializes specified (or all) databases

# Raise an error in case of unbound var
set -u
myname=`basename $0`

conf_dir="${HOME}/.k8s-ca"

###
# Globs
###

# Error codes
E_MISC=20
E_ARGS=21
E_CONF=22
E_DBCONN=23
E_AUTH=24
E_TIMEOUT=25
E_SYNC=26

# Log messages
LOG_AUTH="Authorization successful."
LOG_DELETE="Deleted pod"
LOG_NOTREADY="PostgreSQL not ready yet."
LOG_READY="PostgreSQL is up."
LOG_CLEAR="Truncating database"
LOG_INSERT="Inserting dump into DB"
LOG_DUMP="Taking dump of DB"
LOG_OBFUSCATE="User obfuscation successful."
LOG_SYNC="PostgreSQL to ElasticSearch sync complete."
LOG_PUBLISH="Publishing test entities."

LOG_E_MISC="Unknown error occurred."
LOG_E_ARGS="Invalid arguments supplied."
LOG_E_CONF="Invalid or missing configuration"
LOG_E_DBCONN="Failed to connect to postgres"
LOG_E_AUTH="Authorization failed. Aborting."
LOG_E_TIMEOUT="Timeout waiting for PostgreSQL to start."
LOG_E_SYNC="Failed to sync ElasticSearch to PostgreSQL."
LOG_E_DUMPDIR="Failed to create temporary directory."
LOG_E_ESSYNC="Could not find elastic-sync binary"

###
# Functions
###

clusterAuth() {
    if [[ ! -d $conf_dir ]]; then mkdir $conf_dir; fi
    echo -n $k8s_ca | base64 -d > $conf_dir/cluster.crt

    kubectl config set-credentials cluster --password=$k8s_pass --username=$k8s_user > /dev/null
    kubectl config set-cluster cluster --server="$k8s_addr" --embed-certs=false --certificate-authority=$conf_dir/cluster.crt > /dev/null
    kubectl config set-context cluster --user=cluster --cluster=cluster > /dev/null
    kubectl config use-context cluster > /dev/null

    logEvent $LOG_AUTH "'$k8s_addr'"
}

testDbConn() {
    $psql -ql > /dev/null
}

restartDbPod() {
    pod=$1
    attempt=0

    kubectl delete pod $pod
    logEvent $LOG_DELETE $pod

    until [[ $attempt = $recovery_attempt_count ]]
    do
        sleep $recovery_attempt_timeout
        testDbConn && break
        logEvent $LOG_NOTREADY
        let attempt++

        if [[ $attempt = $recovery_attempt_count ]]
        then
            errorExit $E_TIMEOUT $LOG_E_TIMEOUT
        fi
    done

    logEvent $LOG_READY

    kubectl delete pod -l app=kafka-connect
}

getDump() {
    db_name=$1
    dump_path=$2
    pg_dump="pg_dump -U $db_user -h $db_host -a"

    logEvent $LOG_DUMP $db_name

    $pg_dump $db_name > $dump_path
}

insertDump() {
    db_name=$1
    dump_path=$2

    logEvent $LOG_INSERT $db_name

    $psql -d $db_name -f $dump_path > /dev/null 2> /dev/null
}

obfuscateUsers() {
    not_in_list=`echo ${ignore_userid[@]} | sed -e s/' '/', '/g`
    $psql -d users -q \
      -c "UPDATE users SET
        first_name = 'user' || id,
        last_name = 'user' || id,
        middle_name = 'user' || id,
        phone = '+7495' || id,
        email = id || '@crapmail.tld'
        WHERE id NOT IN ( $not_in_list )" \
    && $psql -d users -q \
      -c "UPDATE identities SET
        email = user_id || '@crapmail.tld',
        password = 'JJIKrKq4UtXrmNbXlflH9zhYxClU+AnngJ1Pl3NH/xA=.1x2DtY66Pg'
        WHERE id NOT IN ( $not_in_list )" \
    && $psql -d delivery -q \
      -c "INSERT INTO roles 
        (user_id, name) 
        VALUES ($admin_userid, 'superuser')" \
    && $psql -d stores -q \
      -c "INSERT INTO user_roles 
        (user_id, name) 
        VALUES ($admin_userid, 'superuser')" \
    && $psql -d billing -q \
      -c "INSERT INTO roles 
        (user_id, name) 
        VALUES ($admin_userid, 'superuser')" \
    && $psql -d users -q \
      -c "INSERT INTO user_roles 
        (user_id, name) 
        VALUES ($admin_userid, 'superuser')" \
    && logEvent $LOG_OBFUSCATE
}

publishStoreProduct() {
    logEvent $LOG_PUBLISH
    for storeid in ${teststoreids[@]}
    do
        $psql -d stores -q \
          -c "UPDATE stores SET
          status = 'published'
          WHERE id = $storeid"
    done
    for productid in ${testproductids[@]}
    do
        $psql -d stores -q \
          -c "UPDATE base_products SET
          status = 'published',
          store_status = 'published'
          WHERE id = $productid"
    done
}

clearDB() {
    db_name="$1"

    logEvent $LOG_CLEAR $db_name

    sequences=( `$psql -d $db_name -F, -c \\\ds | cut -d, -f2` )
    tables=( `$psql -d $db_name -F, -c \\\dt | cut -d, -f2` )

    for table in ${tables[@]}
    do
        $psql -d $db_name \
          -c "TRUNCATE TABLE $table CASCADE" \
          > /dev/null 2> /dev/null
    done

    for sequence in ${sequences[@]}
    do
        $psql -d $db_name \
          -c "ALTER SEQUENCE $sequence RESTART WITH 1;" \
          > /dev/null 2> /dev/null
    done
}

resetDB() {
    db_name=$1

    if [[ -s ./sql/${db_name}/config ]]
    then
        . ./sql/${db_name}/config || errorExit $E_CONF $LOG_E_CONF
        export PGPASSWORD="$db_pass"
        clearDB $db_name
        echo resetDB $db_name
    else
        errorExit $E_ARGS $LOG_E_ARGS
    fi
}

dumpSync() {
    test -d $dumpdir || mkdir -p $dumpdir
    dblist=( `$psql -F, -l | cut -d, -f1 | grep -ve postgres -ve template` )

    for db in ${dblist[@]}
    do
        dump_path=${dumpdir%%/}/${db}.sql
        getDump $db $dump_path
        clearDB $db
        insertDump $db $dump_path
        rm $dump_path
    done
}

elasticSync() {
    for index in ${es_indices[@]}
    do
        $espath -d \
          -p $es_dburl \
          -e $es_host \
          $index
    done
}

printHelp() {
    echo "Usage:
    $myname reset [database] - reinitialize specified database
    $myname reset ALL - reinitialize all databases
    $myname sync - sync this instance with production
    $myname help - print this help message"
}

# Logging function (KO to the rescue)
logEvent() {
    timestamp=`date -R`
    log_msg="$@"

    if [[ ${log_path-stdout} = "stdout" ]]
    then
        echo "[$timestamp] $log_msg"
    else
        echo "[$timestamp] $log_msg" >> $log_path
    fi
}

# Panic function
errorExit() {
    exit_code=$1
    shift
    if [[ $# > 0 ]]; then logEvent "$@"; fi
    exit $exit_code
}

###
# main()
###

. ${DBSEED_CONF-"conf/development"}

psql="psql 
    -U ${db_user-postgres}
    -h ${db_host-localhost}
    --tuples-only
    --no-align"

# Enable debug?
if [[ "${debug_enabled-false}" = "true" ]]; then set -x; fi

# Redirect output
if [[ "${log_applications-false}" = "true" ]]
then
    exec >> "$log_path"
    exec 2>> "$log_path"
fi

case "${1-}" in
"help" )
    printHelp
    ;;
"reset" )
    shift
    db_name="${1-nonexistent}"

    testDbConn || errorExit $E_DBCONN $LOG_E_DBCONN

    if [[ $db_name = ALL ]]
    then
        dbs=( `ls sql` )
        for db in ${dbs[@]}
        do
            resetDB $db
        done
    else
        resetDB $db_name
    fi
    ;;
"sync" )
    if [[ $k8s_auth = "true" ]]
    then
        clusterAuth || errorExit $E_AUTH $LOG_E_AUTH
    fi

    export PGPASSWORD="$db_pass"

    restartDbPod $k8s_pod_name
    testDbConn || errorExit $E_DBCONN $LOG_E_DBCONN
    obfuscateUsers
    publishStoreProduct

    if [[ ${sync_mode-dump} = dump ]]
    then
        test -d $dumpdir || mkdir -p $dumpdir
        test -d $dumpdir || errorExit $E_MISC $LOG_E_DUMPDIR
        dumpSync || errorExit $E_SYNC $LOG_E_SYNC
    else
        test -x $espath || errorExit $E_MISC $LOG_E_ESSYNC
        elasticSync || errorExit $E_SYNC $LOG_E_SYNC
    fi
    
    kubectl delete pods -l stack=storiqa
    ;;
* )
    printHelp
    errorExit $E_ARGS
    ;;
esac

exit 0 
