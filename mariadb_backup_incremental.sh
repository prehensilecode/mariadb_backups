#!/bin/bash
###
### MariaDB incremental backup
###

MARIABACKUP=/bin/mariabackup
BACKUP_BASE_DIR=/var/cache/mariabackup

# delete backup directories older than 14 hours
find ${BACKUP_BASE_DIR}/* -type d -mmin +$((60*14)) -exec rm -rf {} \;

MONTH_DIR=${BACKUP_BASE_DIR}/`date +%Y-%m`
TARGET_DIR=${MONTH_DIR}/`date +%d_%H%M_incr`

LOG_DIR=/var/log/mariabackup
LOG=${LOG_DIR}/mariadb_backup_full.log


if [[ -e ${TARGET_DIR} ]]
then
    printf "[`date --rfc-3339=seconds --utc`] ERROR - Directory ${TARGET_DIR} already exists\n" >> ${LOG}
    exit 1
else
    mkdir -p ${MONTH_DIR}

    if [[ -e ${MONTH_DIR}/last_completed_backup ]]
    then
        BASE_DIR=$(head -n 1 ${MONTH_DIR}/last_completed_backup)
        
        if [[ -z ${BASE_DIR} ]]
        then
            printf "[`date --rfc-3339=seconds --utc`] ERROR - Base dir is an empty string\n" >> ${LOG}
        else
            mkdir -p ${TARGET_DIR}

            SECONDS=0

            ${MARIABACKUP} --backup \
                --target-dir=${TARGET_DIR} \
                --incremental-basedir=${BASE_DIR} \
                --user=mariabackup --password=some_password >> ${LOG} 2>&1

            printf "[`date --rfc-3339=seconds --utc`] INFO - Completed in ${SECONDS} seconds\n" >> ${LOG}

            printf ${TARGET_DIR} > ${MONTH_DIR}/last_completed_backup
            exit 0
        fi
    else
        printf "[`date --rfc-3339=seconds --utc`] ERROR - No base dir for incremental backup\n" >> ${LOG}
        exit 3
    fi
fi
