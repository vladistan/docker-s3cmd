#!/bin/sh

# Fail on errors
set -e

#
# main entry point to run s3cmd
#
S3CMD_PATH=/opt/s3cmd/s3cmd

# Display all commands unless no_verbose environment variable is set
if [ -z "${no_verbose}" ]; then
    set -x    
fi

#
# Check for required parameters
#
if [ -z "${aws_key}" ]; then
    echo "ERROR: The environment variable key is not set."
    exit 1
fi

if [ -z "${aws_secret}" ]; then
    echo "ERROR: The environment variable secret is not set."
    exit 1
fi

if [ -z "${cmd}" ]; then
    echo "ERROR: The environment variable cmd is not set."
    exit 1
fi

#
# Replace key and secret in the /.s3cfg file with the one the user provided
#
echo "" >> /.s3cfg
echo "access_key=${aws_key}" >> /.s3cfg
echo "secret_key=${aws_secret}" >> /.s3cfg

#
# Add region base host if it exist in the env vars
#
if [ "x${s3_host_base}" != "x" ]; then
  sed -i "s/host_base = s3.amazonaws.com/# host_base = s3.amazonaws.com/g" /.s3cfg
  echo "host_base = ${s3_host_base}" >> /.s3cfg
fi

# Check if we want to run in interactive mode or not
if [ ${cmd} != "interactive" ]; then

  #
  # sync-s3-to-local - copy from s3 to local
  #
  if [ "${cmd}" = "sync-s3-to-local" ]; then
      echo ${src-s3}
      ${S3CMD_PATH} --config=/.s3cfg  sync ${SRC_S3} /opt/dest/
  fi

  #
  # sync-local-to-s3 - copy from local to s3
  #
  if [ "${cmd}" = "sync-local-to-s3" ]; then
      ${S3CMD_PATH} --config=/.s3cfg sync /opt/src/ ${DEST_S3}
  fi
  
  if [ "${cmd}" = "sign-url" ]; then
      if [ -z "${s3_url}" ]; then
          echo "ERROR: The environment variable s3_url is not set."
          exit 1
      fi
      if [ -z "${expiry}" ]; then
          # If expiry not set expire URL in two weeks
          expiry="+1209600"
      fi

      ${S3CMD_PATH} --config=/.s3cfg signurl ${s3_url} ${expiry}
  fi
  
else
  # Copy file over to the default location where S3cmd is looking for the config file
  cp /.s3cfg /root/
fi

#
# Finished operations
#
if [ -z "${no_verbose}" ]; then
   echo "Finished s3cmd operations"
fi
