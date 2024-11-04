#!/bin/bash

# Lança erro se o último comando falhar
function throw_error_if_need() {
    if [ $? -ne 0 ]; then
        echo "$1"
        exit 1
    fi
}

# Carrega variáveis do arquivo .env
function load_env() {
    if [ -f .env ]; then
        export $(cat .env | xargs)
    else
        exit 1
    fi
}

# Obter variável, com prioridade para ambiente
function get_env_var() {
    local var_name="$1"
    local var_value

    var_value=$(printenv $var_name)

    if [ -z "$var_value" ]; then
        load_env
        throw_error_if_need "Arquivo .env não encontrado"
        var_value=$(printenv $var_name)
    fi

    echo "$var_value"
}

var_name="$1"

if [ -z "$var_name" ]; then
    echo "Informe o nome da variável"
    exit 1
fi

get_env_var "$var_name"
throw_error_if_need "Variável $var_name não encontrada"
