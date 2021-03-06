#! /bin/bash

resolved_script_path=$(readlink -f $0)
current_script_dir=$(dirname $resolved_script_path)
current_full_path=$(readlink -e $current_script_dir)

# TODO: use getopts
option1=$1
option2=$2
docker_image_name=farigh/minimalist-sshd
docker_name=ubuntu_sshd_docker
docker_home_dir="${current_full_path}/home"
host_port=24042

# Devel mode, use local image
if [ "${option1}" == "-d" ] || [ "${option2}" == "-d" ]; then
	docker_image_name=ubuntu-sshd
fi

# NET_ADMIN capability needed by iptables
docker_run_opt="--cap-add=NET_ADMIN -d -p ${host_port}:22 --name ${docker_name} ${docker_image_name}"

RESET_COLOR=$(echo -en '\e[0m')
RED_COLOR=$(echo -en '\e[0;31m')
CYAN_COLOR=$(echo -en '\e[0;36m')

# Add volume mounting option if dir exists
if [ -d "${docker_home_dir}" ]; then
    docker_run_opt="-v ${docker_home_dir}:/home/sshuser ${docker_run_opt}"
    echo "${CYAN_COLOR}Info: mounting dir '${docker_home_dir}' as container's user home dir${RESET_COLOR}"
fi

docker_ps=$(docker ps -af "name=${docker_name}" --format "{{.Names}}" | grep "^${docker_name}$")
if [ "${docker_ps}" != "${docker_name}" ]; then
    docker run $docker_run_opt
elif [ "${option1}" == "-f" ] || [ "${option2}" == "-f" ]; then
   if [ "$(docker inspect -f {{.State.Running}} ${docker_name} 2>/dev/null)" == "true" ]; then
       docker stop $docker_name
   fi
   docker rm $docker_name
   docker run $docker_run_opt
else
    if [ "$(docker inspect -f {{.State.Running}} ${docker_name} 2>/dev/null)" != "true" ]; then
        docker start $docker_name
    else
        echo "${RED_COLOR}Error: container '${docker_name}' is already running${RESET_COLOR}"
        exit 1
    fi
fi
