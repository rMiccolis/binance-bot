# Binance-bot

This is a simple web app that features a crypto trading bot which works in lateral market conditions.
The projects has
- a Node.js backend application (./server/ folder) which makes use of Binance API to get informations on user wallet, trades, staking operations and to fire buy and sell trades for him based on a user predefined strategy. This backend applications handles user authentication, database connection and firing kubernetes job for each user so the bot trading is intended as a kubernetes job inside the cluster
- a Vue.js frontend application to let user interact with Binance web APIs and to start trading bot operations.

## Building the project:
First of all you have to build images of client and server. To do so there is a shell script that makes the work for you inside ./bin/build.sh. This file takes some input arguments.
Run this script to build and deploy client and server images when you need to apply changes to server or client code
#### Parameters:
- -s 1 => build server
- -c 1 => build client
- -b master => tell the script to use master as github branch to pull code from
- -p http (available options: http - https) => tell the script to use http protocol for contacting server
- -i server ip address (MANDATORY) => tell the script the server ip address
- -d docker username (MANDATORY) => tell the script your docker username to push the images
- -t use tls (MANDATORY) => tell the script to use the tls-cert.pem for mongodb connection. The script will take this file from /home/$USER/tls
#### Usage:

**IMPORTANT:**
if you need tsl connection to mongodb you have to create a "mongodb-tls-cert.pem" inside ./server/
The script will take this file from /home/$USER//tls

-  ./bin/build.sh -s 1 -c 1 -b master -d rmiccolis -i your_ip_domain.com => will build both server and client
-  ./bin/build.sh -s 1 -b master -d docker_username -i your_ip_domain.com => will build just server
-  ./bin/build.sh -s 1 -b master -p https -d docker_username -i 10.11.1.1 => will build just server

### Deploying app on kubernetes cluster
After this, to deploy project you have to replace all the variables in the form of ${variable_name} inside each ./kubernetes/*.yaml file.
Then you can just apply those files in kubernetes with
```
    kubectl apply -f ./kubernetes/
```

## Reaching webapp:
Now you can reach the webapp at ${app_server_addr} (the variable you have substituted inside 3-server-ingress.yaml)

# NB.
This kubernetes configuration is intended to be run on a kubernetes cluster that already has a mongodb deployed and which has a letsencrypt certificate. This project is compatible with [HyperKube Project](https://github.com/rMiccolis/HyperKube).
So for problems and more info visit that project page.
