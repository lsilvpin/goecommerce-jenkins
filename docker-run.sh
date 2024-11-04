#!/bin/bash

function throw_error_if_need() {
    if [ $? -ne 0 ]; then
        echo "$1"
        exit 1
    fi
}

jk_environment=$(bash get-env.sh "jenkins_environment")
cr=$(bash get-env.sh "jenkins_container_registry")
cr_username=$(bash get-env.sh "jenkins_container_registry_username")
cr_token=$(bash get-env.sh "jenkins_container_registry_token")
jk_host_volume_name=$(bash get-env.sh "jenkins_host_volume_name")
jk_container_volume_path=$(bash get-env.sh "jenkins_container_volume_path")
jk_host_port=$(bash get-env.sh "jenkins_host_port")
jk_container_port=$(bash get-env.sh "jenkins_container_port")
jk_app_name=$(bash get-env.sh "jenkins_app_name")
jk_app_version=$(bash get-env.sh "jenkins_app_version")
container_network=$(bash get-env.sh "jenkins_container_network")

new_version="$1"
if [ ! -z "$new_version" ]; then
    appversion="$new_version"
fi

image=$(echo "$cr/$jk_app_name:$jk_app_version")
echo "Image: $image"

container_name="${jk_app_name}_container_${jk_environment}"

echo "Checando se a rede $container_network existe..."
has_network=$(docker network ls --filter name=^${container_network}$ --format "{{.Name}}")
if [ ! -z "$has_network" ]; then
    echo "Rede $container_network encontrada"
else
    echo "Rede $container_network não encontrada"
fi
create_network_try_times=0
while [ -z "$has_network" ]; do
    echo "Criando rede $container_network..."
    docker network create $container_network
    throw_error_if_need "Erro ao criar rede $container_network"
    echo "Rede $container_network criada com sucesso"
    has_network=$(docker network ls --filter name=^${container_network}$ --format "{{.Name}}")
    create_network_try_times=$((error_counter+1))
    if [ $create_network_try_times -gt 3 ]; then
        echo "Erro ao criar rede $container_network"
        exit 1
    fi
done

echo "Checando se o container $container_name existe..."
has_container=$(docker ps -a --filter name=^${container_name}$ --format "{{.Names}}")
if [ ! -z "$has_container" ]; then
    echo "Container $container_name encontrado"
else
    echo "Container $container_name não encontrado"
fi
remove_container_try_times=0
while [ ! -z "$has_container" ]; do
    echo "Parando e removendo container $container_name..."
    docker container stop $container_name
    docker rm -f $container_name
    throw_error_if_need "Erro ao remover container $container_name"
    echo "Container $container_name removido com sucesso"
    has_container=$(docker ps -a --filter name=^${container_name}$ --format "{{.Names}}")
    remove_container_try_times=$((error_counter+1))
    if [ $remove_container_try_times -gt 3 ]; then
        echo "Erro ao remover container $container_name"
        exit 1
    fi
done

echo "Checando se o token do container registry foi configurado..."
if [ "$cr_token" = "VALOR_FALSO" ]; then
    echo "[ERRO] Token do container registry não configurado"
    echo "CR_TOKEN=$cr_token"
    echo "Verifique as variáveis de ambiente"
    exit 1
else
    echo "Token do container registry configurado corretamente"
fi

echo "Running Docker container with following parameters:"
echo "-d"
echo "-p $jk_host_port:$jk_container_port"
echo "-v $jk_host_volume_name:$jk_container_volume_path"
echo "--network $container_network"
echo "--name $container_name"
echo "-e jenkins_container_registry=$cr"
echo "-e jenkins_container_registry_username=$cr_username"
echo "-e jenkins_container_registry_token=$cr_token"
echo "-e jenkins_host_volume_name=$jk_host_volume_name"
echo "-e jenkins_container_volume_path=$jk_container_volume_path"
echo "-e jenkins_host_port=$jk_host_port"
echo "-e jenkins_container_port=$jk_container_port"
echo "-e jenkins_app_name=$jk_app_name"
echo "-e jenkins_app_version=$jk_app_version"
echo "$image"

docker run -d \
    -p $jk_host_port:$jk_container_port \
    -v $jk_host_volume_name:$jk_container_volume_path \
    --network $container_network \
    --name $container_name \
    -e jenkins_container_registry=$cr \
    -e jenkins_container_registry_username=$cr_username \
    -e jenkins_container_registry_token=$cr_token \
    -e jenkins_host_volume_name=$jk_host_volume_name \
    -e jenkins_container_volume_path=$jk_container_volume_path \
    -e jenkins_host_port=$jk_host_port \
    -e jenkins_container_port=$jk_container_port \
    -e jenkins_app_name=$jk_app_name \
    -e jenkins_app_version=$jk_app_version \
    $image
