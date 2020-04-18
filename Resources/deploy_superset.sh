#!/bin/bash

# #############################################################################################
# * name: DVT-superset One-time install script
# * description: Script to install custom superset, only needs to run on initial install (1-time)
# * Notes:
#	-Make sure this script is placed in the Resources folder
# 	
# #############################################################################################

REPO_PATH=$1 #without end slash
PASS=$2
echo "SUPERSET REPO PATH :"$REPO_PATH

#Installing OS dependencies for Ubuntu
sudo apt-get update 
sudo apt-get install -y build-essential libssl-dev libffi-dev libsasl2-dev libldap2-dev python3-gdbm python3.6-venv python3-pip curl 

#Installing Node and npm dependency required to be able to rebuild assets
sudo apt-get install -y nodejs
sudo apt-get install -y npm  #This command does not get the latest npm, so need to update
sudo npm install -g npm      #Updates NPM to the latest version

#Create Python virtual environment for superset and activate it
python3.6 -m venv supersetvenv
. supersetvenv/bin/activate

#Setup python tools and install superset requirements, 
pip install --upgrade setuptools pip
pip install -r $REPO_PATH/requirements.txt

#Install key vault requirements
pip install -r $REPO_PATH/keyvault-requirements.txt

#Install custom superset we created (editable/development)
pip install -e $REPO_PATH/.

#Initialize superset database
superset db upgrade

# Create an admin user (set a username, first, last name, email and password)
export FLASK_APP=superset
flask fab create-admin --username dvt-admin --firstname dvt --lastname admin --email admin_dvt@kp.org --password $PASS

#Initialize superset: this will create default roles and permissions
superset init

#Apply patch for hive_jdbc
bash hive_jdbc_superset_patch.sh $REPO_PATH

#Export environmental variables
export CLASSPATH=$CLASSPATH:$(hadoop classpath):/usr/hdp/current/hadoop-client/*:/usr/hdp/current/hive-client/lib/*:/usr/hdp/current/hadoop-client/client/*
export HIVE_JDBC_DRIVER_PATH=/usr/hdp/current/hive-client/lib/
export HIVE_JDBC_JAR_NAME=hive-jdbc.jar
