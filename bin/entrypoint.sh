#!/bin/bash

if [[ "$FORCE_CLEAN" == "1" ]]; then
    rm -rf $PGDATA/*
fi

/usr/local/bin/cluster/repmgr_configure.sh

if [[ "$INITIAL_NODE_TYPE" == "master" ]]; then
    cp -f /usr/local/bin/cluster/primary.entrypoint.sh /docker-entrypoint-initdb.d/
    /docker-entrypoint.sh "$@" &
else
    /usr/local/bin/cluster/standby.entrypoint.sh "$@" &
fi

wait_db $CLUSTER_NODE_NETWORK_NAME $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB

echo ">>> Registering node with initial role $INITIAL_NODE_TYPE"
gosu postgres repmgr $INITIAL_NODE_TYPE register --force

echo ">>> Starting repmgr daemon..."
rm -rf /tmp/repmgrd.pid

gosu postgres repmgrd -vvv --pid-file=/tmp/repmgrd.pid