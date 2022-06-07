#!/bin/bash

GAME_PATH=`echo $PWD`
CUR_PATH=`echo ${GAME_PATH##*/}`

#启动
start() {
    exist=`ls -l /var/tmp/ | grep $CUR_PATH`
    if [[ $exist != "" ]]; then
        echo "server had started!"
        exit 0
    fi
    cd $GAME_PATH
    java -jar game.jar & >> /dev/null && echo $! > /var/tmp/$CUR_PATH.pid && echo "start server fininish."
}

#停止
stop() {
    exist=`ls -l /var/tmp/ | grep $CUR_PATH`
    if [[ $exist == "" ]]; then
        echo "server not started!"
        exit 0
    fi
    pid=`cat /var/tmp/$CUR_PATH.pid`
    kill -15 $pid
    rm -f /var/tmp/$CUR_PATH.pid
    echo "stop finished."
}
if [[ $# != 1 ]]; then
    echo "Usage: $0 start/stop"
    exit 1
else
    if [[ $1 == "start" ]]; then
        start
    elif [[ $1 == "stop" ]]; then
        stop
    fi
fi
