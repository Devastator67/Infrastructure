#!/usr/local/bin/bash

set -eu
set -x

DEPLOYER_INFRASTRUCTURE_PATH="/usr/local/infrastructure"

DEPLOY_SOFTWARE=""
DEPLOY_ENV=""
DEPLOY_BRANCH="master"
DEPLOY_VERSION=""
SERVER_ID=""
LIMIT="all"

function get_deploy_software() {
    case "$1" in
        helix)
            DEPLOY_SOFTWARE="$1"
            ;;
        hewww)
            DEPLOY_SOFTWARE="$1"
            ;;
        *)
            exit "Can't deploy $1"
            ;;
    esac
}

function get_deploy_environment {
    case $1 in
        prod|production)
            DEPLOY_ENV="production"
            ;;
        stage|staging)
            DEPLOY_ENV="staging"
            ;;
        dev|development)
            DEPLOY_ENV="development"
            ;;
        *)
            exit "Invalid env $1"
            ;;
    esac
}

get_deploy_software "$1" && shift
get_deploy_environment "$1" && shift

while [[ $# -gt 1 ]]; do
    key="$1"

    case $key in
        -b|--branch)
            DEPLOY_BRANCH="$2"
            shift
            ;;
        -v|--version)
            # add regex: only numbers and dots
            # \d{4}(\.){1}\d{2}(\.){1}\d{6}
            DEPLOY_VERSION="$2"
            shift
            ;;
        --server-id)
            SERVER_ID="$2"
            shift
            ;;
        *)
            ;;
    esac
    shift
done

if [ -z "$DEPLOY_VERSION" ]; then
    exit "You did not specify which version to deploy, you fool!"
fi

if [ "$DEPLOY_ENV" == 'staging' ] && [ -z "$SERVER_ID" ]; then
    exit 'You did not specify which server id to deploy to'
else
    LIMIT="interactive-$SERVER_ID"
fi

# tmp, until ansible 2.3 gets released
source /usr/local/ansible/hacking/env-setup

# Make ansible use this config file, not the one on the repository
export ANSIBLE_CONFIG=/home/deployer/.ansible.cfg

cd $DEPLOYER_INFRASTRUCTURE_PATH

ansible-playbook \
    "$DEPLOY_SOFTWARE".yml \
    -i environments/"$DEPLOY_ENV" \
    --extra-vars "deploy=1 branch=$DEPLOY_BRANCH version=$DEPLOY_VERSION" \
    --limit "$LIMIT"
