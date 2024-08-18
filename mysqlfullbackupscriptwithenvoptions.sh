#!/usr/bin/bash

function checkenvfile() {

if [ -f ".env" ]; then
  source .env
else
  echo "Error: .env file not found"
  exit 1
fi

}


function checkexistingbackup_dirandcreatenew() {

    backup_dir=/opt/bkp-$(date +%y%m%d)

    if [ -d $backup_dir ]; then

        echo "you can not take backup, ${backup_dir} folder  is already there, please check"

        exit 1

    else

        mkdir ${backup_dir}
        if [ $? -eq 0 ]; then
            echo "${backup_dir} was created  successfully"
        else
            echo "${backup_dir} was failed. to created"
            exit 1
        fi

    fi

}

function checkexistingbackupcompressfilenameandcreatenew() {

    compressedfile=/opt/bkp-$(date +%y%m%d).7z

    if [ -f $compressedfile ]; then

        echo "you can not compress backup_dir,  $compressedfile  is already there, please check"

        exit 1

    else

        backup_dir=/opt/bkp-$(date +%y%m%d)

        if [ -d $backup_dir ]; then

            7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on ${compressedfile} ${backup_dir}/

            if [ $? -eq 0 ]; then
                echo "{backup_dir} compression is    completed successfully"
                echo ${backup_dir} is removing cause compression is successfully completed.
                rm -rf ${backup_dir}
            else
                echo "${backup_dir} compression is  failed  "
                exit 1
            fi

        fi

    fi
}

function databasedump() {


    if [ -z "$DB_NAME" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ]; then
            echo "Error: DB_NAME,DB_USERNAME, DB_PASSWORD, DB_HOST and DB_PORT must be set in .env file"
        exit 1
    fi


    backup_dir="/opt/bkp-$(date +%y%m%d)"
    db_user_name=$DB_USERNAME
    db_password=$DB_PASSWORD
    db_host=$DB_HOST
    db_port=$DB_PORT
    db_name=$DB_NAME

    checkexistingbackup_dirandcreatenew

    if [ -d "$backup_dir" ]; then

        
            
            mysqldump --lock-all-tables --set-gtid-purged=OFF --user=${db_user_name} --password=${db_password}  ${db_name} > ${backup_dir}/${db_name}.sql

            if [ $? -eq 0 ]; then
                echo "database ${db_name}  dump for  was completed successfully."
            else
                echo "database ${db_name}  dump was failed. so removing directory  ${backup_dir}"
                rm -rf ${backup_dir}
                if [ $? -eq 0 ]; then
                    echo "${backup_dir} was  successfully removed"
                else
                    echo "${backup_dir} was failed to remove, remove it manually"
                    exit 1
                fi
                exit 1
            fi

        checkexistingbackupcompressfilenameandcreatenew

    else
        echo "$backup_dir does not exist"
        exit 1
    fi

}


function copybackupfiletonas(){


    databasedump
    compressedfile=/opt/bkp-$(date +%y%m%d).7z

    if [ -f $compressedfile ]; then 

    $compressedfile for database backup file is found copying it to nas server.

   if [ -z "$NAS_USERNAME" ] || [ -z "$NAS_IP" ] || [ -z "$NAS_FOLDER_PATH_FOR_BACKUP_FILE" ]; then
            echo "Error: NAS_USERNAME, NAS_IP AND NAS_FOLDER_PATH_FOR_BACKUP_FILE must be set in .env file"
        exit 1
    fi

    scp -pr $compressedfile  $NAS_USERNAME@${NAS_IP}:/$NAS_FOLDER_PATH_FOR_BACKUP_FILE 

    if [ $? -eq 0 ]; then
     echo "$compressedfile backup file is copied successfully completed on NAS SERVER ${NAS_IP}"
 else
     echo "$compressedfile backup file is failed to copy  on NAS SERVER ${NAS_IP} please check manually"
     exit 1
 fi

    else
        echo  "$compressedfile backup file is  not found, so not copy  on NAS SERVER ${NAS_IP} please check manually"
        exit 1



}


function main() {

copybackupfiletonas

}

main

#####################################################################
# make sure .env file present with required username, password, dbhost,db port, nasip , nasusername,nasfolder path where you want to copt your file.
#./mysqlfullbackup.sh 