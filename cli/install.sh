#!/bin/bash
#*******************************************************************************
# Licensed Materials - Property of IBM
# "Restricted Materials of IBM"
#
# Copyright IBM Corp. 2018 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
#******************************************************************************
source ../.env

# Variables
STEP_COUNT=1;
DIRECTORY="${HOME}/microclimate-workspace";
CONFIG_DIRECTORY="${DIRECTORY}/.config";
GIT_CONFIG="${DIRECTORY}/.config/git.config";
GIT_USERNAME=`git config --get user.name || echo 'Microclimate User'`;
GIT_EMAIL=`git config --get user.email || echo 'microclimate.user@localhost'`;
INSTALL_DIRECTORY=$HOME/.microclimate;
LIBERTY_BUILD_CMD="$LIBERTY_BUILD_TEMPLATE ${INSTALL_DIRECTORY}/dockerfiles/libertyDockerfile ${INSTALL_DIRECTORY}/dockerfiles/"

NAME="Microclimate";
CLI_NAME="mcdev";

# Functions
# Function to print out the current step and increment
#     takes the step message as the first arg
printStep () {
  sleep 1;
  echo -e "\n\nStep ${STEP_COUNT}: ${1}";
  STEP_COUNT=$(($STEP_COUNT+1));
}

# Function to print the header for the install script
printHeader () {
  # Script header
  echo -e "\n";
  echo -e " ******************************************************";
  echo -e " **                                                  **";
  echo -e " **          Running Microclimate installer          **";
  echo -e " **                                                  **";
  echo -e " ******************************************************";
  sleep 1;
}

# Function to print the footer for the install script
printFooter () {
  echo -e "\n\n=====================";
  echo -e "\nINSTALLATION COMPLETE";
  echo -e "\nMicroclimate has been successfully installed.\n";
}

printHeader;

# Run uninstall to ensure that Microclimate cli will function correctly
# Check if root or not. Root user has ID of 0
if [ "$EUID" -eq 0 ]; then
  ROOT=true;
  sudo ./uninstall.sh;
else
  ROOT=false;
  ./uninstall.sh;
  # Error checking to ensure that the install does not keep running if uninstall fails (not root)
  if [ $? -ne 0 ]; then
    exit 1;
  fi

fi

# Create the microclimate-workspace directory
printStep "Create workspace directory";
echo -e "\n Creating the '${DIRECTORY}' directory (your workspace).";
mkdir -m 777 -p ${DIRECTORY}
# Check its created
echo -e "\n Verifying the workspace has been created successfully. ";
if [ -d ${DIRECTORY} ]; then
  echo -e " '${DIRECTORY}' directory exists.";
else
  echo -e " Error: '${DIRECTORY}' directory does not exist.";
fi
# Check permissions
echo -e "\n Checking the workspace permissions. ";
ls -ld ${DIRECTORY} | grep -q drwxrwxrwx
if [ $? -eq 0 ]; then
  echo -e " '${DIRECTORY}' directory permissions correct.";
else
  echo -e " Error: '${DIRECTORY}' directory permissions incorrect.";
fi

# Create the .config folder used for Git
printStep "Create config directory";
echo -e "\n Creating the '${CONFIG_DIRECTORY}' directory (your workspace).";
mkdir -m 777 -p ${CONFIG_DIRECTORY}
# Check its created
echo -e "\n Verifying the workspace has been created successfully. "
if [ -d ${CONFIG_DIRECTORY} ]; then
  echo -e " '${CONFIG_DIRECTORY}' directory exists.";
else
  echo -e " Error: '${CONFIG_DIRECTORY}' directory does not exist. ";
fi
# Check permissions
echo -e "\n Checking the config permissions. ";
ls -ld ${CONFIG_DIRECTORY} | grep -q drwxrwxrwx
if [ $? -eq 0 ]; then
  echo -e " '${CONFIG_DIRECTORY}' directory permissions correct.";
else
  echo -e " Error: '${CONFIG_DIRECTORY}' directory permissions incorrect.";
fi

# Save the git config required to make an initial commit.
printStep "Save Git config";
echo -e "\n Git config will be located at in:";
echo -e " '${GIT_CONFIG}'";
if [ -f ${GIT_CONFIG} ]; then
  echo -e "\n '${GIT_CONFIG}' file exists.";
  echo -e "\n Removing to overwrite the data.";
  rm $GIT_CONFIG
fi


echo -e "\n Adding username and email address.";
echo -e " Note: If no Github username or password is given, Microclimate will use its defaults.";
echo -e "\n Git username will be: ${GIT_USERNAME}";
echo -e " Git email address will be: ${GIT_EMAIL}";
git config -f $GIT_CONFIG --add user.name "${GIT_USERNAME}";
git config -f $GIT_CONFIG --add user.email "${GIT_EMAIL}";

echo -e " Verifying Git setup has executed successfully. ";
if [ -f ${GIT_CONFIG} ]; then
  echo -e " '${GIT_CONFIG}' file exists.";
else
  echo -e " Error: '${GIT_CONFIG}' file does not exist. ";
fi

# Copying Microclimate to the users path at $HOME/microclimate
echo -e "\n\n\nMoving Microclimate files.\n";
sleep 1;
printStep "Making microclimate directory at '${INSTALL_DIRECTORY}'";
mkdir ${INSTALL_DIRECTORY};
if [ $? -eq 0 ]; then
  echo "Microclimate directory made in '${INSTALL_DIRECTORY}'.";
else
  echo "Microclimate directory exists. Removing and adding the new files.";
  rm -rf ${INSTALL_DIRECTORY};
  if [ $? -eq 0 ]; then
    echo "Microclimate directory removed.";
  else
    echo -e "Error removing Microclimate directory. \nExiting.";
    exit;
  fi
  mkdir ${INSTALL_DIRECTORY};
  if [ $? -eq 0 ]; then
    echo "Microclimate directory made in '${INSTALL_DIRECTORY}'.";
  else
    echo -e "Error adding Microclimate directory. \nExiting.";
    exit;
  fi
fi

printStep "Copying '${CLI_NAME}' to '${INSTALL_DIRECTORY}'";
cp mcdev-frame ${INSTALL_DIRECTORY}/${CLI_NAME};
if [ $? -eq 0 ]; then
  echo "Successfully copied to '${INSTALL_DIRECTORY}'.";
else
  echo -e "Error copying 'microclimate'. \nExiting.";
  exit;
fi

chmod 775 ${INSTALL_DIRECTORY}/${CLI_NAME};

printStep "Copying 'docker-compose.yaml' to '${INSTALL_DIRECTORY}'";
cp ../docker-compose.yaml ${INSTALL_DIRECTORY}/docker-compose.yaml;
if [ $? -eq 0 ]; then
  echo "Successfully copied 'docker-compose.yaml' to '${INSTALL_DIRECTORY}'.";
else
  echo -e "Error copying 'docker-compose.yaml'. \nExiting.";
  exit;
fi

printStep "Copying 'dockerfiles' to '${INSTALL_DIRECTORY}'";
cp -rf ../dockerfiles ${INSTALL_DIRECTORY}/dockerfiles;
if [ $? -eq 0 ]; then
  echo "Successfully copied 'dockerfiles' to '${INSTALL_DIRECTORY}'.";
else
  echo -e "Error copying 'dockerfiles'. \nExiting.";
  exit;
fi

# Force pull the latest websphere liberty image
printStep "Pulling the latest websphere-liberty";
echo -e "\n Pulling the latest websphere-liberty:webProfile7 docker image";
mkdir -p ${INSTALL_DIRECTORY}/logs
docker pull websphere-liberty:webProfile7 >> ${INSTALL_DIRECTORY}/logs/liberty_docker_cache.log 2>&1 &
if [ ! $? -eq 0 ]; then
  echo -e "\n Failed to pull the latest liberty docker image\n";
else
  echo -e "\n Successfully pulled the latest liberty docker image\n";
fi

# Prebuild the Liberty image
if [ ! "$( docker images mc-liberty-jdk-cache -q )" ] && [ -f ${INSTALL_DIRECTORY}/dockerfiles/libertyDockerfile ]; then
  printStep "Pre-building the Liberty app image";
  mkdir -p ${INSTALL_DIRECTORY}/logs
  $LIBERTY_BUILD_CMD >> ${INSTALL_DIRECTORY}/logs/liberty_docker_cache.log 2>&1 &
  if [ ! $? -eq 0 ]; then
    echo -e "\n Failed to pre-build the liberty app image\n";
  else
    echo -e "\n Successfully pre-built the liberty app image\n";
  fi
fi

# Prebuild the Spring image
if [ ! "$( docker images mc-spring-jdk-cache -q )" ] && [ -f ${INSTALL_DIRECTORY}/dockerfiles/springDockerfile ]; then
  printStep "Pre-building the Spring app image";
  mkdir -p ${INSTALL_DIRECTORY}/logs
  $SPRING_BUILD_CMD > ${INSTALL_DIRECTORY}/logs/spring_docker_cache.log 2>&1 &
  if [ ! $? -eq 0 ]; then
    echo -e "\n Failed to pre-build the spring app image\n";
  else
    echo -e "\n Successfully pre-built the spring app image\n";
  fi
fi

printStep "Copying '.env' to '${INSTALL_DIRECTORY}'";
cp ../.env ${INSTALL_DIRECTORY}/.env;
if [ $? -eq 0 ]; then
  echo "Successfully copied '.env' to '${INSTALL_DIRECTORY}'.";
else
  echo -e "Error copying '.env'. \nExiting.";
  exit;
fi

printStep "Adding workspace location to '.env' file.";
echo 'WORKSPACE_DIRECTORY='${DIRECTORY} >> ${INSTALL_DIRECTORY}/.env
if [ $? -eq 0 ]; then
  echo -e "Successfully added workspace location to '.env' file.\n";
else
  echo -e "\nError adding workspace location to '.env' file. \nExiting.";
  exit;
fi

if $ROOT; then
  printStep "Adding Microclimate to path.";
  ln -sf $INSTALL_DIRECTORY/${CLI_NAME} /usr/local/bin/${CLI_NAME}
  if [ $? -eq 0 ]; then
    echo "${CLI_NAME} symlinked to 'usr/local/bin' and is now on path.";
  else
    echo -e "Error symlinking to 'usr/local/bin'. \nExiting.";
    exit;
  fi
  printFooter;
  echo -e "Run '${CLI_NAME} start' to start microclimate.\n";
  exit;
else
  printStep "Adding a symlink to Microclimate at '~/${CLI_NAME}'.";
  ln -sf $INSTALL_DIRECTORY/${CLI_NAME} ~/${CLI_NAME}
  if [ $? -eq 0 ]; then
    echo "Microclimate symlinked to '~/${CLI_NAME}'";
  else
    echo -e "Error symlinking to '~/${CLI_NAME}'. \nExiting.";
    exit;
  fi
  printFooter;

  if [ -e ~/.bashrc -o -e ~/.bash_profile -o -e ~/.profile -o -e ${ZDOTDIR:-~}/.zshrc ]; then
    echo -e "Add Microclimate to your \$PATH by running one or more of the following commands.\n";
    SOURCE_FILE_LIST=(~/.bashrc ~/.bash_profile ~/.profile "${ZDOTDIR:-$HOME}/.zshrc");
    for SOURCE in ${SOURCE_FILE_LIST[@]}; do
      [ -e ${SOURCE} ] && echo "echo 'export PATH=\"\$PATH:${INSTALL_DIRECTORY}\"' >> ${SOURCE}";
    done;

    echo -e "\nNote: These will not reload automatically. Use 'source [ Your file location ]' to reload the path.";
    echo "For example I would use 'source ~/.bashrc' to reload my .bashrc file.";
    echo -e "\nAlternatively you can run '~/${CLI_NAME} COMMAND'\n";
  else
    echo "To run Microclimate you can either:"
    echo "     - Add 'export PATH=\$PATH:${INSTALL_DIRECTORY}' to your shell source file to add mcdev to your \$PATH";
    echo "     - Run '~/${CLI_NAME} COMMAND' to use Microclimate";
  fi

  exit;
fi
