#!/bin/sh

# Import GPG public keys
gpg --import /keys/*

# This is ugly and very un-DRY, but sh(1) is not bash(1). So we will live with
# this as it's manageable, even if inelegant.

if [[ -z "${CRON_INTERVAL}" ]]; then
  echo "CRON_INTERVAL environment variable not set. Aborting."
  exit 1
fi

if [[ -z "${GPG_RECIPIENT}" ]]; then
  echo "GPG_RECIPIENT environment variable not set. Aborting."
  exit 1
fi

if [[ -z "${S3_BUCKET_NAME}" ]]; then
  echo "S3_BUCKET_NAME environment variable not set. Aborting."
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
  echo "AWS_ACCESS_KEY_ID environment variable not set. Aborting."
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
  echo "AWS_ACCESS_KEY_ID environment variable not set. Aborting."
  exit 1
fi


# Create and install crontab file
echo "$CRON_INTERVAL /backup.sh" > /backup.cron

crontab /backup.cron

# tail -f /dev/null
crond -f -d 8
