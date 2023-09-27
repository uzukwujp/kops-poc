#!/bin/bash

if [[ $GITHUB_REF == "main" ]] 
then
    echo "run command to deploy to production"
elif [[ $GITHUB_REF == "dev" ]]
then
    echo "run command to deploy to dev"
elif [[ $GITHUB_REF == "staging" ]]
then
    echo "run command to deploy to staging"
fi
