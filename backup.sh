#!/bin/sh

BACKUP_DATE=$(date +"%Y-%m-%d_%H-%M")

echo "[`date +%Y-%m-%d\ %H:%M:%S`] starting the backup process"

cd /backup

for job in $(ls -1 ); do
    # requires the connected volume to be named <container-name>-data
    CONTAINER_NAME=$(echo $job | sed -e 's/-data$//')
    FILENAME=$BACKUP_DATE-$job

    if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        # Container is not running or does not exist, so safe to back up
        echo "[`date +%Y-%m-%d\ %H:%M:%S`] container $CONTAINER_NAME is not running or does not exist..."
        echo "[`date +%Y-%m-%d\ %H:%M:%S`] taring the $job folder..."
        tar cJf ~/$FILENAME.tar.xz ./$job/.
    else
        # need to stop it before doing the backup, then start it again
        echo "[`date +%Y-%m-%d\ %H:%M:%S`] container $CONTAINER_NAME is running. Stopping it first..."
        docker stop $CONTAINER_NAME

        echo "[`date +%Y-%m-%d\ %H:%M:%S`] taring the $job folder..."
        tar cJf ~/$FILENAME.tar.xz ./$job/.

        echo "[`date +%Y-%m-%d\ %H:%M:%S`] tar complete. Starting container $CONTAINER_NAME ..."
        docker start $CONTAINER_NAME
    fi

    cd /
    echo "[`date +%Y-%m-%d\ %H:%M:%S`] encrypting the $job backup file..."
    gpg --trust-model always --output ~/$FILENAME.tar.xz.gpg --encrypt --recipient $GPG_RECIPIENT ~/$FILENAME.tar.xz
    rm ~/$FILENAME.tar.xz

    echo "[`date +%Y-%m-%d\ %H:%M:%S`] uploading encrypted backup file to AWS S3..."
    aws s3 cp ~/$FILENAME.tar.xz.gpg s3://$S3_BUCKET_NAME/$job/$FILENAME.tar.xz.gpg
    rm ~/$FILENAME.tar.xz.gpg

    cd /backup

done
echo "[`date +%Y-%m-%d\ %H:%M:%S`] backup process completed"
