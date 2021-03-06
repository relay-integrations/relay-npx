#!/bin/bash
set -euo pipefail

# Variables
COMMAND=$(ni get -p '{.command}')
if [ -z "${COMMAND}" ]; then
  ni log fatal "command is required to run an npx step"
fi
PACKAGE_FOLDER=$(ni get -p '{.packageFolder}')
[ "$PACKAGE_FOLDER" ] || PACKAGE_FOLDER="./"
FLAGS=$(ni get | jq -j 'try .flags | to_entries[] | "--\( .key ) \( .value ) "')
COMMAND_FLAGS=$(ni get | jq -j 'try .commandFlags | to_entries[] | "--\( .key ) \( .value ) "')
NODE_VERSION_TO_INSTALL=$(ni get -p '{.nodeVersion}')

# NPM credentials (login is required for commands like `publish`)
NPM_TOKEN=$(ni get -p '{.npm.token}')

# Install a different version of Node.js if version specified
if [ -n "${NODE_VERSION_TO_INSTALL}" ]; then
  # Install nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  if [ "${NODE_VERSION_TO_INSTALL}" = "auto" ]; then
    nvm install
    nvm use
  else
    nvm install "${NODE_VERSION_TO_INSTALL}"
    nvm use "${NODE_VERSION_TO_INSTALL}"
  fi
fi

# Clone git repository and cd into it
GIT=$(ni get -p '{.git}')
if [ -n "${GIT}" ]; then
  ni git clone
  NAME=$(ni get -p '{.git.name}')
  DIRECTORY=/workspace/${NAME}

  cd ${DIRECTORY}
fi

cd ${PACKAGE_FOLDER}

# Create .npmrc with credentials
if [ -n "${NPM_TOKEN}" ]; then
  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> ./.npmrc
fi

# Install npm dependencies
npm install --unsafe-perm

# Run npx
npx ${FLAGS} ${COMMAND} ${COMMAND_FLAGS}
