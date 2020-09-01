#!/bin/bash
###
### MariaDB full backup
###

MARIABACKUP=/bin/mariabackup
BACKUP_BASE_DIR=/var/cache/mariabackup

# delete backup directories older than 14 hours
find ${BACKUP_BASE_DIR}/* -type d -mmin +$((60*14)) -exec rm -rf {} \;


MONTH_DIR=${BACKUP_BASE_DIR}/`date +%Y-%m`
TARGET_DIR=${MONTH_DIR}/`date +%d_%H%M_full`/

LOG_DIR=/var/log/mariabackup
LOG=${LOG_DIR}/mariadb_backup_full.log

if [[ -e ${TARGET_DIR} ]]
then
    printf "[`date --rfc-3339=seconds --utc`] ERROR - Directory ${TARGET_DIR} already exists\n" >> ${LOG}
    exit 1
else
    mkdir -p ${TARGET_DIR}

    SECONDS=0

    ${MARIABACKUP} --backup \
        --target-dir=${TARGET_DIR} \
        --user=mariabackup --password=some_password >> ${LOG} 2&>1
    
    printf "[`date --rfc-3339=seconds --utc`] INFO - Completed in ${SECONDS} seconds\n" >> ${LOG}

    printf ${TARGET_DIR} > ${MONTH_DIR}/last_completed_backup
    exit 0
fi

