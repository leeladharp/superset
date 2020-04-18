#!/usr/bin/env bash

# #############################################################################################
# * name: DVT-superset Assets rebuilding
# * description: Run this Script to rebuild UI assets such as HTML, CSS, and JSX
# * Last updated by: Alexis Lara
# * Notes:
#   -09/30/19 - v1.0.0  - First Creation
#	-Make sure this script is placed in the Resources folder. Script should be run from this folder
# 	
# #############################################################################################
REPO_PATH=$1

#Make sure superset environment is activated 
cd $REPO_PATH/Resources
. supersetvenv/bin/activate

#Setup for key vault- get server IP/URL
export SECRET_ID='dvt-svc-url'
superset_url=$(python3 $REPO_PATH/Resources/akv_get_secret.py)
echo "Got value for superset url"

export SECRET_ID='dvt-svc-port'
superset_port=$(python3 $REPO_PATH/Resources/akv_get_secret.py)
echo "Got value for superset port"

# echo "full port: $superset_url:$superset_port"

#Shutdown Superset processes. superset does not have a superset stop server call, so alternative is to kill processes
#This command will list pid's running under port used for server
kill -9 $(lsof -ti tcp:$superset_port)
echo "superset server stopped"

#Rebuild static assets folder link
cd $REPO_PATH/superset/static
rm -rf assets
ln -s ../assets/ assets  #Create the link to that assets folder that should have the dist 
echo 'static assets link recreated'

#Rebuild assets
cd $REPO_PATH/superset/assets
npm ci  #Install dependencies from the package-lock.json file
npm run build
echo "superset assets rebuilt"

#Need to check if all correct packages for python backend have been installed, if not they will be installed with this command
cd $REPO_PATH
pip install -r requirements.txt
echo "superset assets packages updated"

#If new python api calls are created in core.py, then the following command must run to update superset permissions
superset init
echo "superset assets permissions updated"

#Export environmental variables for hive connection
export CLASSPATH=$CLASSPATH:$(hadoop classpath):/usr/hdp/current/hadoop-client/*:/usr/hdp/current/hive-client/lib/*:/usr/hdp/current/hadoop-client/client/*
export HIVE_JDBC_DRIVER_PATH=/usr/hdp/current/hive-client/lib/
export HIVE_JDBC_JAR_NAME=hive-jdbc.jar

#Start Superset server
#To start superset in prod mode 
echo "starting superset server"
nohup gunicorn -w 10 -k gevent --timeout 120  -b  $superset_url:$superset_port  --limit-request-line 0  --limit-request-field_size 0 superset:app > /home/sshuser/dvt/dvtLogs/dvtlogs.log &

#If developing locally on your machine, uncomment below and comment out line above to start superset server on localhost
#nohup& gunicorn -w 10 -k gevent --timeout 120  -b  0.0.0.0:8101  --limit-request-line 0  --limit-request-field_size 0 superset:app
