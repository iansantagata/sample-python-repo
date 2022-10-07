#!/bin/bash
. $(dirname $0)/script_setup.sh

echo "BOOTSTRAPPING PYTHON ENVIRONMENT"

installed_version=$(pyenv versions | grep "$PYTHON_VER")

case "$installed_version" in
  *$PYTHON_VER*)
  echo "Python version '$PYTHON_VER' is already installed"
  ;;
  *)
    echo "Python version '$PYTHON_VER' is not installed - installing now..."
    pyenv install $PYTHON_VER

    [ $? -ne 0 ] && echo "ERROR: Unable to install required python version" && exit 1
  ;;
esac


virtual_env=$(pyenv versions | grep "$VIRTUAL_PY")
if [ -n "$virtual_env" ]; then
  echo "Python virtual env '$VIRTUAL_PY' has already been created"
  virtual_env_version=$(python --version | awk '{print $2}')
  if [ "$PYTHON_VER" !=  "$virtual_env_version" ]; then
      echo "Existing environment ($virtual_env_version) doesn't match the desired version ($PYTHON_VER), deleting the virtual env..."
      pyenv virtualenv-delete "$VIRTUAL_PY"
      # virtual env no longer exists
      unset virtual_env
  fi
fi

if [ -z "$virtual_env" ]; then
  echo "Python virtual env '$VIRTUAL_PY' doesn't exist - creating now..."
  pyenv virtualenv $PYTHON_VER $VIRTUAL_PY

  [ $? -ne 0 ] && echo "ERROR: Unable to create python virtual env" && exit 1
fi

echo "Setting local python virtual env"
pyenv local $VIRTUAL_PY

echo "COPYING pip.conf to project root"
# this is needed to put .pip in docker's build context
cp -R ~/.pip .


echo "[global]
use-feature=2020-resolver" > $(pyenv virtualenv-prefix)/envs/$VIRTUAL_PY/pip.conf

# Install pinned dependencies, including development ones.
# This includes versions necessary to run module.
pip install -r requirements.txt -r requirements-dev.txt -e ".[dev]"


echo "WRITING ENVIRONMENT VARIABLES TO .env"
yarn install

. $(dirname $0)/init_dotenv.sh

