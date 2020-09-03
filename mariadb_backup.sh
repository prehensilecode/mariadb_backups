#!/bin/bash
###
### MariaDB backup
###
umask 077
set -e
set -u
set -o pipefail

function help {
    echo "script usage: $(basename $0) [-t full | incr]" >&2
}

if [ $# -eq 0 ]
then
    help
    exit 1
else
    while getopts "t:" OPTION
    do
        case "$OPTION" in
            t)
                tvalue="$OPTARG"
                ;;
            ?)
                help
                exit 1
                ;;
        esac
    done
fi

shift "$(($OPTIND -1))"

MARIABACKUP=/bin/mariabackup
BACKUP_BASE_DIR=/var/cache/mariabackup

# delete backup directories older than 90 days
find ${BACKUP_BASE_DIR} -type d -mmin +$((60*24*90)) -exec rm -rf {} \;

MONTH_DIR=${BACKUP_BASE_DIR}/`date +%Y-%m`
TARGET_DIR=${MONTH_DIR}/$( date +%d-%H%M%S-${tvalue} )

MARIABACKUP_OPTS="--backup --target-dir=${TARGET_DIR} --user=mariabackup --password=some_password"

LOG_DIR=/var/log/mariabackup
LOG=${LOG_DIR}/mariadb_backup.log

if [[ -e ${TARGET_DIR} ]]
then
    printf "`date --rfc-3339=seconds --utc` - ERROR - Directory ${TARGET_DIR} already exists\n" >> ${LOG}
    exit 1
else
    if [[ x${tvalue} = xfull ]]
    then
        mkdir -p ${TARGET_DIR}

        SECONDS=0

        ${MARIABACKUP} ${MARIABACKUP_OPTS} >> ${LOG} 2>&1

        printf "`date --rfc-3339=seconds --utc` - INFO - Full backup completed in ${SECONDS} seconds\n" >> ${LOG}

        printf ${TARGET_DIR} > ${MONTH_DIR}/last_completed_backup
        exit 0
    elif [[ x${tvalue} = xincr ]]
    then
        mkdir -p ${MONTH_DIR}

        if [[ -e ${MONTH_DIR}/last_completed_backup ]]
        then
            BASE_DIR=$(head -n 1 ${MONTH_DIR}/last_completed_backup)

            if [[ -z ${BASE_DIR} ]]
            then
                printf "`date --rfc-3339=seconds --utc` - ERROR - BASE_DIR is an empty string\n" >> ${LOG}
            else
                mkdir -p ${TARGET_DIR}

                SECONDS=0

                ${MARIABACKUP} ${MARIABACKUP_OPTS} \
                    --incremental-basedir=${BASE_DIR}  >> ${LOG} 2>&1

                printf "`date --rfc-3339=seconds --utc` - INFO - Incremental backup completed in ${SECONDS} seconds\n" >> ${LOG}

                printf ${TARGET_DIR} > ${MONTH_DIR}/last_completed_backup
                exit 0
            fi
        else
            printf "`date --rfc-3339=seconds --utc` - ERROR - No base dir for incremental backup\n" >> ${LOG}
            exit 3
        fi
    fi
fi

