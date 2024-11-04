#!/bin/bash

function throw_error_if_need() {
    if [ $? -ne 0 ]; then
        echo "An error ocurred"
        exit 1
    fi
}

echo "Pushing Docker image..."

cr=$(bash get-env.sh "jenkins_container_registry")
cr_user=$(bash get-env.sh "jenkins_container_registry_username")
cr_password=$(bash get-env.sh "jenkins_container_registry_token")

appname=$(bash get-env.sh "jenkins_app_name")
appversion=$(bash get-env.sh "jenkins_app_version")

echo "Parâmetros lidos:"
echo "cr: $cr"
echo "cr_user: $cr_user"
echo "cr_password: PROTEGIDO"
echo "appname: $appname"
echo "appversion: $appversion"

new_version="$1"
if [ ! -z "$new_version" ]; then
    appversion="$new_version"
fi

image=$(echo "$cr/$appname:$appversion")
echo "Image: $image"

echo "$cr_password" | docker login $cr -u $cr_user --password-stdin
throw_error_if_need

echo "Pushing image $image..."

docker push $image
throw_error_if_need
