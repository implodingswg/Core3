#!/bin/bash
if [ ! -f ./env-run -a ! -f ./env-base ]; then
    echo "Run build.sh first."
    exit 1
fi

source ./env-run
source ./env-base

RUN_FORCE=false
RUN_KILL=false
RUN_CLEAN=false

while [ $# -gt 0 ]
do
    case $1 in
        clean ) RUN_CLEAN=true; RUN_KILL=true ;;
        kill ) RUN_KILL=true ;;
    esac
    shift
done

if $RUN_KILL; then
    echo "Running kill..."
    docker container kill ${GALAXY_NAME} || true
fi

if [ "$(docker inspect --format '{{.State.Status}}' ${GALAXY_NAME} 2> /dev/null)" = "running" ]; then
    echo "Container ${GALAXY_NAME} is already running."
    exit 100
fi

set -x
docker container rm ${GALAXY_NAME}

if $RUN_CLEAN; then
    echo "Running clean..."
    docker volume rm swgemu-core3 || true
fi

docker run -it \
    --name ${GALAXY_NAME} \
    --hostname ${GALAXY_NAME} \
    --cap-add=SYS_PTRACE \
    --restart=unless-stopped \
    --env-file env-base \
    --env-file env-run \
    -p ${SSHPORT}:${SSHPORT}/tcp \
    -p ${LOGINPORT}:${LOGINPORT}/udp \
    -p ${STATUSPORT}:${STATUSPORT}/tcp \
    -p ${PINGPORT}:${PINGPORT}/udp \
    -p ${ZONESERVERPORT}:${ZONESERVERPORT}/udp \
    -p 53306:3306 \
    -v $(pwd)/tre:/tre:ro \
    -v swgemu-core3:/home/swgemu \
    -v $(pwd)/../MMOCoreORB/bin/scripts:/home/swgemu/workspace/Core3/MMOCoreORB/bin/scripts \
    ${IMAGE}
