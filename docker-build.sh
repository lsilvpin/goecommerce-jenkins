#!/bin/bash

function throw_error_if_need() {
    if [ $? -ne 0 ]; then
        echo "An error ocurred"
        exit 1
    fi
}

echo "Building Docker image..."

cr=$(bash get-env.sh "jenkins_container_registry")
appname=$(bash get-env.sh "jenkins_app_name")
appversion=$(bash get-env.sh "jenkins_app_version")

echo "Configurações lidas:"
echo "cr: $cr"
echo "appname: $appname"
echo "appversion: $appversion"

new_version="$1"
if [ ! -z "$new_version" ]; then
    appversion="$new_version"
fi

image=$(echo "$cr/$appname:$appversion")

echo "A imagem será construída com os seguintes parâmetros:"
echo "-t $image"
echo "-f Dockerfile"

docker build \
    -t $image \
    -f Dockerfile \
    .
throw_error_if_need

echo "Docker image built successfully."
