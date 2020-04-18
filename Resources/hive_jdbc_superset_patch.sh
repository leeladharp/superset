#!/bin/bash

REPO_PATH=$1
DIALECT_PATH=$REPO_PATH/extra-libs/hive-jdbc
EXTERNAL_PATCH_PATH=$REPO_PATH/Resources/patches

pip install -r $DIALECT_PATH/requirements.txt
pip install $DIALECT_PATH/

#Applying patches
PYTHON_INSTALL_PATH=$(pip show flask | grep "Location:" | cut -c11-)

#copy hive2.py (DB engine spec in to /db_engine_spec/)
cp $DIALECT_PATH/patches/hive2.py  $PYTHON_INSTALL_PATH/superset/db_engine_specs/

patch -u $PYTHON_INSTALL_PATH/jaydebeapi/__init__.py -i  $DIALECT_PATH/patches/jaydebeapi.patch

cp $EXTERNAL_PATCH_PATH/login_oauth.html $PYTHON_INSTALL_PATH/flask_appbuilder/templates/appbuilder/general/security/login_oauth.html
#pip install $REPO_PATH
