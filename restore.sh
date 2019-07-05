#!/bin/sh

gpg --import /keys/*

aws s3 ls s3://$S3_BUCKET_NAME --recursive --human-readable --summarize
echo "These are the files currently available in your backup bucket."
echo "Which file contains the backup you want to restore from?"
echo -n "File name: "
read RESTORE_PATH

RESTORE_FILE=$(echo $RESTORE_PATH | sed -e 's/.*\///')
RESTORE_DIR=$(echo $RESTORE_PATH | sed -e 's/\/.*$//')
CONTAINER_NAME=$(echo $RESTORE_DIR |  sed -e 's/-data$//')

echo
echo "Restore file: $RESTORE_FILE"
echo "Restore path: $RESTORE_PATH"
echo "Restore dir: $RESTORE_DIR"
echo "Container: $CONTAINER_NAME"
echo

aws s3 cp s3://$S3_BUCKET_NAME/$RESTORE_PATH .

gpg --output ./restore.tar.xz --decrypt $RESTORE_FILE

if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        # Container is not running or does not exist, so safe to restore
        echo "[`date +%Y-%m-%d\ %H:%M:%S`] container $CONTAINER_NAME is not running. Restoring..."
        tar -x -C /backup -f ./restore.tar.xz
else
        # need to stop it before doing the backup, then start it again
        echo "[`date +%Y-%m-%d\ %H:%M:%S`] container $CONTAINER_NAME is running. Stopping it first..."
        docker stop $CONTAINER_NAME

        echo "[`date +%Y-%m-%d\ %H:%M:%S`] Restoring..."
        tar -x -C /backup -f ./restore.tar.xz

        echo "[`date +%Y-%m-%d\ %H:%M:%S`] Restore complete. Starting container $CONTAINER_NAME ..."
        docker start $CONTAINER_NAME
fi

rm restore.tar.xz
rm $RESTORE_FILE

exit
