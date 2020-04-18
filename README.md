

## Installation Guide:

#### A) Versions (Dependencies)
*These are required to be installed before you can continue with superset installation*
- Python: **3.6.x**
- Ubuntu: 16.04.06
- Hadoop Java Client (hive-jdbc.jar and its dependencies)
- nodejs
- npm

#### B) DVT - Superset Repository
 Here are some important folders and files to take note of in this repository:

- **`extra-libs/hive-jdbc`**: This folder contains the script/patches that are required to run during installation in order to have a working dialect for Apache HIVE JDBC Dialect.
- **`Resources/`**: This folder contains the scripts that will be used during the deployment and installation process for superset
    - **`akv_get_secret.py`**: Python script that will be called to query and retrieve values from Azure Key-Vault.
    - **`deploy_superset.sh`**: Shell script used to install dependencies, *(npm and nodejs will be installed/updated through this script if needed),* create python virtual environment, and install superset along with applying hive patches.
    - **`superset_uiChanges.sh`**: Shell script used to stop superset server, rebuild superset assets, *(JSX, CSS, HTML, etc.),* and finally start the superset server after assets have been rebuilt
- **`superset/`**: This folder contains various superset assets and configuration files.
    - **`assets/`**: This folder contains the superset images, css, and jsx asset files. If developing any ui changes, make sure to change asset files in this folder.
    - **`static/`**: The superset ui references the ui assets from this folder, which is a link to the mentioned above /assets folder
    - **`config.py`**: One of the python configuration file for superset backend.
- **`keyvault-requirements.txt`**: Python libraries required for python script to work with key vault.
- **`requirements.txt`**: Python libraries required for superset to work properly.

#### C) Jenkins Pipeline Deployment
While working with the DevOps team, the following commands were created/ran to successfully deploy Superset:

```
#For the dev env, the install_path variable was set to the following:
#INSTALLATION_PATH='/home/sshuser/dvt'

#----->START HERE
#change directory to installation path (path may vary for env, this is example for dev)
cd $INSTALLATION_PATH 

#Clear folders
rm -rf dvtLogs/ dvtnew.zip DVT-onetimeinstallationnew/

#Create a logs folder
mkdir -p dvtLogs

#unzip the pulled dvt repo zip file
unzip -o $INSTALLATION_PATH/dvtnew.zip -d $INSTALLATION_PATH

#Define tenant id and deployed env name required for key-vault
AKV_TENANT_ID=""
export SUPERSET_DEPLOYED_ENV='${SUPERSET_ENV}'

#change directory to the resources folder where scripts are located
cd $INSTALLATION_PATH/DVT-onetimeinstallationnew/Resources/

#Run the deployment script, 1st param = Path to Unzipped repo, 2nd param = admin password for DVT
sh $INSTALLATION_PATH/DVT-onetimeinstallationnew/Resources/deploy_superset.sh $INSTALLATION_PATH/DVT-onetimeinstallationnew $PASSWORD

#Export Key-vault variables
export AKV_CLIENT_ID=${AKV_CLIENT_ID}
export AKV_CLIENT_SECRET=${AKV_CLIENT_SECRET}
export AKV_VAULT_URL=${AKV_VAULT_URL}
export AKV_TENANT_ID=$AKV_TENANT_ID

#Run the ui script to build assets and start server, 1st param = Path to unzipped repo
sh $INSTALLATION_PATH/DVT-onetimeinstallationnew/Resources/superset_uiChanges.sh $INSTALLATION_PATH/DVT-onetimeinstallationnew
```

#### D) Manual Deployment Instructions
This section contains the instructions for a manual deployment. Scripts have been developed that run these commands, however these are the steps required in case those two scripts were not available.

##### Installation
1. Download this repo from stash 
  
1. Make sure Python 3.6.x is installed. Also, for Ubuntu make sure OS Dependencies are installed.
   ```
   sudo apt-get update
   sudo apt-get install -y build-essential libssl-dev libffi-dev libsasl2-dev libldap2-dev python3-gdbm python3.6-venv python3-pip curl 
    
   #Installing Node and npm dependency required to be able to rebuild assets
   sudo apt-get install -y nodejs
   sudo apt-get install -y npm    #This command does not get the latest npm, so need to update
   sudo npm install -g npm        #Updates NPM to the latest version
   ```

1. Export the following variable. This value is used for a ui config. Please fill in depending on environment that pipeline is for (DEV | QA | UAT | PROD)
   ```
   export SUPERSET_DEPLOYED_ENV='${SUPERSET_ENV}'
   ```

1. Create a python virtual environment
    ```
    python3.6 -m venv supersetvenv
    . supersetvenv/bin/activate
    ```

1. Setup Python tools
   ```
    pip install --upgrade setuptools pip
   ```

1. When you have unzipped the repo, cd into the repo and run the following command to install superset requirements
    ```
    pip install -r $REPO_PATH/requirements.txt
    pip install gevent

    #Install key-vault requirements for python script
    pip install -r $REPO_PATH/keyvault-requirements.txt
    ```

1. While in the parent folder for the repo, install the custom superset
    ```
    pip install -e $REPO_PATH/.
    ```

1. You will need to run the following commands the first time after installation to setup superset db and initializations
    ```
    superset db upgrade

    export FLASK_APP=superset
    flask fab create-admin --username admin --firstname admin --lastname admin --email admin-dvt@kp.org --password $PASS

    superset init
    ```

1. After installation, Hive JDBC patch will need to be applied. Run the script named: hive_jdbc_superset_patch.sh in the /Resources folder
    ```
    #Run patch script
    bash hive_jdbc_superset_patch.sh $REPO_PATH

    #Export environment varibales
    export CLASSPATH=$CLASSPATH:$(hadoop classpath):/usr/hdp/current/hadoop-client/*:/usr/hdp/current/hive-client/lib/*:/usr/hdp/current/hadoop-client/client/*
    export HIVE_JDBC_DRIVER_PATH=/usr/hdp/current/hive-client/lib/
    export HIVE_JDBC_JAR_NAME=hive-jdbc.jar
    ```    

1. After patch has been applied, the superset assets have to be built. The following steps have to be taken and will have to be re-ran anytime there are any ui changes. Please take a look at the **Rebuilding Assets** section of this readme file

##### Rebuilding Assets
1. Activate superset virtual environment, if it hasn't already been activated
   ```
   cd $REPO_PATH/Resources
   . supersetvenv/bin/activate
   ```


1. Export Key-Vault variables to retrieve values
   ```
   #DevOps team will have to provide these based off of environment
   export AKV_CLIENT_ID=''  
   export AKV_TENANT_ID=''
   export AKV_CLIENT_SECRET=''
   export AKV_VAULT_URL=''
   ```

1. Export the following variable. This value is used for a ui config. Please fill in depending on environment that pipeline is for (DEV | QA | UAT | PROD)
   ```
   export SUPERSET_DEPLOYED_ENV='${SUPERSET_ENV}'
   ```

1. Retrieve values from key-vault
   ```
   export SECRET_ID='dvt-svc-url'
   superset_url=$(python3 $REPO_PATH/Resources/akv_get_secret.py)
   echo "Got value for superset url"
   
   export SECRET_ID='dvt-svc-port'
   superset_port=$(python3 $REPO_PATH/Resources/akv_get_secret.py)
   echo "Got value for superset port"
   ```

1. Shutdown Superset processes. superset does not have a superset stop server call, so alternative is to kill processes
   ```
   kill -9 $(lsof -ti tcp:$superset_port)
   echo "superset server stopped"
   ```

1. You now have to rebuild the superset assets running the following
   ```
   #Rebuild static assets folder link
   cd $REPO_PATH/superset/static
   rm -rf assets

   #Rereate the link to that assets folder
   ln -s ../assets/ assets 
   echo 'static assets link recreated'
   
   #Rebuild assets
   cd $REPO_PATH/superset/assets
   npm ci
   npm run build
   echo "superset assets rebuilt"
   ```

1. Install any python libraries that may have been added
   ```
   cd $REPO_PATH
   pip install -r requirements.txt
   echo "superset assets packages updated"
   ```

1. If new python api calls are created in `core.py` file, then the following command must run to update superset permissions
   ```
   superset init
   echo "superset assets permissions updated"
   ```

1. Export environment variables for hive connection
   ```
   export CLASSPATH=$CLASSPATH:$(hadoop classpath):/usr/hdp/current/hadoop-client/*:/usr/hdp/current/hive-client/lib/*:/usr/hdp/current/hadoop-client/client/*
   export HIVE_JDBC_DRIVER_PATH=/usr/hdp/current/hive-client/lib/
   export HIVE_JDBC_JAR_NAME=hive-jdbc.jar
   ```

1. Finally, start Superset server
   ```
   echo "starting superset server"
   nohup gunicorn -w 10 -k gevent --timeout 120  -b  $superset_url:$superset_port  --limit-request-line 0  --limit-request-field_size 0 superset:app &
   ```

#### E) Local Development Instructions
If you are developing on your local machine, there are some features and steps that you can skip/process. Please follow these steps:

##### Installation
1. Download this repo from stash and move folder to where you would like to install superset.

1. Unzip the folder.

1. Make sure all dependencies have been installed: Python 3.6.x, Hadoop, nodejs, npm.

1. Export the following variable. This value is used for a ui config. Please fill in depending on environment that pipeline is for (DEV | QA | UAT | PROD)
   ```
   export SUPERSET_DEPLOYED_ENV='${SUPERSET_ENV}'
   ```

1. Run the deployment script found in the /Resources folder:
   ```
   #Make sure to run from the /Resources folder; cd if necessary
   . ./deploy_superset.sh $PATH_TO_REPO $ADMIN_PW
   ```

##### Rebuilding Assets
1. After running the script above, you will need to update the contents of a different script, *(**Resources/superset_uiChanges.sh**)*, to remove the key-vault code section and to point superset to start on your localhost:
   ```diff
   REPO_PATH=$1
   
   #Make sure superset environment is activated 
   cd $REPO_PATH/Resources
   . supersetvenv/bin/activate

   - #Setup for key vault- get server IP/URL
   - export SECRET_ID='dvt-svc-url'
   - superset_url=$(python3 $REPO_PATH/Resources/akv_get_secret.py)
   - echo "Got value for superset url"
   
   - export SECRET_ID='dvt-svc-port'
   - superset_port=$(python3 $REPO_PATH/Resources/akv_get_secret.py)
   - echo "Got value for superset port"

   - #echo "full port: $superset_url:$superset_port"
   
   - #Shutdown Superset processes. superset does not have a superset stop server call, - so alternative is to kill processes
   - #This command will list pid's running under port used for server
   - kill -9 $(lsof -ti tcp:$superset_port)
   - echo "superset server stopped"
   
   ...
   
   #Start Superset server
   - #To start superset in prod mode 
   - echo "starting superset server"
   - nohup gunicorn -w 10 -k gevent --timeout 120  -b  $superset_url:$superset_port  --limit-request-line 0  --limit-request-field_size 0 superset:app > /home/sshuser/dvt/dvtLogs/dvtlogs.log &
   
   + #If developing locally on your machine, uncomment below and comment out line above to start superset server on localhost
   + echo "starting superset server"
   + nohup& gunicorn -w 10 -k gevent --timeout 120  -b  0.0.0.0:8101  --limit-request-line 0  --limit-request-field_size 0 superset:app
   ```

1. After updating the script, you need to run the script to rebuild superset assets found in the /Resources folder: **superset_uiChanges.sh**
   ```
   #Make sure to run from the /Resources folder; cd if necessary
   . ./superset_uiChanges.sh
   ```
