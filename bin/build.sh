#!/bin/bash

# usage info
usage(){
  echo " Run this script to build and deploy client and server images when you need to apply changes to server or client code"
  echo ""
  echo "Parameters:"
  echo ""
  echo " -s 1 => build server"
  echo ""
  echo " -c 1 => build client"
  echo ""
  echo " -b master => tell the script to use master as github branch to pull code from"
  echo ""
  echo " -p http (available options: http - https) => tell the script to use http protocol for contacting server"
  echo ""
  echo " -ip server ip address (MANDATORY) => tell the script the server ip address"
  echo ""
  echo " -du docker username (MANDATORY) => tell the script your docker username to push the images"
  echo ""
  echo "Usage:"
  echo "  $0 -s 1 -c 1 -b master -du rmiccolis -ip your_ip_domain.com => will build both server and client"
  echo ""
  echo "  $0 -s 1 -b master -du docker_username -ip your_ip_domain.com => will build just server"
  echo ""
  echo "  $0 -s 1 -b master -p https -du docker_username -ip 10.11.1.1 => will build just server"
  echo ""
  echo "Options:"
  echo "  pass 1 if you want to build client or server. If no arguments are provided, then both client and server will be built"
  echo ""
  exit
}

while getopts ":c:s:b:p:ip:du:" opt; do
  case $opt in
    c) client="$OPTARG"
    ;;
    s) server="$OPTARG"
    ;;
    b) github_branch_name="$OPTARG"
    ;;
    p) protocol="$OPTARG"
    ;;
    ip) app_server_addr="$OPTARG"
    ;;
    ip) docker_username="$OPTARG"
    ;;
    \?) usage
        exit
    ;;
  esac
done

repository_root_dir="/home/$USER/apps"
# if github_branch_name is not passed as input parameter set default branch to master
if [ -z "$github_branch_name" ]; then github_branch_name='master'; fi
# if protocol is not passed as input parameter set default protocol to http
if [ -z "$protocol" ]; then protocol='https'; fi
if [ -z "$app_server_addr" ]; then
    usage
    exit
fi

###############################################################################
# Build docker images from server and client applications
# cd into project root directory
cd $repository_root_dir/binance-bot/

echo -e "${LBLUE}Pulling code...${WHITE}"
# source /home/$USER/.profile
git checkout .
git checkout $github_branch_name
git pull origin $github_branch_name
cd ..
chmod -R u+x binance-bot
cd $repository_root_dir/binance-bot/


# if either client and server are not passed as argument set them to 1 (meaning we build both)
if [ -z "$client" ] && [ -z "$server" ]; then client=1; server=1; fi

if [ "$client" == "1" ]; then
# Set environment variable VITE_SERVER_URI
# echo -e "${LBLUE}Setting Server IP address: Public or Private...${WHITE}"
# cluster_ip=$master_host_ip
# if [ "$environment" == "production" ]; then
# echo -e "${LBLUE}Setting Server Public IP address: $load_balancer_public_ip ${WHITE}"
# cluster_ip=$load_balancer_public_ip
# fi
# before building images we have to set a .env file to pass client its environment variables
echo -e "${LBLUE}Setting Server IP for client environment...${WHITE}"
cat << EOF | tee $repository_root_dir/binance-bot/client/.env.production > /dev/null
VITE_SERVER_URI="$protocol://$app_server_addr/server/"
EOF

envsubst < $repository_root_dir/binance-bot/client/capacitor.config.json | tee $repository_root_dir/binance-bot/client/capacitor.config.json > /dev/null

# Start building docker client image
echo -e "${LBLUE}Building client docker image...${WHITE}"
sudo docker build -t $docker_username/binance_bot_client -f ./client/client.dockerfile ./client/
# Push generated client docker image to docker hub
sudo docker push $docker_username/binance_bot_client:latest
kubectl -n binance-b scale --replicas=0 deployment client; kubectl -n binance-b scale --replicas=1 deployment client
fi

if [ "$server" == "1" ]; then
echo -e "${LBLUE}Building server docker image...${WHITE}"
# Start building docker server image
sudo docker build -t $docker_username/binance_bot_server -f ./server/docker/server.dockerfile ./server/

echo -e "${LBLUE}Building docker image for kubernetes jobs to be launched...${WHITE}"
# Start building docker image for kubernetes jobs to be launched
sudo docker build -t $docker_username/binance_bot_server_job -f ./server/docker/job.dockerfile ./server/

echo -e "${LBLUE}Pushing docker image to dockerhub...${WHITE}"
# Push generated server docker image to docker hub
sudo docker push $docker_username/binance_bot_server:latest
sudo docker push $docker_username/binance_bot_server_job:latest
server_replica_count=$(kubectl get deployment -n binance-bot server -o jsonpath='{.spec.replicas}')
kubectl -n binance-b scale --replicas=0 deployment server; kubectl -n binance-b scale --replicas=$server_replica_count deployment server
fi