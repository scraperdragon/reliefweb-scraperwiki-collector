#!/bin/bash

# This script can be run regularly - it will kick off tool/main.py|sh and
# send the output to ~/log


DATE_NOW=$(date +%Y-%m-%d_%H-%M-%S)
LOG_DIR=~/log

SW_STATUS_URL=${SW_STATUS_URL-https://scraperwiki.com/api/status}

mkdir -p ${LOG_DIR}
LOG_FILE=${LOG_DIR}/${DATE_NOW}.log

ln -sf ${LOG_FILE} ${LOG_DIR}/latest

for command in tool/main.py tool/main.sh "$@"
do
    if [ -f "$command" ]; then
        run-one ${command} >> ${LOG_FILE} 2>&1
        RETCODE=$?
        if [ ${RETCODE} != 0 ]; then
            echo "$@ exited with code: ${RETCODE}"
            cat ${LOG_FILE}
            curl --data "type=error" ${SW_STATUS_URL} > /dev/null 2>&1
            git remote -v
            exit
        fi
        curl --data "type=ok" ${SW_STATUS_URL} > /dev/null 2>&1
    fi
done

# delete logs older than a month
find ${LOG_DIR} -type f -iname '*.log' -mtime +30 -delete

